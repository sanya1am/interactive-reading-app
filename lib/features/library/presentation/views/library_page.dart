import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../reader/presentation/views/reader_page.dart';
import '../../domain/entities/book.dart';
import '../viewmodels/library_view_model.dart';
import '../widgets/book_list_item.dart';
import '../widgets/book_shelf_card.dart';

class LibraryPage
    extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() =>
      _LibraryPageState();
}

class _LibraryPageState
    extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback(
          (_) {
        context
            .read<LibraryViewModel>()
            .loadBooks();
      },
    );
  }

  Future<void> _importBook() async {
    final viewModel =
    context.read<LibraryViewModel>();

    final book =
    await viewModel.importBook();

    if (!mounted) return;

    if (viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            viewModel.errorMessage!,
          ),
        ),
      );

      viewModel.clearError();
    } else if (book != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Добавлено: ${book.title}',
          ),
        ),
      );
    }
  }

  Future<void> _openBook(
      Book book,
      ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ReaderPage(
              book: book,
            ),
      ),
    );

    if (!mounted) return;

    await context
        .read<LibraryViewModel>()
        .loadBooks();
  }

  Future<void> _confirmDelete(
      Book book,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title:
            const Text(
              'Удалить книгу?',
            ),
            content: Text(
              '«${book.title}» будет удалена из библиотеки.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                      false,
                    ),
                child:
                const Text(
                  'Отмена',
                ),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                      true,
                    ),
                child:
                const Text(
                  'Удалить',
                ),
              ),
            ],
          ),
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    final viewModel =
    context.read<LibraryViewModel>();

    final deleted =
    await viewModel.deleteBook(
      book.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Книга удалена'
              : (
              viewModel
                  .errorMessage ??
                  'Не удалось удалить'
          ),
        ),
      ),
    );
  }

  Future<void> _showSearch(
      List<Book> books,
      ) async {
    final selectedBook =
    await showSearch<Book?>(
      context: context,
      delegate:
      _BookSearchDelegate(
        books: books,
      ),
    );

    if (selectedBook != null &&
        mounted) {
      await _openBook(
        selectedBook,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child:
        Consumer<LibraryViewModel>(
          builder: (
              context,
              viewModel,
              _,
              ) {
            if (viewModel.status ==
                LibraryStatus.loading &&
                viewModel.books.isEmpty) {
              return const Center(
                child:
                CircularProgressIndicator(),
              );
            }

            if (viewModel.status ==
                LibraryStatus.error &&
                viewModel.books.isEmpty) {
              return _LoadError(
                message:
                viewModel.errorMessage ??
                    'Ошибка загрузки',
                onRetry:
                viewModel.loadBooks,
              );
            }

            return RefreshIndicator(
              onRefresh:
              viewModel.loadBooks,
              child: ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                padding:
                const EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  36,
                ),
                children: [
                  _Header(
                    onSearch:
                    viewModel
                        .books
                        .isEmpty
                        ? null
                        : () =>
                        _showSearch(
                          viewModel
                              .books,
                        ),
                    onImport:
                    viewModel.isBusy
                        ? null
                        : _importBook,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  _LibrarySummary(
                    viewModel:
                    viewModel,
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  _ImportBanner(
                    isImporting:
                    viewModel.status ==
                        LibraryStatus
                            .importing,
                    onTap:
                    viewModel.isBusy
                        ? null
                        : _importBook,
                  ),

                  if (viewModel
                      .continueReadingBooks
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 28,
                    ),

                    _SectionHeader(
                      title:
                      'Продолжить чтение',
                      trailing:
                      '${viewModel.continueReadingBooks.length}',
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    SizedBox(
                      height: 292,
                      child:
                      ListView.separated(
                        scrollDirection:
                        Axis.horizontal,
                        clipBehavior:
                        Clip.none,
                        itemCount:
                        viewModel
                            .continueReadingBooks
                            .length,
                        separatorBuilder:
                            (
                            _,
                            __,
                            ) =>
                        const SizedBox(
                          width: 14,
                        ),
                        itemBuilder: (
                            context,
                            index,
                            ) {
                          final book =
                          viewModel
                              .continueReadingBooks[
                          index];

                          return BookShelfCard(
                            book: book,
                            onTap: () =>
                                _openBook(
                                  book,
                                ),
                            onFavorite:
                                () =>
                                viewModel
                                    .toggleFavorite(
                                  book,
                                ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 28,
                  ),

                  const _SectionHeader(
                    title: 'Книги',
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  _FilterBar(
                    selected:
                    viewModel.filter,
                    favoriteCount:
                    viewModel
                        .favoriteCount,
                    readingCount:
                    viewModel
                        .readingBooks
                        .length,
                    onSelected:
                    viewModel.setFilter,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  if (viewModel
                      .books.isEmpty)
                    _EmptyLibrary(
                      onImport:
                      _importBook,
                    )
                  else if (viewModel
                      .filteredBooks
                      .isEmpty)
                    _EmptyFilter(
                      filter:
                      viewModel.filter,
                    )
                  else
                    ...viewModel
                        .filteredBooks
                        .map(
                          (book) =>
                          Column(
                            children: [
                              BookListItem(
                                book: book,
                                onTap: () =>
                                    _openBook(
                                      book,
                                    ),
                                onFavorite:
                                    () =>
                                    viewModel
                                        .toggleFavorite(
                                      book,
                                    ),
                                onDelete:
                                    () =>
                                    _confirmDelete(
                                      book,
                                    ),
                              ),
                              const Divider(
                                height: 1,
                              ),
                            ],
                          ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header
    extends StatelessWidget {
  const _Header({
    required this.onSearch,
    required this.onImport,
  });

  final VoidCallback? onSearch;

  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            'Моя библиотека',
            style: theme
                .textTheme
                .headlineLarge,
          ),
        ),
        IconButton(
          tooltip: 'Поиск',
          onPressed: onSearch,
          icon: const Icon(
            Icons.search_rounded,
          ),
        ),
        const SizedBox(width: 4),
        IconButton.filled(
          tooltip:
          'Импортировать EPUB',
          onPressed: onImport,
          style:
          IconButton.styleFrom(
            backgroundColor:
            AppTheme.primary,
            foregroundColor:
            Colors.white,
          ),
          icon: const Icon(
            Icons.add_rounded,
          ),
        ),
      ],
    );
  }
}

class _LibrarySummary
    extends StatelessWidget {
  const _LibrarySummary({
    required this.viewModel,
  });

  final LibraryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    final progress =
    viewModel.averageReadingProgress
        .clamp(
      0.0,
      1.0,
    );

    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color:
          AppTheme.outline,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _Stat(
                  value:
                  '${viewModel.books.length}',
                  label:
                  'книг в библиотеке',
                ),
                const SizedBox(
                  width: 24,
                ),
                _Stat(
                  value:
                  '${viewModel.readingBooks.length}',
                  label:
                  'читаю сейчас',
                ),
              ],
            ),
          ),
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment:
              Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor:
                  theme
                      .colorScheme
                      .surfaceContainerHighest,
                  color:
                  AppTheme.primary,
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat
    extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
  });

  final String value;

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return Flexible(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme
                .textTheme
                .headlineMedium
                ?.copyWith(
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            style: theme
                .textTheme
                .bodySmall
                ?.copyWith(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportBanner
    extends StatelessWidget {
  const _ImportBanner({
    required this.isImporting,
    required this.onTap,
  });

  final bool isImporting;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary,
      borderRadius:
      BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(20),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          child: Row(
            children: [
              isImporting
                  ? const SizedBox(
                width: 28,
                height: 28,
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2.5,
                  color:
                  Colors.white,
                ),
              )
                  : const Icon(
                Icons
                    .file_upload_outlined,
                color:
                Colors.white,
                size: 28,
              ),

              const SizedBox(
                width: 14,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      'Импортировать книгу',
                      style: TextStyle(
                        color:
                        Colors.white,
                        fontSize: 16,
                        fontWeight:
                        FontWeight
                            .w700,
                      ),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      'Добавьте EPUB с устройства',
                      style: TextStyle(
                        color:
                        Color(
                          0xFFE7EFEA,
                        ),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons
                    .chevron_right_rounded,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader
    extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  final String title;

  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme
                .textTheme
                .titleLarge,
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: theme
                .textTheme
                .bodySmall
                ?.copyWith(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _FilterBar
    extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.favoriteCount,
    required this.readingCount,
    required this.onSelected,
  });

  final LibraryFilter selected;

  final int favoriteCount;

  final int readingCount;

  final ValueChanged<LibraryFilter>
  onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: 'Все',
          selected:
          selected ==
              LibraryFilter.all,
          onTap: () =>
              onSelected(
                LibraryFilter.all,
              ),
        ),
        _FilterChip(
          label:
          'Избранное ($favoriteCount)',
          selected:
          selected ==
              LibraryFilter
                  .favorites,
          onTap: () =>
              onSelected(
                LibraryFilter.favorites,
              ),
        ),
        _FilterChip(
          label:
          'Читаю ($readingCount)',
          selected:
          selected ==
              LibraryFilter.reading,
          onTap: () =>
              onSelected(
                LibraryFilter.reading,
              ),
        ),
      ],
    );
  }
}

class _FilterChip
    extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;

  final bool selected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    );
  }
}

class _EmptyLibrary
    extends StatelessWidget {
  const _EmptyLibrary({
    required this.onImport,
  });

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 42,
      ),
      child: Column(
        children: [
          Icon(
            Icons
                .auto_stories_outlined,
            size: 58,
            color: theme
                .colorScheme
                .primary,
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            'Библиотека пуста',
            style: theme
                .textTheme
                .titleLarge,
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            'Импортируйте первую EPUB-книгу, чтобы начать чтение.',
            textAlign:
            TextAlign.center,
            style: theme
                .textTheme
                .bodyMedium
                ?.copyWith(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          FilledButton.icon(
            onPressed: onImport,
            icon: const Icon(
              Icons.add_rounded,
            ),
            label:
            const Text(
              'Добавить книгу',
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFilter
    extends StatelessWidget {
  const _EmptyFilter({
    required this.filter,
  });

  final LibraryFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    final message =
    switch (filter) {
      LibraryFilter.favorites =>
      'В избранном пока нет книг',

      LibraryFilter.reading =>
      'Сейчас нет начатых книг',

      LibraryFilter.all =>
      'Книг пока нет',
    };

    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 32,
      ),
      child: Center(
        child: Text(
          message,
          style: theme
              .textTheme
              .bodyMedium
              ?.copyWith(
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _LoadError
    extends StatelessWidget {
  const _LoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign:
              TextAlign.center,
            ),
            const SizedBox(
              height: 12,
            ),
            FilledButton(
              onPressed: onRetry,
              child:
              const Text(
                'Повторить',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookSearchDelegate
    extends SearchDelegate<Book?> {
  _BookSearchDelegate({
    required this.books,
  });

  final List<Book> books;

  @override
  String get searchFieldLabel =>
      'Название или автор';

  @override
  ThemeData appBarTheme(
      BuildContext context,
      ) {
    final base =
    Theme.of(context);

    return base.copyWith(
      scaffoldBackgroundColor:
      AppTheme.background,
      appBarTheme:
      base.appBarTheme.copyWith(
        backgroundColor:
        AppTheme.background,
      ),
      inputDecorationTheme:
      const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(
      BuildContext context,
      ) {
    if (query.isEmpty) {
      return null;
    }

    return [
      IconButton(
        onPressed: () =>
        query = '',
        icon:
        const Icon(
          Icons.close_rounded,
        ),
      ),
    ];
  }

  @override
  Widget? buildLeading(
      BuildContext context,
      ) {
    return IconButton(
      onPressed: () =>
          close(
            context,
            null,
          ),
      icon:
      const Icon(
        Icons.arrow_back_rounded,
      ),
    );
  }

  @override
  Widget buildResults(
      BuildContext context,
      ) =>
      _buildList(context);

  @override
  Widget buildSuggestions(
      BuildContext context,
      ) =>
      _buildList(context);

  Widget _buildList(
      BuildContext context,
      ) {
    final normalized =
    query
        .trim()
        .toLowerCase();

    final results =
    normalized.isEmpty
        ? books
        : books
        .where(
          (book) {
        final title =
        book.title
            .toLowerCase();

        final author =
            book.author
                ?.toLowerCase() ??
                '';

        return title
            .contains(
          normalized,
        ) ||
            author
                .contains(
              normalized,
            );
      },
    )
        .toList(
      growable:
      false,
    );

    if (results.isEmpty) {
      return const Center(
        child: Text(
          'Ничего не найдено',
        ),
      );
    }

    return ListView.separated(
      padding:
      const EdgeInsets.all(
        20,
      ),
      itemCount:
      results.length,
      separatorBuilder:
          (
          _,
          __,
          ) =>
      const Divider(),
      itemBuilder:
          (
          context,
          index,
          ) {
        final book =
        results[index];

        return ListTile(
          contentPadding:
          EdgeInsets.zero,
          title:
          Text(book.title),
          subtitle:
          book.author == null
              ? null
              : Text(
            book.author!,
          ),
          trailing:
          const Icon(
            Icons
                .chevron_right_rounded,
          ),
          onTap: () =>
              close(
                context,
                book,
              ),
        );
      },
    );
  }
}