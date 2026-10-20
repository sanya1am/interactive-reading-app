import '../../../../core/utils/result.dart';
import '../entities/book.dart';
import '../repositories/library_repository.dart';

class GetBooks {
  const GetBooks(this._repository);

  final LibraryRepository _repository;

  Future<Result<List<Book>>> call() => _repository.getBooks();
}
