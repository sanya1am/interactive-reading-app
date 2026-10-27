import 'package:flutter/foundation.dart';

import '../../domain/entities/book.dart';
import '../../domain/usecases/delete_book.dart';
import '../../domain/usecases/get_books.dart';
import '../../domain/usecases/import_book.dart';
import '../../domain/usecases/set_favorite.dart';

enum LibraryStatus {
  initial,
  loading,
  ready,
  importing,
  error,
}

enum LibraryFilter {
  all,
  favorites,
  reading,
}

class LibraryViewModel
    extends ChangeNotifier {
  LibraryViewModel({
    required GetBooks getBooks,
    required ImportBook importBook,
    required DeleteBook deleteBook,
    required SetFavorite setFavorite,
  })  : getBooksUseCase = getBooks,
        importBookUseCase = importBook,
        deleteBookUseCase = deleteBook,
        setFavoriteUseCase = setFavorite;

  final GetBooks getBooksUseCase;
  final ImportBook importBookUseCase;
  final DeleteBook deleteBookUseCase;
  final SetFavorite setFavoriteUseCase;

  LibraryStatus _status =
      LibraryStatus.initial;

  LibraryFilter _filter =
      LibraryFilter.all;

  List<Book> _books = const [];

  String? _errorMessage;

  LibraryStatus get status => _status;

  LibraryFilter get filter => _filter;

  List<Book> get books => _books;

  String? get errorMessage =>
      _errorMessage;

  bool get isEmpty => _books.isEmpty;

  bool get isBusy =>
      _status == LibraryStatus.loading ||
          _status == LibraryStatus.importing;

  List<Book> get readingBooks => _books
      .where(
        (book) =>
    book.readingProgress > 0 &&
        book.readingProgress < 0.999,
  )
      .toList(growable: false);

  List<Book> get continueReadingBooks =>
      readingBooks
          .take(6)
          .toList(growable: false);

  List<Book> get filteredBooks {
    return switch (_filter) {
      LibraryFilter.all => _books,

      LibraryFilter.favorites =>
          _books
              .where(
                (book) => book.isFavorite,
          )
              .toList(growable: false),

      LibraryFilter.reading =>
      readingBooks,
    };
  }

  int get favoriteCount => _books
      .where(
        (book) => book.isFavorite,
  )
      .length;

  double get averageReadingProgress {
    if (readingBooks.isEmpty) {
      return 0;
    }

    final total =
    readingBooks.fold<double>(
      0,
          (
          sum,
          book,
          ) =>
      sum + book.readingProgress,
    );

    return total /
        readingBooks.length;
  }

  Future<void> loadBooks() async {
    _status =
        LibraryStatus.loading;

    _errorMessage = null;

    notifyListeners();

    final result =
    await getBooksUseCase();

    if (result.isSuccess) {
      _books =
          result.valueOrNull ??
              const [];

      _status =
          LibraryStatus.ready;
    } else {
      _errorMessage =
          result.failureOrNull?.message ??
              'Неизвестная ошибка';

      _status =
          LibraryStatus.error;
    }

    notifyListeners();
  }

  Future<Book?> importBook() async {
    _status =
        LibraryStatus.importing;

    _errorMessage = null;

    notifyListeners();

    final result =
    await importBookUseCase();

    if (result.isSuccess) {
      final book =
      result.valueOrNull!;

      _books = [
        book,
        ..._books.where(
              (item) =>
          item.id != book.id,
        ),
      ];

      _status =
          LibraryStatus.ready;

      notifyListeners();

      return book;
    }

    final message =
        result.failureOrNull?.message ??
            'Не удалось импортировать';

    final cancelled =
    message.contains('отменён');

    if (!cancelled) {
      _errorMessage = message;
      _status =
          LibraryStatus.error;
    } else {
      _status =
          LibraryStatus.ready;
    }

    notifyListeners();

    return null;
  }

  Future<bool> deleteBook(
      String bookId,
      ) async {
    final result =
    await deleteBookUseCase(
      bookId,
    );

    if (result.isSuccess) {
      _books = _books
          .where(
            (book) =>
        book.id != bookId,
      )
          .toList();

      notifyListeners();

      return true;
    }

    _errorMessage =
        result.failureOrNull?.message ??
            'Не удалось удалить книгу';

    notifyListeners();

    return false;
  }

  Future<void> toggleFavorite(
      Book book,
      ) async {
    final newValue =
    !book.isFavorite;

    _books = _books
        .map(
          (item) =>
      item.id == book.id
          ? item.copyWith(
        isFavorite:
        newValue,
      )
          : item,
    )
        .toList(
      growable: false,
    );

    notifyListeners();

    final result =
    await setFavoriteUseCase(
      bookId: book.id,
      isFavorite: newValue,
    );

    if (!result.isSuccess) {
      _books = _books
          .map(
            (item) =>
        item.id == book.id
            ? item.copyWith(
          isFavorite:
          book.isFavorite,
        )
            : item,
      )
          .toList(
        growable: false,
      );

      _errorMessage =
          result.failureOrNull
              ?.message ??
              'Не удалось изменить избранное';

      notifyListeners();
    }
  }

  void setFilter(
      LibraryFilter filter,
      ) {
    if (_filter == filter) {
      return;
    }

    _filter = filter;

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;

    if (_status ==
        LibraryStatus.error) {
      _status =
          LibraryStatus.ready;
    }

    notifyListeners();
  }
}