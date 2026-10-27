import '../../../../core/utils/result.dart';
import '../repositories/library_repository.dart';

class UpdateReadingProgress {
  const UpdateReadingProgress(
      this._repository,
      );

  final LibraryRepository _repository;

  Future<Result<void>> call({
    required String bookId,
    required double progress,
    String? lastCfi,
    int? lastPageIndex,
  }) {
    return _repository.updateReadingProgress(
      bookId: bookId,
      progress: progress,
      lastCfi: lastCfi,
      lastPageIndex: lastPageIndex,
    );
  }
}