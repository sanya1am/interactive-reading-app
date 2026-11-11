import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_theme.dart';
import '../viewmodels/ai_analysis_view_model.dart';

class AnalysisBottomSheet
    extends StatelessWidget {
  const AnalysisBottomSheet({
    super.key,
    required this.selectedText,
    required this.onRetry,
  });

  final String selectedText;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final viewModel =
    context.watch<AiAnalysisViewModel>();

    final theme =
    Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          6,
          22,
          22 +
              MediaQuery.viewInsetsOf(
                context,
              ).bottom,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration:
                BoxDecoration(
                  color:
                  AppTheme.outline,
                  borderRadius:
                  BorderRadius
                      .circular(
                    999,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            Text(
              'Разбор фразы',
              style:
              theme.textTheme
                  .titleLarge,
            ),

            const SizedBox(
              height: 10,
            ),

            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(
                14,
              ),
              decoration:
              BoxDecoration(
                color: theme
                    .colorScheme
                    .surfaceContainerLow,
                borderRadius:
                BorderRadius
                    .circular(
                  14,
                ),
                border:
                Border.all(
                  color:
                  AppTheme.outline,
                ),
              ),
              child: Text(
                '“$selectedText”',
                style: theme
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                  fontFamily:
                  'serif',
                  fontStyle:
                  FontStyle
                      .italic,
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            switch (
            viewModel.status) {
              AiAnalysisStatus.idle ||
              AiAnalysisStatus.loading =>
              const _LoadingState(),

              AiAnalysisStatus.success =>
                  _SuccessState(
                    translation:
                    viewModel
                        .analysis!
                        .translation,
                    explanation:
                    viewModel
                        .analysis!
                        .explanation,
                  ),

              AiAnalysisStatus.error =>
                  _ErrorState(
                    message:
                    viewModel
                        .errorMessage ??
                        'Неизвестная ошибка',
                    retryAfterSeconds:
                    viewModel
                        .retryAfterSeconds,
                    onRetry:
                    onRetry,
                  ),
            },
          ],
        ),
      ),
    );
  }
}

class _LoadingState
    extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(
      BuildContext context,
      ) {
    return const Padding(
      padding:
      EdgeInsets.symmetric(
        vertical: 28,
      ),
      child: Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'Анализируем фразу в контексте…',
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessState
    extends StatelessWidget {
  const _SuccessState({
    required this.translation,
    required this.explanation,
  });

  final String translation;

  final String explanation;

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Перевод',
          style: theme
              .textTheme
              .labelLarge
              ?.copyWith(
            color:
            AppTheme.primary,
            fontWeight:
            FontWeight.w700,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          translation.isEmpty
              ? '—'
              : translation,
          style: theme
              .textTheme
              .titleMedium
              ?.copyWith(
            fontFamily: 'serif',
            fontWeight:
            FontWeight.w700,
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'Смысл в контексте',
          style: theme
              .textTheme
              .labelLarge
              ?.copyWith(
            color:
            AppTheme.primary,
            fontWeight:
            FontWeight.w700,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          explanation.isEmpty
              ? '—'
              : explanation,
          style:
          theme.textTheme
              .bodyLarge,
        ),
      ],
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.retryAfterSeconds,
    required this.onRetry,
  });

  final String message;

  final int? retryAfterSeconds;

  final VoidCallback onRetry;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style:
            Theme.of(context)
                .textTheme
                .bodyLarge,
          ),

          if (retryAfterSeconds !=
              null) ...[
            const SizedBox(
              height: 6,
            ),
            Text(
              'Повторный запрос доступен через '
                  '$retryAfterSeconds сек.',
              style:
              Theme.of(context)
                  .textTheme
                  .bodySmall,
            ),
          ],

          const SizedBox(
            height: 14,
          ),

          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label:
            const Text(
              'Повторить',
            ),
          ),
        ],
      ),
    );
  }
}