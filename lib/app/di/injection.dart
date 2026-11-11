import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';

import '../../features/ai_analysis/data/datasources/ai_analysis_remote_datasource.dart';
import '../../features/ai_analysis/data/repositories/ai_analysis_repository_impl.dart';
import '../../features/ai_analysis/domain/repositories/ai_analysis_repository.dart';
import '../../features/ai_analysis/domain/usecases/analyze_text.dart';
import '../../features/ai_analysis/presentation/viewmodels/ai_analysis_view_model.dart';

import '../../features/library/data/datasources/epub_file_datasource.dart';
import '../../features/library/data/datasources/library_local_datasource.dart';
import '../../features/library/data/repositories/library_repository_impl.dart';
import '../../features/library/domain/repositories/library_repository.dart';
import '../../features/library/domain/usecases/delete_book.dart';
import '../../features/library/domain/usecases/get_books.dart';
import '../../features/library/domain/usecases/import_book.dart';
import '../../features/library/domain/usecases/set_favorite.dart';
import '../../features/library/domain/usecases/update_reading_progress.dart';
import '../../features/library/presentation/viewmodels/library_view_model.dart';

import '../../features/reader/data/datasources/epub_reader_datasource.dart';
import '../../features/reader/data/repositories/reader_repository_impl.dart';
import '../../features/reader/domain/repositories/reader_repository.dart';
import '../../features/reader/domain/usecases/open_book.dart';
import '../../features/reader/presentation/viewmodels/reader_view_model.dart';

class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance =
  ServiceLocator._();

  late final SharedPreferences preferences;

  late final Dio dio;

  late final LibraryLocalDataSource
  libraryLocalDataSource;

  late final EpubFileDataSource
  epubFileDataSource;

  late final LibraryRepository
  libraryRepository;

  late final EpubReaderDataSource
  epubReaderDataSource;

  late final ReaderRepository
  readerRepository;

  late final AiAnalysisRemoteDataSource
  aiAnalysisRemoteDataSource;

  late final AiAnalysisRepository
  aiAnalysisRepository;

  late final GetBooks getBooks;

  late final ImportBook importBook;

  late final DeleteBook deleteBook;

  late final SetFavorite setFavorite;

  late final UpdateReadingProgress
  updateReadingProgress;

  late final OpenBook openBook;

  late final AnalyzeText analyzeText;

  bool _initialized = false;

  Future<void> init({
    bool force = false,
  }) async {
    if (_initialized && !force) {
      return;
    }

    preferences =
    await SharedPreferences
        .getInstance();

    dio = ApiClient.create();

    libraryLocalDataSource =
        LibraryLocalDataSourceImpl(
          preferences,
        );

    epubFileDataSource =
        EpubFileDataSourceImpl(
          localDataSource:
          libraryLocalDataSource,
        );

    libraryRepository =
        LibraryRepositoryImpl(
          localDataSource:
          libraryLocalDataSource,
          epubFileDataSource:
          epubFileDataSource,
        );

    epubReaderDataSource =
        EpubReaderDataSourceImpl();

    readerRepository =
        ReaderRepositoryImpl(
          epubReaderDataSource,
        );

    aiAnalysisRemoteDataSource =
        AiAnalysisRemoteDataSourceImpl(
          dio,
        );

    aiAnalysisRepository =
        AiAnalysisRepositoryImpl(
          aiAnalysisRemoteDataSource,
        );

    getBooks =
        GetBooks(
          libraryRepository,
        );

    importBook =
        ImportBook(
          libraryRepository,
        );

    deleteBook =
        DeleteBook(
          libraryRepository,
        );

    setFavorite =
        SetFavorite(
          libraryRepository,
        );

    updateReadingProgress =
        UpdateReadingProgress(
          libraryRepository,
        );

    openBook =
        OpenBook(
          readerRepository,
        );

    analyzeText =
        AnalyzeText(
          aiAnalysisRepository,
        );

    _initialized = true;
  }

  LibraryViewModel
  createLibraryViewModel() {
    return LibraryViewModel(
      getBooks: getBooks,
      importBook: importBook,
      deleteBook: deleteBook,
      setFavorite: setFavorite,
    );
  }

  ReaderViewModel
  createReaderViewModel() {
    return ReaderViewModel(
      openBook: openBook,
      updateReadingProgress:
      updateReadingProgress,
    );
  }

  AiAnalysisViewModel
  createAiAnalysisViewModel() {
    return AiAnalysisViewModel(
      analyzeText: analyzeText,
    );
  }
}

final sl =
    ServiceLocator.instance;