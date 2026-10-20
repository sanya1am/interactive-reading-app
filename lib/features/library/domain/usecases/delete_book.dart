import '../../../../core/utils/result.dart';
import '../repositories/library_repository.dart';

class DeleteBook {
  const DeleteBook(this._repository);

  final LibraryRepository _repository;

  Future<Result<void>> call(String bookId) => _repository.deleteBook(bookId);
}
