import 'dart:typed_data';

sealed class ReaderBlock {
  const ReaderBlock();
}

final class ReaderTextBlock extends ReaderBlock {
  const ReaderTextBlock(this.text);

  final String text;
}

final class ReaderImageBlock extends ReaderBlock {
  const ReaderImageBlock({
    required this.bytes,
    this.alt,
  });

  final Uint8List bytes;
  final String? alt;
}

/// Internal EPUB hyperlink (TOC and in-text references).
final class ReaderLinkBlock extends ReaderBlock {
  const ReaderLinkBlock({
    required this.label,
    required this.href,
  });

  final String label;
  final String href;
}

/// Invisible marker for `id`/`name` anchors used by TOC links.
final class ReaderAnchorMark extends ReaderBlock {
  const ReaderAnchorMark(this.id);

  final String id;
}
