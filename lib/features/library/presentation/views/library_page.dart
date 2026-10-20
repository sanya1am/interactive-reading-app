import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../reader/presentation/views/reader_page.dart';
import '../../domain/entities/book.dart';
import '../viewmodels/library_view_model.dart';
import '../widgets/book_list_item.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryViewModel>().loadBooks();
    });
  }

  Future<void> _importBook() async {
    final viewModel = context.read<LibraryViewModel>();
    final book = await viewModel.importBook();
    if (!mounted) return;

    if (viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage!)),
      );
      viewModel.clearError();
    } else if (book != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Добавлено: ${book.title}')),
      );
    }
  }

  Future<void> _openBook(Book book) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderPage(book: book),
      ),
    );
    if (!mounted) return;
    await context.read<LibraryViewModel>().loadBooks();
  }

  Future<void> _confirmDelete(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить книгу?'),
        content: Text('«${book.title}» будет удалена из библиотеки.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final viewModel = context.read<LibraryViewModel>();
    final deleted = await viewModel.deleteBook(book.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Книга удалена'
              : (viewModel.errorMessage ?? 'Не удалось удалить'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Библиотека'),
      ),
      floatingActionButton: Consumer<LibraryViewModel>(
        builder: (context, viewModel, _) {
          return FloatingActionButton.extended(
            onPressed: viewModel.isBusy ? null : _importBook,
            icon: viewModel.status == LibraryStatus.importing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.folder_open),
            label: const Text('Открыть EPUB'),
          );
        },
      ),
      body: Consumer<LibraryViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.status == LibraryStatus.loading &&
              viewModel.books.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.status == LibraryStatus.error &&
              viewModel.books.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(viewModel.errorMessage ?? 'Ошибка загрузки'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: viewModel.loadBooks,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (viewModel.isEmpty) {
            return const _EmptyLibrary();
          }

          return RefreshIndicator(
            onRefresh: viewModel.loadBooks,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              itemCount: viewModel.books.length,
              itemBuilder: (context, index) {
                final book = viewModel.books[index];
                return BookListItem(
                  book: book,
                  onTap: () => _openBook(book),
                  onDelete: () => _confirmDelete(book),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Библиотека пуста',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Выберите EPUB-файл с устройства, чтобы начать чтение иностранной литературы.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
