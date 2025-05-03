class TranslationRequest {
  final String word;
  final String destLang;
  final String? context;

  TranslationRequest({
    required this.word,
    required this.destLang,
    this.context,
  });

  Map<String, dynamic> toJson() => {
    'word': word,
    'dest_lang': destLang,
    if (context != null) 'context': context,
  };
}