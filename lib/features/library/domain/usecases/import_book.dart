import '../../../../core/utils/result.dart';
import '../entities/book.dart';
import '../repositories/library_repository.dart';

class ImportBook {
  const ImportBook(this._repository);

  final LibraryRepository _repository;

  Future<Result<Book>> call() => _repository.importBookFromDevice();
}
