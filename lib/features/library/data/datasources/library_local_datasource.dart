import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/failures.dart';
import '../models/book_model.dart';

abstract class LibraryLocalDataSource {
  Future<List<BookModel>> getBooks();

  Future<void> saveBooks(List<BookModel> books);

  Future<Directory> getBooksDirectory();

  Future<void> deleteBookFiles(BookModel book);
}

class LibraryLocalDataSourceImpl implements LibraryLocalDataSource {
  LibraryLocalDataSourceImpl(this._preferences);

  static const _booksKey = 'library_books';

  final SharedPreferences _preferences;

  @override
  Future<List<BookModel>> getBooks() async {
    final raw = _preferences.getString(_booksKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => BookModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const StorageFailure('Не удалось прочитать библиотеку книг');
    }
  }

  @override
  Future<void> saveBooks(List<BookModel> books) async {
    try {
      final payload = books.map((book) => book.toJson()).toList();
      final saved = await _preferences.setString(_booksKey, jsonEncode(payload));
      if (!saved) {
        throw const StorageFailure('Не удалось сохранить библиотеку книг');
      }
    } catch (error) {
      if (error is StorageFailure) rethrow;
      throw StorageFailure('Не удалось сохранить библиотеку: $error');
    }
  }

  @override
  Future<Directory> getBooksDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final booksDir = Directory(p.join(documents.path, 'books'));
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    return booksDir;
  }

  @override
  Future<void> deleteBookFiles(BookModel book) async {
    final file = File(book.filePath);
    if (await file.exists()) {
      await file.delete();
    }

    if (book.coverPath != null) {
      final cover = File(book.coverPath!);
      if (await cover.exists()) {
        await cover.delete();
      }
    }
  }
}
