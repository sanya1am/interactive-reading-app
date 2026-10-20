import '../../../../core/utils/result.dart';
import '../entities/reader_page.dart';

abstract class ReaderRepository {
  Future<Result<ReaderDocument>> openBook({
    required String bookId,
    required String filePath,
    required String title,
    String? author,
    int initialPageIndex = 0,
  });
}
