import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../models/text_analysis_request_model.dart';
import '../models/text_analysis_response_model.dart';

abstract class AiAnalysisRemoteDataSource {
  Future<TextAnalysisResponseModel> analyzeText(
      TextAnalysisRequestModel request,
      );
}

class AiAnalysisRemoteDataSourceImpl
    implements AiAnalysisRemoteDataSource {
  AiAnalysisRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<TextAnalysisResponseModel> analyzeText(
      TextAnalysisRequestModel request,
      ) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/analyses',
        data: request.toJson(),
      );

      final data = response.data;

      if (data is! Map) {
        throw const ParsingFailure(
          'Сервер вернул ответ в неизвестном формате',
        );
      }

      return TextAnalysisResponseModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on ParsingFailure {
      rethrow;
    } on FormatException catch (error) {
      throw ParsingFailure(
        error.message.toString(),
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    } catch (error) {
      throw NetworkFailure(
        'Не удалось выполнить анализ текста: $error',
      );
    }
  }

  Failure _mapDioException(
      DioException error,
      ) {
    final statusCode =
        error.response?.statusCode;

    final retryAfterSeconds =
    _parseRetryAfter(
      error.response?.headers,
    );

    final serverDetail =
    _extractServerDetail(
      error.response?.data,
    );

    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          return ApiFailure(
            serverDetail ??
                'Некорректные данные запроса',
            statusCode: statusCode,
          );

        case 415:
          return ApiFailure(
            serverDetail ??
                'Сервер ожидает тело запроса в формате JSON',
            statusCode: statusCode,
          );

        case 429:
          return ApiFailure(
            serverDetail ??
                'Превышен лимит запросов',
            statusCode: statusCode,
            retryAfterSeconds:
            retryAfterSeconds,
          );

        case 500:
          return ApiFailure(
            serverDetail ??
                'Внутренняя ошибка сервера',
            statusCode: statusCode,
          );

        case 502:
          return ApiFailure(
            serverDetail ??
                'Модель вернула некорректный ответ',
            statusCode: statusCode,
          );

        case 503:
          return ApiFailure(
            serverDetail ??
                'LLM-провайдер временно недоступен',
            statusCode: statusCode,
          );

        default:
          return ApiFailure(
            serverDetail ??
                'Ошибка сервера ($statusCode)',
            statusCode: statusCode,
          );
      }
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout =>
      const NetworkFailure(
        'Не удалось подключиться к серверу',
      ),

      DioExceptionType.sendTimeout =>
      const NetworkFailure(
        'Превышено время отправки запроса',
      ),

      DioExceptionType.receiveTimeout =>
      const NetworkFailure(
        'Сервер слишком долго формирует ответ',
      ),

      DioExceptionType.connectionError =>
      const NetworkFailure(
        'Нет соединения с сервером',
      ),

      DioExceptionType.cancel =>
      const NetworkFailure(
        'Запрос был отменён',
      ),

      _ => NetworkFailure(
        error.message ?? 'Ошибка сети',
      ),
    };
  }

  String? _extractServerDetail(
      dynamic data,
      ) {
    if (data is! Map) {
      return null;
    }

    final detail = data['detail'];

    if (detail is String &&
        detail.trim().isNotEmpty) {
      return detail.trim();
    }

    final title = data['title'];

    if (title is String &&
        title.trim().isNotEmpty) {
      return title.trim();
    }

    return null;
  }

  int? _parseRetryAfter(
      Headers? headers,
      ) {
    final value =
    headers?.value('retry-after');

    if (value == null) {
      return null;
    }

    return int.tryParse(value);
  }
}