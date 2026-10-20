import 'package:flutter/foundation.dart';

import '../../domain/entities/book.dart';
import '../../domain/usecases/delete_book.dart';
import '../../domain/usecases/get_books.dart';
import '../../domain/usecases/import_book.dart';

enum LibraryStatus { initial, loading, ready, importing, error }

class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel({
    required GetBooks getBooks,
    required ImportBook importBook,
    required DeleteBook deleteBook,
  })  : getBooksUseCase = getBooks,
        importBookUseCase = importBook,
        deleteBookUseCase = deleteBook;

  final GetBooks getBooksUseCase;
  final ImportBook importBookUseCase;
  final DeleteBook deleteBookUseCase;

  LibraryStatus _status = LibraryStatus.initial;
  List<Book> _books = const [];
  String? _errorMessage;

  LibraryStatus get status => _status;
  List<Book> get books => _books;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _books.isEmpty;
  bool get isBusy =>
      _status == LibraryStatus.loading || _status == LibraryStatus.importing;

  Future<void> loadBooks() async {
    _status = LibraryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await getBooksUseCase();
    if (result.isSuccess) {
      _books = result.valueOrNull ?? const [];
      _status = LibraryStatus.ready;
    } else {
      _errorMessage = result.failureOrNull?.message ?? 'Неизвестная ошибка';
      _status = LibraryStatus.error;
    }
    notifyListeners();
  }

  Future<Book?> importBook() async {
    _status = LibraryStatus.importing;
    _errorMessage = null;
    notifyListeners();

    final result = await importBookUseCase();
    if (result.isSuccess) {
      final book = result.valueOrNull!;
      _books = [book, ..._books.where((item) => item.id != book.id)];
      _status = LibraryStatus.ready;
      notifyListeners();
      return book;
    }

    final message = result.failureOrNull?.message ?? 'Не удалось импортировать';
    final cancelled = message.contains('отменён');
    if (!cancelled) {
      _errorMessage = message;
      _status = LibraryStatus.error;
    } else {
      _status = LibraryStatus.ready;
    }
    notifyListeners();
    return null;
  }

  Future<bool> deleteBook(String bookId) async {
    final result = await deleteBookUseCase(bookId);
    if (result.isSuccess) {
      _books = _books.where((book) => book.id != bookId).toList();
      notifyListeners();
      return true;
    }

    _errorMessage = result.failureOrNull?.message ?? 'Не удалось удалить книгу';
    notifyListeners();
    return false;
  }

  void clearError() {
    _errorMessage = null;
    if (_status == LibraryStatus.error) {
      _status = LibraryStatus.ready;
    }
    notifyListeners();
  }
}
