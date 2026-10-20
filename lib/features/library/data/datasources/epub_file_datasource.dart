import 'dart:io';
import 'dart:typed_data';

import 'package:epubx/epubx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../models/book_model.dart';
import 'library_local_datasource.dart';

class PickedEpubFile {
  const PickedEpubFile({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;
}

abstract class EpubFileDataSource {
  Future<PickedEpubFile?> pickEpubFile();

  Future<BookModel> importEpubBytes({
    required Uint8List bytes,
    required String originalName,
  });
}

class EpubFileDataSourceImpl implements EpubFileDataSource {
  EpubFileDataSourceImpl({
    required this.localDataSource,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final LibraryLocalDataSource localDataSource;
  final Uuid _uuid;

  @override
  Future<PickedEpubFile?> pickEpubFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['epub'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        final path = file.path;
        if (path == null) {
          throw const FileFailure('Не удалось прочитать выбранный EPUB-файл');
        }
        final fileBytes = await File(path).readAsBytes();
        return PickedEpubFile(name: file.name, bytes: fileBytes);
      }

      return PickedEpubFile(name: file.name, bytes: bytes);
    } catch (error) {
      if (error is FileFailure) rethrow;
      throw FileFailure('Ошибка выбора файла: $error');
    }
  }

  @override
  Future<BookModel> importEpubBytes({
    required Uint8List bytes,
    required String originalName,
  }) async {
    try {
      final epubBook = await EpubReader.readBook(bytes);
      final bookId = _uuid.v4();
      final booksDir = await localDataSource.getBooksDirectory();
      final safeName = _sanitizeFileName(
        originalName.endsWith('.epub') ? originalName : '$originalName.epub',
      );
      final storedPath = p.join(booksDir.path, '${bookId}_$safeName');
      await File(storedPath).writeAsBytes(bytes, flush: true);

      String? coverPath;
      final coverImage = epubBook.CoverImage;
      if (coverImage != null) {
        final encoded = img.encodePng(coverImage);
        coverPath = p.join(booksDir.path, '${bookId}_cover.png');
        await File(coverPath).writeAsBytes(encoded, flush: true);
      }

      final title = (epubBook.Title?.trim().isNotEmpty ?? false)
          ? epubBook.Title!.trim()
          : p.basenameWithoutExtension(originalName);
      final author = epubBook.Author?.trim();

      return BookModel(
        id: bookId,
        title: title,
        author: (author == null || author.isEmpty) ? null : author,
        filePath: storedPath,
        coverPath: coverPath,
        importedAt: DateTime.now(),
      );
    } on FileFailure {
      rethrow;
    } catch (error) {
      throw ParsingFailure('Не удалось обработать EPUB: $error');
    }
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
