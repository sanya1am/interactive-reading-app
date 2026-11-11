import '../../../../core/utils/result.dart';
import '../entities/text_analysis.dart';
import '../repositories/ai_analysis_repository.dart';

class AnalyzeText {
  const AnalyzeText(this._repository);

  final AiAnalysisRepository _repository;

  Future<Result<TextAnalysis>> call({
    required String selectedText,
    required String context,
    String book = '',
    String author = '',
    String edition = '',
  }) {
    return _repository.analyzeText(
      selectedText: selectedText,
      context: context,
      book: book,
      author: author,
      edition: edition,
    );
  }
}