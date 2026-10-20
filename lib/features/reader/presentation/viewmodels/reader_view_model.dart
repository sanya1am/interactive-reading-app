import 'package:flutter/foundation.dart';

import '../../../library/domain/entities/book.dart';
import '../../../library/domain/usecases/update_reading_progress.dart';
import '../../domain/entities/reader_page.dart';
import '../../domain/usecases/open_book.dart';

enum ReaderStatus { initial, loading, ready, error }

class ReaderViewModel extends ChangeNotifier {
  ReaderViewModel({
    required OpenBook openBook,
    required UpdateReadingProgress updateReadingProgress,
  })  : openBookUseCase = openBook,
        updateReadingProgressUseCase = updateReadingProgress;

  final OpenBook openBookUseCase;
  final UpdateReadingProgress updateReadingProgressUseCase;

  ReaderStatus _status = ReaderStatus.initial;
  ReaderDocument? _document;
  int _currentPageIndex = 0;
  String? _errorMessage;
  bool _savingProgress = false;

  ReaderStatus get status => _status;
  ReaderDocument? get document => _document;
  int get currentPageIndex => _currentPageIndex;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ReaderStatus.loading;

  ReaderPage? get currentPage {
    final doc = _document;
    if (doc == null || doc.pages.isEmpty) return null;
    return doc.pages[_currentPageIndex.clamp(0, doc.pages.length - 1)];
  }

  double get progress {
    final doc = _document;
    if (doc == null || doc.totalPages == 0) return 0;
    return (_currentPageIndex + 1) / doc.totalPages;
  }

  String get pageLabel {
    final doc = _document;
    if (doc == null || doc.totalPages == 0) return '0 / 0';
    return '${_currentPageIndex + 1} / ${doc.totalPages}';
  }

  Future<void> open(Book book) async {
    _status = ReaderStatus.loading;
    _errorMessage = null;
    _document = null;
    notifyListeners();

    final result = await openBookUseCase(
      bookId: book.id,
      filePath: book.filePath,
      title: book.title,
      author: book.author,
      initialPageIndex: book.lastPageIndex,
    );

    if (result.isSuccess) {
      final document = result.valueOrNull!;
      _document = document;
      _currentPageIndex = document.initialPageIndex;
      _status = ReaderStatus.ready;
    } else {
      _errorMessage = result.failureOrNull?.message ?? 'Не удалось открыть книгу';
      _status = ReaderStatus.error;
    }
    notifyListeners();
  }

  Future<void> goToPage(int index) async {
    final doc = _document;
    if (doc == null || doc.pages.isEmpty) return;

    final next = index.clamp(0, doc.pages.length - 1);
    if (next == _currentPageIndex) return;

    _currentPageIndex = next;
    notifyListeners();
    await _persistProgress();
  }

  Future<void> nextPage() => goToPage(_currentPageIndex + 1);

  Future<void> previousPage() => goToPage(_currentPageIndex - 1);

  /// Resolves an internal EPUB href (TOC / cross-reference) to a page index.
  int? resolveInternalLink(String href) {
    final doc = _document;
    if (doc == null) return null;
    return doc.resolveHref(
      href,
      fromFile: currentPage?.contentFileName,
    );
  }

  Future<bool> openInternalLink(String href) async {
    final pageIndex = resolveInternalLink(href);
    if (pageIndex == null) return false;
    await goToPage(pageIndex);
    return true;
  }

  Future<void> _persistProgress() async {
    final doc = _document;
    if (doc == null || _savingProgress) return;

    _savingProgress = true;
    await updateReadingProgressUseCase(
      bookId: doc.bookId,
      progress: progress,
      lastPageIndex: _currentPageIndex,
    );
    _savingProgress = false;
  }

  Future<void> saveProgressOnExit() => _persistProgress();
}
