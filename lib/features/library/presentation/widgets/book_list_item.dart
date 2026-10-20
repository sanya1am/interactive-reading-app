import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/book.dart';

class BookListItem extends StatelessWidget {
  const BookListItem({
    super.key,
    required this.book,
    required this.onTap,
    required this.onDelete,
  });

  final Book book;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = (book.readingProgress * 100).clamp(0, 100).round();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _CoverThumb(coverPath: book.coverPath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (book.author != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        book.author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      progressPercent == 0
                          ? 'Не начато'
                          : 'Прогресс: $progressPercent%',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (book.readingProgress > 0) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: book.readingProgress.clamp(0, 1),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Удалить',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverThumb extends StatelessWidget {
  const _CoverThumb({required this.coverPath});

  final String? coverPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCover = coverPath != null && File(coverPath!).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 80,
        child: hasCover
            ? Image.file(
                File(coverPath!),
                fit: BoxFit.cover,
              )
            : ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.menu_book_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
      ),
    );
  }
}
