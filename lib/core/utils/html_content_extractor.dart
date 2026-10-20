import 'dart:typed_data';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;

import '../../features/reader/domain/entities/reader_block.dart';

/// Converts EPUB XHTML into ordered text/image/link blocks for the reader.
class HtmlContentExtractor {
  const HtmlContentExtractor();

  List<ReaderBlock> extract({
    required String? htmlContent,
    required Map<String, Uint8List> images,
    String? chapterFileName,
  }) {
    if (htmlContent == null || htmlContent.trim().isEmpty) {
      return const [];
    }

    final document = html_parser.parse(htmlContent);
    document.querySelectorAll('script, style').forEach((node) => node.remove());

    final root = document.body ?? document.documentElement;
    if (root == null) {
      return const [];
    }

    final blocks = <ReaderBlock>[];
    final textBuffer = StringBuffer();

    void flushText() {
      final text = _normalize(textBuffer.toString());
      textBuffer.clear();
      if (text.isNotEmpty) {
        blocks.add(ReaderTextBlock(text));
      }
    }

    void maybeAddAnchor(Element node) {
      final id = node.id.trim().isNotEmpty
          ? node.id.trim()
          : (node.attributes['name']?.trim() ?? '');
      if (id.isEmpty) return;
      flushText();
      blocks.add(ReaderAnchorMark(id));
    }

    void walk(Node node) {
      if (node is Text) {
        textBuffer.write(node.text);
        return;
      }

      if (node is! Element) {
        return;
      }

      final localName = node.localName?.toLowerCase();
      maybeAddAnchor(node);

      if (localName == 'a') {
        final href = node.attributes['href']?.trim();
        final label = _normalize(node.text);
        if (href != null &&
            href.isNotEmpty &&
            label.isNotEmpty &&
            _isInternalHref(href)) {
          flushText();
          blocks.add(ReaderLinkBlock(label: label, href: href));
          return;
        }
        // External/empty links: keep visible text only.
        for (final child in node.nodes) {
          walk(child);
        }
        return;
      }

      if (localName == 'img' || localName == 'image') {
        flushText();
        final src = node.attributes['src'] ??
            node.attributes['xlink:href'] ??
            node.attributes['href'];
        final bytes = _resolveImage(src, images, chapterFileName);
        if (bytes != null && bytes.isNotEmpty) {
          blocks.add(
            ReaderImageBlock(
              bytes: bytes,
              alt: node.attributes['alt'],
            ),
          );
        }
        return;
      }

      if (localName == 'svg') {
        for (final child in node.nodes) {
          walk(child);
        }
        return;
      }

      if (_isBlock(localName) || localName == 'br') {
        textBuffer.writeln();
      }

      for (final child in node.nodes) {
        walk(child);
      }

      if (_isBlock(localName)) {
        textBuffer.writeln();
      }
    }

    for (final node in root.nodes) {
      walk(node);
    }
    flushText();

    return blocks;
  }

  bool _isInternalHref(String href) {
    final lower = href.trim().toLowerCase();
    return !(lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('mailto:') ||
        lower.startsWith('www.'));
  }

  Uint8List? _resolveImage(
    String? rawSrc,
    Map<String, Uint8List> images,
    String? chapterFileName,
  ) {
    if (rawSrc == null || rawSrc.trim().isEmpty) {
      return null;
    }

    var src = rawSrc.trim();
    if (src.startsWith('data:')) {
      return null;
    }

    src = src.split('#').first.split('?').first;
    src = src.replaceAll('\\', '/');

    final candidates = <String>{
      src,
      _stripLeadingDotSlash(src),
      p.url.normalize(src),
      p.basename(src),
    };

    if (chapterFileName != null && chapterFileName.isNotEmpty) {
      final chapterDir = p.url.dirname(chapterFileName.replaceAll('\\', '/'));
      final joined = p.url.normalize(
        chapterDir == '.' || chapterDir.isEmpty
            ? src
            : p.url.join(chapterDir, src),
      );
      candidates
        ..add(joined)
        ..add(_stripLeadingDotSlash(joined))
        ..add(p.basename(joined));
    }

    for (final key in images.keys) {
      final normalizedKey = key.replaceAll('\\', '/');
      for (final candidate in candidates) {
        if (_pathsMatch(normalizedKey, candidate)) {
          return images[key];
        }
      }
    }

    return null;
  }

  bool _pathsMatch(String storedKey, String candidate) {
    final a = _stripLeadingDotSlash(storedKey).toLowerCase();
    final b = _stripLeadingDotSlash(candidate).toLowerCase();
    if (a == b) return true;
    if (a.endsWith('/$b') || b.endsWith('/$a')) return true;
    return p.basename(a) == p.basename(b);
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

  bool _isBlock(String? localName) {
    return localName == 'p' ||
        localName == 'div' ||
        localName == 'h1' ||
        localName == 'h2' ||
        localName == 'h3' ||
        localName == 'h4' ||
        localName == 'li' ||
        localName == 'tr' ||
        localName == 'section' ||
        localName == 'blockquote' ||
        localName == 'figure' ||
        localName == 'figcaption';
  }

  String _normalize(String text) {
    return text
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
