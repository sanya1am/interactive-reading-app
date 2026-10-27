import '../../../../core/utils/result.dart';
import '../entities/reader_document.dart';
import '../repositories/reader_repository.dart';

class OpenBook {
  const OpenBook(this._repository);

  final ReaderRepository _repository;

  Future<Result<ReaderDocument>> call({
    required String bookId,
    required String filePath,
    required String title,
    String? author,
    double initialProgress = 0,
    String? initialCfi,
  }) {
    return _repository.openBook(
      bookId: bookId,
      filePath: filePath,
      title: title,
      author: author,
      initialProgress: initialProgress,
      initialCfi: initialCfi,
    );
  }
}