import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/reader_document.dart';
import '../../domain/repositories/reader_repository.dart';
import '../datasources/epub_reader_datasource.dart';

class ReaderRepositoryImpl implements ReaderRepository {
  ReaderRepositoryImpl(this._dataSource);

  final EpubReaderDataSource _dataSource;

  @override
  Future<Result<ReaderDocument>> openBook({
    required String bookId,
    required String filePath,
    required String title,
    String? author,
    double initialProgress = 0,
    String? initialCfi,
  }) async {
    try {
      await _dataSource.validateBookFile(filePath);

      final safeProgress =
      initialProgress.clamp(0.0, 1.0).toDouble();

      final safeCfi = initialCfi?.trim();

      return Success(
        ReaderDocument(
          bookId: bookId,
          title: title,
          author: author,
          filePath: filePath,
          initialProgress: safeProgress,
          initialCfi:
          safeCfi == null || safeCfi.isEmpty
              ? null
              : safeCfi,
        ),
      );
    } on Failure catch (failure) {
      return Error(failure);
    } catch (error) {
      return Error(
        FileFailure(
          'Не удалось открыть книгу: $error',
        ),
      );
    }
  }
}