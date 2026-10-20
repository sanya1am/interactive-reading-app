import '../../domain/entities/reader_page.dart';

class EpubLoadResult {
  const EpubLoadResult({
    required this.pages,
    required this.locationIndex,
  });

  final List<ReaderPage> pages;
  final Map<String, int> locationIndex;
}
