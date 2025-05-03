class DeepLTranslation {
  final String detectedSourceLanguage;
  final String text;

  DeepLTranslation({
    required this.detectedSourceLanguage,
    required this.text,
  });

  factory DeepLTranslation.fromJson(Map<String, dynamic> json) => DeepLTranslation(
    detectedSourceLanguage: json['detected_source_language'],
    text: json['text'],
  );

  Map<String, dynamic> toJson() => {
    'detected_source_language': detectedSourceLanguage,
    'text': text,
  };
}

class TranslationResponse {
  final String text;
  final String detLang;
  final List<DeepLTranslation> translations;

  TranslationResponse({
    required this.text,
    required this.detLang,
    required this.translations,
  });

  factory TranslationResponse.fromJson(Map<String, dynamic> json) => TranslationResponse(
    text: json['text'],
    detLang: json['det_lang'],
    translations: (json['translations'] as List)
        .map((t) => DeepLTranslation.fromJson(t))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'text': text,
    'det_lang': detLang,
    'translations': translations.map((t) => t.toJson()).toList(),
  };
}