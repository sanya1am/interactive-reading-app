import '../../domain/entities/text_analysis.dart';

class TextAnalysisResponseModel extends TextAnalysis {
  const TextAnalysisResponseModel({
    required super.translation,
    required super.explanation,
  });

  factory TextAnalysisResponseModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final translation = json['translation'];
    final explanation = json['explanation'];

    if (translation is! String ||
        explanation is! String) {
      throw const FormatException(
        'Ответ сервера не содержит translation/explanation',
      );
    }

    return TextAnalysisResponseModel(
      translation: translation.trim(),
      explanation: explanation.trim(),
    );
  }
}