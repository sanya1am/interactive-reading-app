import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/epub_file_datasource.dart';
import '../datasources/library_local_datasource.dart';
import '../models/book_model.dart';

class LibraryRepositoryImpl
    implements LibraryRepository {
  LibraryRepositoryImpl({
    required this.localDataSource,
    required this.epubFileDataSource,
  });

  final LibraryLocalDataSource localDataSource;
  final EpubFileDataSource epubFileDataSource;

  @override
  Future<Result<List<Book>>> getBooks() async {
    try {
      final books =
      await localDataSource.getBooks();

      books.sort(
            (a, b) =>
            b.importedAt.compareTo(a.importedAt),
      );

      return Success(
        List<Book>.unmodifiable(books),
      );
    } on Failure catch (failure) {
      return Error(failure);
    } catch (error) {
      return Error(
        StorageFailure(
          'Ошибка загрузки библиотеки: $error',
        ),
      );
    }
  }

  @override
  Future<Result<Book>>
  importBookFromDevice() async {
    try {
      final picked =
      await epubFileDataSource.pickEpubFile();

      if (picked == null) {
        return const Error(
          FileFailure('Выбор файла отменён'),
        );
      }

      final imported =
      await epubFileDataSource.importEpubBytes(
        bytes: picked.bytes,
        originalName: picked.name,
      );

      final books =
      await localDataSource.getBooks();

      final updated = [
        ...books,
        imported,
      ];

      await localDataSource.saveBooks(
        updated,
      );

      return Success(imported);
    } on Failure catch (failure) {
      return Error(failure);
    } catch (error) {
      return Error(
        FileFailure(
          'Не удалось импортировать книгу: $error',
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteBook(
      String bookId,
      ) async {
    try {
      final books =
      await localDataSource.getBooks();

      final index = books.indexWhere(
            (book) => book.id == bookId,
      );

      if (index < 0) {
        return const Error(
          StorageFailure('Книга не найдена'),
        );
      }

      final book = books[index];

      await localDataSource.deleteBookFiles(
        book,
      );

      books.removeAt(index);

      await localDataSource.saveBooks(
        books,
      );

      return const Success(null);
    } on Failure catch (failure) {
      return Error(failure);
    } catch (error) {
      return Error(
        StorageFailure(
          'Не удалось удалить книгу: $error',
        ),
      );
    }
  }

  @override
  Future<Result<void>>
  updateReadingProgress({
    required String bookId,
    required double progress,
    String? lastCfi,
    int? lastPageIndex,
  }) async {
    try {
      final books =
      await localDataSource.getBooks();

      final index = books.indexWhere(
            (book) => book.id == bookId,
      );

      if (index < 0) {
        return const Error(
          StorageFailure('Книга не найдена'),
        );
      }

      final current = books[index];

      final normalizedCfi =
      lastCfi?.trim();

      books[index] = BookModel(
        id: current.id,
        title: current.title,
        author: current.author,
        filePath: current.filePath,
        coverPath: current.coverPath,
        importedAt: current.importedAt,
        readingProgress:
        progress.clamp(0.0, 1.0).toDouble(),
        lastPageIndex:
        lastPageIndex ??
            current.lastPageIndex,
        lastCfi:
        normalizedCfi == null ||
            normalizedCfi.isEmpty
            ? current.lastCfi
            : normalizedCfi,
        isFavorite: current.isFavorite,
      );

      await localDataSource.saveBooks(
        books,
      );

      return const Success(null);
    } on Failure catch (failure) {
      return Error(failure);
    } catch (error) {
      return Error(
        StorageFailure(
          'Не удалось сохранить прогресс: $error',
        ),
      );
    }
  }

  @override
  Future<Result<void>> setFavorite({
    required String bookId,
    required bool isFavorite,
  }) async {
    try {
      final books =
      await localDataSource.getBooks();

      final index = books.indexWhere(
            (book) => book.id == bookId,
      );

      if (index < 0) {
        return const Error(
          StorageFailure('Книга не найдена'),
        );
      }

      final current = books[index];

      books[index] = BookModel(
        id: current.id,
        title: current.title,
        author: current.author,
        filePath: current.filePath,
        coverPath: current.coverPath,
        importedAt: current.importedAt,
        readingProgress:
        current.readingProgress,
        lastPageIndex:
        current.lastPageIndex,
        lastCfi: current.lastCfi,
        isFavorite: isFavorite,
      );

      await localDataSource.saveBooks(
        books,
      );

      return const Success(null);
    } on Failure catch (failure) {
      return Error(failure);
    } catch (error) {
      return Error(
        StorageFailure(
          'Не удалось изменить избранное: $error',
        ),
      );
    }
  }

  @override
  Future<Result<Book>> getBookById(
      String bookId,
      ) async {
    try {
      final books =
      await localDataSource.getBooks();

      for (final book in books) {
        if (book.id == bookId) {
          return Success(book);
        }
      }

      return const Error(
        StorageFailure('Книга не найдена'),
      );
    } on Failure catch (failure) {
      return Error(failure);
    } catch (error) {
      return Error(
        StorageFailure(
          'Ошибка поиска книги: $error',
        ),
      );
    }
  }
}