import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../domain/entities/reader_block.dart';

class ReaderPageContent extends StatelessWidget {
  const ReaderPageContent({
    super.key,
    required this.blocks,
    this.onLinkTap,
  });

  final List<ReaderBlock> blocks;
  final ValueChanged<String>? onLinkTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      height: 1.55,
      fontSize: 18,
    );
    final linkStyle = textStyle?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            switch (blocks[i]) {
              ReaderTextBlock(:final text) => SelectableText(
                  text,
                  style: textStyle,
                ),
              ReaderImageBlock(:final bytes, :final alt) => _ReaderImage(
                  bytes: bytes,
                  alt: alt,
                ),
              ReaderLinkBlock(:final label, :final href) => Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: onLinkTap == null ? null : () => onLinkTap!(href),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(label, style: linkStyle),
                    ),
                  ),
                ),
              ReaderAnchorMark() => const SizedBox.shrink(),
            },
          ],
        ],
      ),
    );
  }
}

class _ReaderImage extends StatelessWidget {
  const _ReaderImage({
    required this.bytes,
    this.alt,
  });

  final Uint8List bytes;
  final String? alt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Не удалось показать изображение',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
        if (alt != null && alt!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            alt!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
