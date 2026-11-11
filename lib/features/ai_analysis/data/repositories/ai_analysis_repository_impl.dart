import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/text_analysis.dart';
import '../../domain/repositories/ai_analysis_repository.dart';
import '../datasources/ai_analysis_remote_datasource.dart';
import '../models/text_analysis_request_model.dart';

class AiAnalysisRepositoryImpl
    implements AiAnalysisRepository {
  AiAnalysisRepositoryImpl(
      this._remoteDataSource,
      );

  final AiAnalysisRemoteDataSource
  _remoteDataSource;

  @override
  Future<Result<TextAnalysis>> analyzeText({
    required String selectedText,
    required String context,
    String book = '',
    String author = '',
    String edition = '',
  }) async {
    try {
      final result =
      await _remoteDataSource.analyzeText(
        TextAnalysisRequestModel(
          selectedText: selectedText,
          context: context,
          book: book,
          author: author,
          edition: edition,
        ),
      );

      return Success(result);
    } on Failure catch (failure) {
      return Error(failure);
    } catch (error) {
      return Error(
        NetworkFailure(
          'Не удалось выполнить анализ текста: $error',
        ),
      );
    }
  }
}