import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:provider/provider.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../library/domain/entities/book.dart';
import '../../domain/entities/reader_document.dart';
import '../viewmodels/reader_view_model.dart';

class ReaderPage
    extends StatelessWidget {
  const ReaderPage({
    super.key,
    required this.book,
  });

  final Book book;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      sl.createReaderViewModel()
        ..open(book),
      child: const _ReaderView(),
    );
  }
}

class _ReaderView
    extends StatefulWidget {
  const _ReaderView();

  @override
  State<_ReaderView> createState() =>
      _ReaderViewState();
}

class _ReaderViewState
    extends State<_ReaderView> {
  final EpubController
  _epubController =
  EpubController();

  EpubSource? _epubSource;

  String? _epubSourcePath;

  bool _restoredByProgress =
  false;

  double _fontSize = 16;

  EpubSource _sourceFor(
      String filePath,
      ) {
    if (_epubSource == null ||
        _epubSourcePath !=
            filePath) {
      _epubSourcePath =
          filePath;

      _epubSource =
          EpubSource.fromFile(
            File(filePath),
          );

      _restoredByProgress =
      false;
    }

    return _epubSource!;
  }

  Future<void>
  _showReadingSettings() async {
    var temporaryFontSize =
        _fontSize;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor:
      AppTheme.surface,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (
              context,
              setSheetState,
              ) {
            return SafeArea(
              top: false,
              child: Padding(
                padding:
                const EdgeInsets
                    .fromLTRB(
                  24,
                  6,
                  24,
                  28,
                ),
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      'Настройки чтения',
                      style:
                      Theme.of(
                        context,
                      ).textTheme
                          .titleLarge,
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Row(
                      children: [
                        const Text(
                          'Aa',
                          style:
                          TextStyle(
                            fontSize:
                            14,
                          ),
                        ),
                        Expanded(
                          child:
                          Slider(
                            min: 13,
                            max: 26,
                            divisions:
                            13,
                            value:
                            temporaryFontSize,
                            onChanged:
                                (
                                value,
                                ) {
                              setSheetState(
                                    () {
                                  temporaryFontSize =
                                      value;
                                },
                              );

                              _epubController
                                  .setFontSize(
                                fontSize:
                                value,
                              );
                            },
                          ),
                        ),
                        const Text(
                          'Aa',
                          style:
                          TextStyle(
                            fontSize:
                            24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      'Размер текста: ${temporaryFontSize.round()}',
                      style:
                      Theme.of(
                        context,
                      ).textTheme
                          .bodySmall
                          ?.copyWith(
                        color:
                        Theme.of(
                          context,
                        ).colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (mounted) {
      setState(
            () {
          _fontSize =
              temporaryFontSize;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<
        ReaderViewModel>(
      builder: (
          context,
          viewModel,
          _,
          ) {
        final document =
            viewModel.document;

        return PopScope(
          canPop: true,
          onPopInvokedWithResult:
              (
              didPop,
              _,
              ) async {
            if (didPop) {
              await viewModel
                  .saveProgressOnExit();
            }
          },
          child: Scaffold(
            backgroundColor:
            AppTheme.background,

            appBar: AppBar(
              toolbarHeight: 72,
              centerTitle: true,

              leading: IconButton(
                tooltip: 'Назад',
                onPressed: () =>
                    Navigator.of(
                      context,
                    ).maybePop(),
                icon:
                const Icon(
                  Icons
                      .arrow_back_ios_new_rounded,
                  size: 20,
                ),
              ),

              title:
              document == null
                  ? const Text(
                'Чтение',
              )
                  : Column(
                mainAxisSize:
                MainAxisSize
                    .min,
                children: [
                  Text(
                    document
                        .title,
                    maxLines:
                    1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    Theme.of(
                      context,
                    ).textTheme
                        .titleMedium
                        ?.copyWith(
                      fontFamily:
                      'serif',
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),
                  if (document
                      .author
                      ?.trim()
                      .isNotEmpty ==
                      true) ...[
                    const SizedBox(
                      height:
                      2,
                    ),
                    Text(
                      document
                          .author!,
                      maxLines:
                      1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      Theme.of(
                        context,
                      ).textTheme
                          .labelSmall
                          ?.copyWith(
                        color:
                        Theme.of(
                          context,
                        ).colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),

              actions: [
                IconButton(
                  tooltip:
                  'Настройки чтения',
                  onPressed:
                  document == null
                      ? null
                      : _showReadingSettings,
                  icon:
                  const Text(
                    'Aa',
                    style:
                    TextStyle(
                      fontFamily:
                      'serif',
                      fontSize:
                      18,
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 6,
                ),
              ],
            ),

            body:
            switch (
            viewModel.status) {
              ReaderStatus.initial ||
              ReaderStatus.loading =>
              const Center(
                child:
                CircularProgressIndicator(),
              ),

              ReaderStatus.error =>
                  _ErrorBody(
                    message:
                    viewModel
                        .errorMessage ??
                        'Ошибка открытия книги',
                  ),

              ReaderStatus.ready =>
                  _buildReader(
                    context,
                    viewModel,
                    document!,
                  ),
            },
          ),
        );
      },
    );
  }

  Widget _buildReader(
      BuildContext context,
      ReaderViewModel viewModel,
      ReaderDocument document,
      ) {
    final source =
    _sourceFor(
      document.filePath,
    );

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: EpubViewer(
                  epubController:
                  _epubController,

                  epubSource:
                  source,

                  initialCfi:
                  document
                      .initialCfi,

                  displaySettings:
                  EpubDisplaySettings(
                    flow:
                    EpubFlow
                        .paginated,

                    spread:
                    EpubSpread
                        .none,

                    snap: false,

                    useSnapAnimationAndroid:
                    false,

                    allowScriptedContent:
                    false,
                  ),

                  selectionContextMenu:
                  EpubContextMenu(
                    hideDefaultSystemItems:
                    true,
                    items: [
                      EpubContextMenuItem(
                        id: 1,
                        title:
                        'Копировать',
                        action:
                            () {
                          final text =
                          viewModel
                              .selectedText
                              ?.trim();

                          if (text ==
                              null ||
                              text
                                  .isEmpty) {
                            return;
                          }

                          Clipboard
                              .setData(
                            ClipboardData(
                              text:
                              text,
                            ),
                          );

                          _epubController
                              .clearSelection();
                        },
                      ),
                      EpubContextMenuItem(
                        id: 2,
                        title:
                        'Перевести',
                        action:
                            () {
                          final text =
                          viewModel
                              .selectedText
                              ?.trim();

                          if (text ==
                              null ||
                              text
                                  .isEmpty) {
                            return;
                          }

                          ScaffoldMessenger
                              .of(
                            context,
                          ).showSnackBar(
                            const SnackBar(
                              content:
                              Text(
                                'Перевод подключим к backend следующим этапом',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  onEpubLoaded:
                      () {
                    viewModel
                        .onViewerLoaded();

                    _epubController
                        .updateTheme(
                      theme:
                      EpubTheme
                          .custom(
                        customCss:
                        {
                          '::selection':
                          {
                            'background':
                            'rgba(69, 107, 87, 0.28)',
                          },
                        },
                      ),
                    );
                  },

                  onLocationLoaded:
                      () {
                    if (_restoredByProgress) {
                      return;
                    }

                    if (document
                        .initialCfi !=
                        null) {
                      return;
                    }

                    if (document
                        .initialProgress <=
                        0) {
                      return;
                    }

                    _restoredByProgress =
                    true;

                    _epubController
                        .toProgressPercentage(
                      document
                          .initialProgress,
                    );
                  },

                  onRelocated:
                      (
                      location,
                      ) {
                    viewModel
                        .onRelocated(
                      progress:
                      location
                          .progress,
                      startCfi:
                      location
                          .startCfi,
                    );
                  },

                  onTextSelected:
                      (
                      selection,
                      ) {
                    viewModel
                        .onTextSelected(
                      text:
                      selection
                          .selectedText,
                      cfi:
                      selection
                          .selectionCfi,
                    );
                  },

                  onDeselection:
                  viewModel
                      .clearSelection,

                  onLoadError:
                      (
                      error,
                      ) {
                    viewModel
                        .onViewerError(
                      error
                          .toString(),
                    );
                  },

                  clearSelectionOnPageChange:
                  false,
                ),
              ),

              if (!viewModel
                  .viewerLoaded)
                const Positioned.fill(
                  child:
                  ColoredBox(
                    color:
                    AppTheme
                        .background,
                    child:
                    Center(
                      child:
                      CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        ),

        _ReaderBottomBar(
          progress:
          viewModel.progress,
          progressPercent:
          viewModel
              .progressPercent,
          onPrevious: () =>
              _epubController
                  .prev(),
          onNext: () =>
              _epubController
                  .next(),
        ),
      ],
    );
  }
}

class _ReaderBottomBar
    extends StatelessWidget {
  const _ReaderBottomBar({
    required this.progress,
    required this.progressPercent,
    required this.onPrevious,
    required this.onNext,
  });

  final double progress;

  final int progressPercent;

  final VoidCallback onPrevious;

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding:
        const EdgeInsets.fromLTRB(
          18,
          10,
          18,
          12,
        ),
        decoration:
        const BoxDecoration(
          color:
          AppTheme.background,
          border: Border(
            top: BorderSide(
              color:
              AppTheme.outline,
            ),
          ),
        ),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'Назад',
              onPressed: onPrevious,
              icon:
              const Icon(
                Icons
                    .chevron_left_rounded,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius:
                    BorderRadius
                        .circular(
                      999,
                    ),
                    child:
                    LinearProgressIndicator(
                      value: progress
                          .clamp(
                        0.0,
                        1.0,
                      ),
                      minHeight: 5,
                      backgroundColor:
                      theme
                          .colorScheme
                          .surfaceContainerHighest,
                      color:
                      AppTheme
                          .primary,
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Text(
                    '$progressPercent%',
                    style: theme
                        .textTheme
                        .labelMedium
                        ?.copyWith(
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            IconButton.filledTonal(
              tooltip: 'Далее',
              onPressed: onNext,
              icon:
              const Icon(
                Icons
                    .chevron_right_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody
    extends StatelessWidget {
  const _ErrorBody({
    required this.message,
  });

  final String message;

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
              onPressed: () =>
                  Navigator.of(
                    context,
                  ).maybePop(),
              child:
              const Text(
                'Назад',
              ),
            ),
          ],
        ),
      ),
    );
  }
}