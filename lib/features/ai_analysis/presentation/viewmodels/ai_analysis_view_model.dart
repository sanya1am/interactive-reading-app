import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/text_analysis.dart';
import '../../domain/usecases/analyze_text.dart';

enum AiAnalysisStatus {
  idle,
  loading,
  success,
  error,
}

class AiAnalysisViewModel
    extends ChangeNotifier {
  AiAnalysisViewModel({
    required AnalyzeText analyzeText,
  }) : _analyzeText = analyzeText;

  final AnalyzeText _analyzeText;

  AiAnalysisStatus _status =
      AiAnalysisStatus.idle;

  TextAnalysis? _analysis;

  String? _errorMessage;

  int? _retryAfterSeconds;

  AiAnalysisStatus get status =>
      _status;

  TextAnalysis? get analysis =>
      _analysis;

  String? get errorMessage =>
      _errorMessage;

  int? get retryAfterSeconds =>
      _retryAfterSeconds;

  Future<void> analyze({
    required String selectedText,
    required String context,
    String book = '',
    String author = '',
    String edition = '',
  }) async {
    _status =
        AiAnalysisStatus.loading;

    _analysis = null;
    _errorMessage = null;
    _retryAfterSeconds = null;

    notifyListeners();

    final result =
    await _analyzeText(
      selectedText: selectedText,
      context: context,
      book: book,
      author: author,
      edition: edition,
    );

    if (result.isSuccess) {
      _analysis =
          result.valueOrNull;

      _status =
          AiAnalysisStatus.success;
    } else {
      final failure =
          result.failureOrNull;

      _errorMessage =
          failure?.message ??
              'Не удалось получить ответ';

      _retryAfterSeconds =
      failure is ApiFailure
          ? failure
          .retryAfterSeconds
          : null;

      _status =
          AiAnalysisStatus.error;
    }

    notifyListeners();
  }

  void reset() {
    _status =
        AiAnalysisStatus.idle;

    _analysis = null;
    _errorMessage = null;
    _retryAfterSeconds = null;

    notifyListeners();
  }
}