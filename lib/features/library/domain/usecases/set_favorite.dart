import '../../../../core/utils/result.dart';
import '../repositories/library_repository.dart';

class SetFavorite {
  const SetFavorite(this._repository);

  final LibraryRepository _repository;

  Future<Result<void>> call({
    required String bookId,
    required bool isFavorite,
  }) {
    return _repository.setFavorite(
      bookId: bookId,
      isFavorite: isFavorite,
    );
  }
}