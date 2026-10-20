import '../../domain/entities/book.dart';

class BookModel extends Book {
  const BookModel({
    required super.id,
    required super.title,
    required super.filePath,
    required super.importedAt,
    super.author,
    super.coverPath,
    super.readingProgress,
    super.lastPageIndex,
  });

  factory BookModel.fromEntity(Book book) {
    return BookModel(
      id: book.id,
      title: book.title,
      author: book.author,
      filePath: book.filePath,
      coverPath: book.coverPath,
      importedAt: book.importedAt,
      readingProgress: book.readingProgress,
      lastPageIndex: book.lastPageIndex,
    );
  }

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      filePath: json['filePath'] as String,
      coverPath: json['coverPath'] as String?,
      importedAt: DateTime.parse(json['importedAt'] as String),
      readingProgress: (json['readingProgress'] as num?)?.toDouble() ?? 0,
      lastPageIndex: json['lastPageIndex'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'filePath': filePath,
      'coverPath': coverPath,
      'importedAt': importedAt.toIso8601String(),
      'readingProgress': readingProgress,
      'lastPageIndex': lastPageIndex,
    };
  }
}
