import 'package:flutter/foundation.dart';

import '../../../library/domain/entities/book.dart';
import '../../../library/domain/usecases/update_reading_progress.dart';
import '../../domain/entities/reader_document.dart';
import '../../domain/usecases/open_book.dart';

enum ReaderStatus {
  initial,
  loading,
  ready,
  error,
}

class ReaderViewModel
    extends ChangeNotifier {
  ReaderViewModel({
    required OpenBook openBook,
    required UpdateReadingProgress
    updateReadingProgress,
  })  : openBookUseCase = openBook,
        updateReadingProgressUseCase =
            updateReadingProgress;

  final OpenBook openBookUseCase;

  final UpdateReadingProgress
  updateReadingProgressUseCase;

  ReaderStatus _status =
      ReaderStatus.initial;

  ReaderDocument? _document;
  String? _errorMessage;

  bool _viewerLoaded = false;

  double _progress = 0;
  String? _currentCfi;

  String? _selectedText;
  String? _selectedCfi;

  bool _savingProgress = false;

  bool _saveRequestedWhileBusy =
  false;

  ReaderStatus get status => _status;

  ReaderDocument? get document =>
      _document;

  String? get errorMessage =>
      _errorMessage;

  bool get viewerLoaded =>
      _viewerLoaded;

  double get progress => _progress;

  String? get currentCfi =>
      _currentCfi;

  String? get selectedText =>
      _selectedText;

  String? get selectedCfi =>
      _selectedCfi;

  int get progressPercent =>
      (_progress * 100)
          .round()
          .clamp(0, 100)
          .toInt();

  Future<void> open(
      Book book,
      ) async {
    _status = ReaderStatus.loading;

    _errorMessage = null;
    _document = null;

    _viewerLoaded = false;

    _selectedText = null;
    _selectedCfi = null;

    _progress = book.readingProgress
        .clamp(0.0, 1.0)
        .toDouble();

    _currentCfi = book.lastCfi;

    notifyListeners();

    final result =
    await openBookUseCase(
      bookId: book.id,
      filePath: book.filePath,
      title: book.title,
      author: book.author,
      initialProgress:
      book.readingProgress,
      initialCfi: book.lastCfi,
    );

    if (result.isSuccess) {
      final document =
      result.valueOrNull!;

      _document = document;

      _progress =
          document.initialProgress;

      _currentCfi =
          document.initialCfi;

      _status = ReaderStatus.ready;
    } else {
      _errorMessage =
          result.failureOrNull?.message ??
              'Не удалось открыть книгу';

      _status = ReaderStatus.error;
    }

    notifyListeners();
  }

  void onViewerLoaded() {
    if (_viewerLoaded) {
      return;
    }

    _viewerLoaded = true;

    notifyListeners();
  }

  void onViewerError(
      String message,
      ) {
    _errorMessage =
    message.trim().isEmpty
        ? 'EPUB-рендерер не смог открыть книгу'
        : 'Не удалось отобразить EPUB: $message';

    _status = ReaderStatus.error;

    _viewerLoaded = false;

    notifyListeners();
  }

  Future<void> onRelocated({
    required double progress,
    required String startCfi,
  }) async {
    final safeProgress =
    progress.isFinite
        ? progress
        .clamp(0.0, 1.0)
        .toDouble()
        : _progress;

    final safeCfi =
    startCfi.trim();

    final progressChanged =
        (safeProgress - _progress)
            .abs() >
            0.0001;

    final cfiChanged =
        safeCfi.isNotEmpty &&
            safeCfi != _currentCfi;

    _progress = safeProgress;

    if (safeCfi.isNotEmpty) {
      _currentCfi = safeCfi;
    }

    if (progressChanged ||
        cfiChanged) {
      notifyListeners();

      await _persistProgress();
    }
  }

  void onTextSelected({
    required String text,
    required String cfi,
  }) {
    final normalizedText =
    text.trim();

    final normalizedCfi =
    cfi.trim();

    _selectedText =
    normalizedText.isEmpty
        ? null
        : normalizedText;

    _selectedCfi =
    normalizedCfi.isEmpty
        ? null
        : normalizedCfi;

    notifyListeners();
  }

  void clearSelection() {
    if (_selectedText == null &&
        _selectedCfi == null) {
      return;
    }

    _selectedText = null;
    _selectedCfi = null;

    notifyListeners();
  }

  Future<void>
  _persistProgress() async {
    final document = _document;

    if (document == null) {
      return;
    }

    if (_savingProgress) {
      _saveRequestedWhileBusy =
      true;

      return;
    }

    do {
      _saveRequestedWhileBusy =
      false;

      _savingProgress = true;

      await updateReadingProgressUseCase(
        bookId: document.bookId,
        progress: _progress,
        lastCfi: _currentCfi,
      );

      _savingProgress = false;
    } while (
    _saveRequestedWhileBusy);
  }

  Future<void>
  saveProgressOnExit() =>
      _persistProgress();
}