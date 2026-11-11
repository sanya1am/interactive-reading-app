import '../../../../core/utils/result.dart';
import '../entities/text_analysis.dart';

abstract class AiAnalysisRepository {
  Future<Result<TextAnalysis>> analyzeText({
    required String selectedText,
    required String context,
    String book = '',
    String author = '',
    String edition = '',
  });
}