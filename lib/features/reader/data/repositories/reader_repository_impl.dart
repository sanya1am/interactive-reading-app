import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/reader_page.dart';
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
    int initialPageIndex = 0,
  }) async {
    try {
      final loaded = await _dataSource.loadBook(filePath);
      final pages = loaded.pages;
      final safeInitial = initialPageIndex.clamp(0, pages.length - 1);

      return Success(
        ReaderDocument(
          bookId: bookId,
          title: title,
          author: author,
          pages: pages,
          initialPageIndex: safeInitial,
          locationIndex: loaded.locationIndex,
        ),
      );
    } on Failure catch (failure) {
      return Error(failure);
    } catch (error) {
      return Error(ParsingFailure('Не удалось открыть книгу: $error'));
    }
  }
}
