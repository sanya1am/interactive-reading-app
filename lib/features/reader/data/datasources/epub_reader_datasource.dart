import 'dart:io';
import 'dart:typed_data';

import 'package:epubx/epubx.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/html_content_extractor.dart';
import '../../domain/entities/reader_block.dart';
import '../../domain/entities/reader_page.dart';
import '../models/epub_load_result.dart';

abstract class EpubReaderDataSource {
  Future<EpubLoadResult> loadBook(String filePath);
}

class EpubReaderDataSourceImpl implements EpubReaderDataSource {
  EpubReaderDataSourceImpl({
    HtmlContentExtractor? contentExtractor,
    this.charsPerPage = 1400,
    this.imageWeight = 500,
  }) : _contentExtractor = contentExtractor ?? const HtmlContentExtractor();

  final HtmlContentExtractor _contentExtractor;
  final int charsPerPage;
  final int imageWeight;

  @override
  Future<EpubLoadResult> loadBook(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const FileFailure('Файл книги не найден на устройстве');
      }

      final bytes = await file.readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);
      final chapters = _flattenChapters(epubBook.Chapters ?? const []);
      final images = _collectImages(epubBook);

      if (chapters.isEmpty) {
        throw const ParsingFailure('В EPUB не найдены главы для чтения');
      }

      final pages = <ReaderPage>[];
      final locationIndex = <String, int>{};
      var pageIndex = 0;

      for (var chapterIndex = 0; chapterIndex < chapters.length; chapterIndex++) {
        final chapter = chapters[chapterIndex];
        final title = (chapter.Title?.trim().isNotEmpty ?? false)
            ? chapter.Title!.trim()
            : 'Глава ${chapterIndex + 1}';
        final contentFileName = chapter.ContentFileName;

        final blocks = _contentExtractor.extract(
          htmlContent: chapter.HtmlContent,
          images: images,
          chapterFileName: contentFileName,
        );

        if (blocks.isEmpty) {
          continue;
        }

        final chapterStartPage = pageIndex;
        _registerLocation(
          locationIndex,
          contentFileName,
          chapter.Anchor,
          chapterStartPage,
        );

        final chapterPages = _paginateBlocks(blocks);
        for (final pageBlocks in chapterPages) {
          _registerAnchorsOnPage(
            locationIndex,
            contentFileName,
            pageBlocks,
            pageIndex,
          );
          pages.add(
            ReaderPage(
              index: pageIndex,
              chapterTitle: title,
              blocks: pageBlocks
                  .where((block) => block is! ReaderAnchorMark)
                  .toList(growable: false),
              chapterIndex: chapterIndex,
              contentFileName: contentFileName,
            ),
          );
          pageIndex++;
        }
      }

      if (pages.isEmpty) {
        throw const ParsingFailure('Не удалось извлечь содержимое из EPUB');
      }

      // Register NCX/nav chapter targets that share a content file via Anchor.
      _registerChapterNavigationTargets(
        epubBook.Chapters ?? const [],
        locationIndex,
      );

      return EpubLoadResult(
        pages: pages,
        locationIndex: Map.unmodifiable(locationIndex),
      );
    } on Failure {
      rethrow;
    } catch (error) {
      throw ParsingFailure('Ошибка чтения EPUB: $error');
    }
  }

  void _registerChapterNavigationTargets(
    List<EpubChapter> chapters,
    Map<String, int> index,
  ) {
    for (final chapter in chapters) {
      final fileName = chapter.ContentFileName;
      if (fileName != null && fileName.trim().isNotEmpty) {
        final file = _stripLeadingDotSlash(fileName.replaceAll('\\', '/'));
        final basename = file.split('/').last;
        final filePage =
            index[file.toLowerCase()] ?? index[basename.toLowerCase()];
        if (filePage != null) {
          _registerLocation(index, fileName, chapter.Anchor, filePage);
        }
      }
      final subChapters = chapter.SubChapters;
      if (subChapters != null && subChapters.isNotEmpty) {
        _registerChapterNavigationTargets(subChapters, index);
      }
    }
  }

  void _registerLocation(
    Map<String, int> index,
    String? contentFileName,
    String? anchor,
    int pageIndex,
  ) {
    if (contentFileName == null || contentFileName.trim().isEmpty) return;

    final file = _stripLeadingDotSlash(contentFileName.replaceAll('\\', '/'));
    final basename = file.split('/').last;

    void put(String key) => index.putIfAbsent(key.toLowerCase(), () => pageIndex);

    put(file);
    put(basename);
    if (anchor != null && anchor.trim().isNotEmpty) {
      final a = anchor.trim();
      put('$file#$a');
      put('$basename#$a');
    }
  }

  void _registerAnchorsOnPage(
    Map<String, int> index,
    String? contentFileName,
    List<ReaderBlock> pageBlocks,
    int pageIndex,
  ) {
    if (contentFileName == null || contentFileName.trim().isEmpty) return;
    final file = _stripLeadingDotSlash(contentFileName.replaceAll('\\', '/'));
    final basename = file.split('/').last;

    for (final block in pageBlocks) {
      if (block is! ReaderAnchorMark) continue;
      final id = block.id.trim();
      if (id.isEmpty) continue;
      index.putIfAbsent('$file#$id'.toLowerCase(), () => pageIndex);
      index.putIfAbsent('$basename#$id'.toLowerCase(), () => pageIndex);
      index.putIfAbsent(id.toLowerCase(), () => pageIndex);
    }
  }

  Map<String, Uint8List> _collectImages(EpubBook epubBook) {
    final result = <String, Uint8List>{};

    void addImage(String key, List<int>? content) {
      if (content == null || content.isEmpty) return;
      final bytes = Uint8List.fromList(content);
      result[key] = bytes;
      final basename = key.replaceAll('\\', '/').split('/').last;
      if (basename.isNotEmpty) {
        result.putIfAbsent(basename, () => bytes);
      }
    }

    final images = epubBook.Content?.Images;
    if (images != null) {
      for (final entry in images.entries) {
        addImage(entry.key, entry.value.Content);
      }
    }

    final allFiles = epubBook.Content?.AllFiles;
    if (allFiles != null) {
      for (final entry in allFiles.entries) {
        final file = entry.value;
        if (file is! EpubByteContentFile) continue;
        final mime = file.ContentMimeType?.toLowerCase() ?? '';
        final key = entry.key.toLowerCase();
        final looksLikeImage = mime.startsWith('image/') ||
            key.endsWith('.jpg') ||
            key.endsWith('.jpeg') ||
            key.endsWith('.png') ||
            key.endsWith('.gif') ||
            key.endsWith('.webp') ||
            key.endsWith('.bmp');
        if (!looksLikeImage) continue;
        addImage(entry.key, file.Content);
      }
    }

    return result;
  }

  List<EpubChapter> _flattenChapters(List<EpubChapter> chapters) {
    final result = <EpubChapter>[];
    for (final chapter in chapters) {
      final hasOwnContent =
          chapter.HtmlContent != null && chapter.HtmlContent!.trim().isNotEmpty;
      if (hasOwnContent) {
        result.add(chapter);
      }
      final subChapters = chapter.SubChapters;
      if (subChapters != null && subChapters.isNotEmpty) {
        result.addAll(_flattenChapters(subChapters));
      }
    }
    return result;
  }

  List<List<ReaderBlock>> _paginateBlocks(List<ReaderBlock> blocks) {
    final pages = <List<ReaderBlock>>[];
    var current = <ReaderBlock>[];
    var currentWeight = 0;

    void flush() {
      if (current.isEmpty) return;
      pages.add(List<ReaderBlock>.unmodifiable(current));
      current = <ReaderBlock>[];
      currentWeight = 0;
    }

    for (final block in blocks) {
      switch (block) {
        case ReaderAnchorMark():
          current.add(block);
        case ReaderLinkBlock():
          if (currentWeight >= charsPerPage) {
            flush();
          }
          current.add(block);
          currentWeight += block.label.length.clamp(20, 120);
          if (currentWeight >= charsPerPage) {
            flush();
          }
        case ReaderImageBlock():
          if (currentWeight >= charsPerPage) {
            flush();
          }
          current.add(block);
          currentWeight += imageWeight;
          if (currentWeight >= charsPerPage) {
            flush();
          }
        case ReaderTextBlock(:final text):
          for (final chunk in _splitText(text, charsPerPage - currentWeight)) {
            final chunkWeight = chunk.length;
            if (current.isNotEmpty &&
                currentWeight > 0 &&
                currentWeight + chunkWeight > charsPerPage) {
              flush();
            }
            current.add(ReaderTextBlock(chunk));
            currentWeight += chunk.length;
            if (currentWeight >= charsPerPage) {
              flush();
            }
          }
      }
    }

    flush();
    return pages.isEmpty ? [blocks] : pages;
  }

  List<String> _splitText(String text, int firstPageBudget) {
    if (text.isEmpty) return const [];

    final chunks = <String>[];
    var offset = 0;
    var budget = firstPageBudget > 200 ? firstPageBudget : charsPerPage;

    while (offset < text.length) {
      var end = (offset + budget).clamp(0, text.length);
      if (end < text.length) {
        final window = text.substring(offset, end);
        final breakAt = _findBreak(window);
        if (breakAt > budget ~/ 2) {
          end = offset + breakAt;
        }
      }

      final chunk = text.substring(offset, end).trim();
      if (chunk.isNotEmpty) {
        chunks.add(chunk);
      }

      offset = end;
      while (offset < text.length &&
          (text[offset] == ' ' || text[offset] == '\n')) {
        offset++;
      }
      budget = charsPerPage;
    }

    return chunks;
  }

  int _findBreak(String window) {
    final paragraph = window.lastIndexOf('\n\n');
    if (paragraph != -1) return paragraph;

    final newline = window.lastIndexOf('\n');
    if (newline != -1) return newline;

    final sentence = window.lastIndexOf('. ');
    if (sentence != -1) return sentence + 1;

    final space = window.lastIndexOf(' ');
    if (space != -1) return space;

    return window.length;
  }

  String _stripLeadingDotSlash(String value) {
    var result = value;
    while (result.startsWith('./')) {
      result = result.substring(2);
    }
    while (result.startsWith('/')) {
      result = result.substring(1);
    }
    return result;
  }
}
