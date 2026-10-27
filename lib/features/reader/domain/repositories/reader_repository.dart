import '../../../../core/utils/result.dart';
import '../entities/reader_document.dart';

abstract class ReaderRepository {
  Future<Result<ReaderDocument>> openBook({
    required String bookId,
    required String filePath,
    required String title,
    String? author,
    double initialProgress = 0,
    String? initialCfi,
  });
}