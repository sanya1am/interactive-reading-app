import 'reader_block.dart';

class ReaderPage {
  const ReaderPage({
    required this.index,
    required this.chapterTitle,
    required this.blocks,
    required this.chapterIndex,
    this.contentFileName,
  });

  final int index;
  final String chapterTitle;
  final List<ReaderBlock> blocks;
  final int chapterIndex;
  final String? contentFileName;

  bool get isEmpty => blocks.isEmpty;
}

class ReaderDocument {
  const ReaderDocument({
    required this.bookId,
    required this.title,
    required this.pages,
    this.author,
    this.initialPageIndex = 0,
    this.locationIndex = const {},
  });

  final String bookId;
  final String title;
  final String? author;
  final List<ReaderPage> pages;
  final int initialPageIndex;

  /// Normalized EPUB locations (`file`, `file#anchor`, basename variants)
  /// mapped to the first page index that contains them.
  final Map<String, int> locationIndex;

  int get totalPages => pages.length;

  int? resolveHref(String href, {String? fromFile}) {
    final target = _normalizeHref(href, fromFile: fromFile);
    if (target == null) return null;

    final file = target.file;
    final anchor = target.anchor;

    if (anchor != null && anchor.isNotEmpty) {
      final withAnchor = locationIndex[_key(file, anchor)] ??
          locationIndex[_key(_basename(file), anchor)];
      if (withAnchor != null) return withAnchor;
    }

    return locationIndex[_key(file)] ??
        locationIndex[_key(_basename(file))] ??
        locationIndex[_stripLeadingDotSlash(file).toLowerCase()];
  }

  static ({String file, String? anchor})? _normalizeHref(
    String href, {
    String? fromFile,
  }) {
    var raw = href.trim();
    if (raw.isEmpty) return null;

    final lower = raw.toLowerCase();
    if (lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('mailto:') ||
        lower.startsWith('www.')) {
      return null;
    }

    String? anchor;
    final hashIndex = raw.indexOf('#');
    if (hashIndex >= 0) {
      anchor = raw.substring(hashIndex + 1).trim();
      raw = raw.substring(0, hashIndex);
      if (anchor.isEmpty) anchor = null;
    }

    raw = raw.split('?').first.replaceAll('\\', '/');

    if (raw.isEmpty) {
      // Pure fragment: `#section` inside current file.
      if (anchor == null || fromFile == null || fromFile.isEmpty) {
        return null;
      }
      return (file: _stripLeadingDotSlash(fromFile), anchor: anchor);
    }

    if (fromFile != null && fromFile.isNotEmpty && !raw.startsWith('/')) {
      final dir = _dirname(fromFile);
      raw = _normalizePath(dir.isEmpty ? raw : '$dir/$raw');
    } else {
      raw = _normalizePath(raw);
    }

    return (file: _stripLeadingDotSlash(raw), anchor: anchor);
  }

  static String _key(String file, [String? anchor]) {
    final normalized = _stripLeadingDotSlash(file).toLowerCase();
    if (anchor == null || anchor.isEmpty) return normalized;
    return '$normalized#${anchor.toLowerCase()}';
  }

  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index < 0 ? normalized : normalized.substring(index + 1);
  }

  static String _dirname(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index <= 0) return '';
    return normalized.substring(0, index);
  }

  static String _normalizePath(String path) {
    final parts = <String>[];
    for (final part in path.replaceAll('\\', '/').split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (parts.isNotEmpty) parts.removeLast();
        continue;
      }
      parts.add(part);
    }
    return parts.join('/');
  }

  static String _stripLeadingDotSlash(String value) {
    var result = value.replaceAll('\\', '/');
    while (result.startsWith('./')) {
      result = result.substring(2);
    }
    while (result.startsWith('/')) {
      result = result.substring(1);
    }
    return result;
  }
}
