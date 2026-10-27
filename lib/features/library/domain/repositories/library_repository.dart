import '../../../../core/utils/result.dart';
import '../entities/book.dart';

abstract class LibraryRepository {
  Future<Result<List<Book>>> getBooks();

  Future<Result<Book>> importBookFromDevice();

  Future<Result<void>> deleteBook(
      String bookId,
      );

  Future<Result<void>> updateReadingProgress({
    required String bookId,
    required double progress,
    String? lastCfi,
    int? lastPageIndex,
  });

  Future<Result<void>> setFavorite({
    required String bookId,
    required bool isFavorite,
  });

  Future<Result<Book>> getBookById(
      String bookId,
      );
}