import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/book.dart';

class BookShelfCard
    extends StatelessWidget {
  const BookShelfCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onFavorite,
  });

  final Book book;

  final VoidCallback onTap;

  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    final progress =
    book.readingProgress
        .clamp(0.0, 1.0)
        .toDouble();

    final percent =
    (progress * 100).round();

    return SizedBox(
      width: 146,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _BookCover(
                  coverPath:
                  book.coverPath,
                  width: 146,
                  height: 210,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black
                        .withValues(
                      alpha: 0.38,
                    ),
                    shape:
                    const CircleBorder(),
                    child: IconButton(
                      visualDensity:
                      VisualDensity.compact,
                      tooltip:
                      book.isFavorite
                          ? 'Убрать из избранного'
                          : 'В избранное',
                      onPressed:
                      onFavorite,
                      icon: Icon(
                        book.isFavorite
                            ? Icons
                            .favorite_rounded
                            : Icons
                            .favorite_border_rounded,
                        size: 19,
                        color:
                        Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              book.title,
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
              style: theme
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                fontFamily: 'serif',
                fontWeight:
                FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              book.author
                  ?.trim()
                  .isNotEmpty ==
                  true
                  ? book.author!
                  : 'Автор не указан',
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style: theme
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                    BorderRadius
                        .circular(
                      999,
                    ),
                    child:
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor:
                      theme
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percent%',
                  style: theme
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCover
    extends StatelessWidget {
  const _BookCover({
    required this.coverPath,
    required this.width,
    required this.height,
  });

  final String? coverPath;

  final double width;

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    final hasCover =
        coverPath != null &&
            File(coverPath!).existsSync();

    return ClipRRect(
      borderRadius:
      BorderRadius.circular(16),
      child: SizedBox(
        width: width,
        height: height,
        child: hasCover
            ? Image.file(
          File(coverPath!),
          fit: BoxFit.cover,
        )
            : DecoratedBox(
          decoration:
          BoxDecoration(
            color: theme
                .colorScheme
                .surfaceContainerHighest,
            gradient:
            LinearGradient(
              begin:
              Alignment.topLeft,
              end: Alignment
                  .bottomRight,
              colors: [
                theme
                    .colorScheme
                    .primary
                    .withValues(
                  alpha: 0.18,
                ),
                theme
                    .colorScheme
                    .surfaceContainerHighest,
              ],
            ),
          ),
          child: Icon(
            Icons
                .auto_stories_rounded,
            size: 42,
            color: theme
                .colorScheme
                .primary,
          ),
        ),
      ),
    );
  }
}