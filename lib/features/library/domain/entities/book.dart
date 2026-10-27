class Book {
  const Book({
    required this.id,
    required this.title,
    required this.filePath,
    required this.importedAt,
    this.author,
    this.coverPath,
    this.readingProgress = 0,
    this.lastPageIndex = 0,
    this.lastCfi,
    this.isFavorite = false,
  });

  final String id;
  final String title;
  final String? author;
  final String filePath;
  final String? coverPath;
  final DateTime importedAt;

  final double readingProgress;

  final int lastPageIndex;

  final String? lastCfi;

  final bool isFavorite;

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    String? coverPath,
    DateTime? importedAt,
    double? readingProgress,
    int? lastPageIndex,
    String? lastCfi,
    bool? isFavorite,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      coverPath: coverPath ?? this.coverPath,
      importedAt: importedAt ?? this.importedAt,
      readingProgress:
      readingProgress ?? this.readingProgress,
      lastPageIndex:
      lastPageIndex ?? this.lastPageIndex,
      lastCfi: lastCfi ?? this.lastCfi,
      isFavorite:
      isFavorite ?? this.isFavorite,
    );
  }
}