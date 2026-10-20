import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/di/injection.dart';
import '../../../library/domain/entities/book.dart';
import '../viewmodels/reader_view_model.dart';
import '../widgets/reader_page_content.dart';

class ReaderPage extends StatelessWidget {
  const ReaderPage({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl.createReaderViewModel()..open(book),
      child: const _ReaderView(),
    );
  }
}

class _ReaderView extends StatefulWidget {
  const _ReaderView();

  @override
  State<_ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<_ReaderView> {
  PageController? _pageController;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _ensureController(int initialPage) {
    if (_pageController != null) return;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderViewModel>(
      builder: (context, viewModel, _) {
        final document = viewModel.document;

        if (viewModel.status == ReaderStatus.ready && document != null) {
          _ensureController(document.initialPageIndex);
        }

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) {
              await viewModel.saveProgressOnExit();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                document?.title ?? 'Чтение',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                if (document != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Text(
                        viewModel.pageLabel,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
              ],
            ),
            body: switch (viewModel.status) {
              ReaderStatus.initial || ReaderStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
              ReaderStatus.error => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          viewModel.errorMessage ?? 'Ошибка открытия книги',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Text('Назад'),
                        ),
                      ],
                    ),
                  ),
                ),
              ReaderStatus.ready => _ReadyBody(
                  pageController: _pageController!,
                ),
            },
          ),
        );
      },
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.pageController,
  });

  final PageController pageController;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReaderViewModel>();
    final document = viewModel.document!;
    final theme = Theme.of(context);

    return Column(
      children: [
        LinearProgressIndicator(
          value: viewModel.progress,
          minHeight: 3,
        ),
        if (viewModel.currentPage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                viewModel.currentPage!.chapterTitle,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        Expanded(
          child: PageView.builder(
            controller: pageController,
            itemCount: document.totalPages,
            onPageChanged: viewModel.goToPage,
            itemBuilder: (context, index) {
              final page = document.pages[index];
              return ReaderPageContent(
                blocks: page.blocks,
                onLinkTap: (href) async {
                  final target = viewModel.resolveInternalLink(href);
                  if (target == null) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Не удалось открыть ссылку оглавления'),
                      ),
                    );
                    return;
                  }
                  pageController.jumpToPage(target);
                  await viewModel.goToPage(target);
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: viewModel.currentPageIndex > 0
                      ? () {
                          pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    viewModel.pageLabel,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed:
                      viewModel.currentPageIndex < document.totalPages - 1
                          ? () {
                              pageController.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            }
                          : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
