import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/book.dart';

class BookListItem
    extends StatelessWidget {
  const BookListItem({
    super.key,
    required this.book,
    required this.onTap,
    required this.onFavorite,
    required this.onDelete,
  });

  final Book book;

  final VoidCallback onTap;

  final VoidCallback onFavorite;

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    final progress =
    book.readingProgress
        .clamp(0.0, 1.0)
        .toDouble();

    final progressPercent =
    (progress * 100).round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(18),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(
            vertical: 9,
          ),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _CoverThumb(
                coverPath:
                book.coverPath,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding:
                  const EdgeInsets.only(
                    top: 3,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontFamily:
                          'serif',
                          fontWeight:
                          FontWeight
                              .w700,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        book.author
                            ?.trim()
                            .isNotEmpty ==
                            true
                            ? book.author!
                            : 'Автор не указан',
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Text(
                            progressPercent ==
                                0
                                ? 'Не начато'
                                : '$progressPercent%',
                            style: theme
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                              color: theme
                                  .colorScheme
                                  .primary,
                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),
                          if (progressPercent >
                              0) ...[
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child:
                              ClipRRect(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  999,
                                ),
                                child:
                                LinearProgressIndicator(
                                  value:
                                  progress,
                                  minHeight: 4,
                                  backgroundColor:
                                  theme
                                      .colorScheme
                                      .surfaceContainerHighest,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Column(
                children: [
                  IconButton(
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
                      color:
                      book.isFavorite
                          ? const Color(
                        0xFFB15C57,
                      )
                          : theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                  PopupMenuButton<
                      String>(
                    tooltip: 'Ещё',
                    onSelected: (
                        value,
                        ) {
                      if (value ==
                          'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder:
                        (context) =>
                    const [
                      PopupMenuItem(
                        value:
                        'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .delete_outline_rounded,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Удалить',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverThumb
    extends StatelessWidget {
  const _CoverThumb({
    required this.coverPath,
  });

  final String? coverPath;

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    final hasCover =
        coverPath != null &&
            File(coverPath!).existsSync();

    return ClipRRect(
      borderRadius:
      BorderRadius.circular(12),
      child: SizedBox(
        width: 70,
        height: 100,
        child: hasCover
            ? Image.file(
          File(coverPath!),
          fit: BoxFit.cover,
        )
            : ColoredBox(
          color: theme
              .colorScheme
              .surfaceContainerHighest,
          child: Icon(
            Icons
                .auto_stories_rounded,
            color: theme
                .colorScheme
                .primary,
            size: 30,
          ),
        ),
      ),
    );
  }
}