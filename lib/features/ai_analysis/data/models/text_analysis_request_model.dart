class TextAnalysisRequestModel {
  const TextAnalysisRequestModel({
    required this.selectedText,
    required this.context,
    this.book = '',
    this.author = '',
    this.edition = '',
  });

  final String book;
  final String author;
  final String edition;
  final String selectedText;
  final String context;

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'author': author,
      'edition': edition,
      'selectedText': selectedText,
      'context': context,
    };
  }
}