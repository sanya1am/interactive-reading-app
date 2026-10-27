import 'dart:io';

import '../../../../core/error/failures.dart';

abstract class EpubReaderDataSource {
  Future<void> validateBookFile(String filePath);
}

class EpubReaderDataSourceImpl implements EpubReaderDataSource {
  @override
  Future<void> validateBookFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw const FileFailure('EPUB-файл книги не найден');
      }

      final length = await file.length();
      if (length == 0) {
        throw const FileFailure('EPUB-файл книги пуст');
      }
    } on FileFailure {
      rethrow;
    } on FileSystemException catch (error) {
      throw FileFailure(
        'Не удалось прочитать EPUB-файл: ${error.message}',
      );
    } catch (error) {
      throw FileFailure(
        'Не удалось проверить EPUB-файл: $error',
      );
    }
  }
}