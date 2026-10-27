class ReaderDocument {
  const ReaderDocument({
    required this.bookId,
    required this.title,
    required this.filePath,
    this.author,
    this.initialProgress = 0,
    this.initialCfi,
  });

  final String bookId;
  final String title;
  final String? author;
  final String filePath;

  final double initialProgress;

  final String? initialCfi;
}