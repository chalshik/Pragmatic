// models/word_entry.dart
class WordEntry {
  final String word;
  final String phonetic;
  final List<Phonetic> phonetics;
  final List<Meaning> meanings;

  WordEntry({
    required this.word,
    required this.phonetic,
    required this.phonetics,
    required this.meanings,
  });

  factory WordEntry.fromJson(Map<String, dynamic> json) {
    return WordEntry(
      word: json['word'] ?? '',
      phonetic: json['phonetic'] ?? '',
      phonetics: (json['phonetics'] as List<dynamic>?)
              ?.map((e) => Phonetic.fromJson(e))
              .toList() ??
          [],
      meanings: (json['meanings'] as List<dynamic>)
          .map((e) => Meaning.fromJson(e))
          .toList(),
    );
  }
}

class Phonetic {
  final String? text;
  final String? audio;

  Phonetic({this.text, this.audio});

  factory Phonetic.fromJson(Map<String, dynamic> json) {
    return Phonetic(
      text: json['text'],
      audio: json['audio'],
    );
  }
}

class Meaning {
  final String partOfSpeech;
  final List<Definition> definitions;

  Meaning({
    required this.partOfSpeech,
    required this.definitions,
  });

  factory Meaning.fromJson(Map<String, dynamic> json) {
    return Meaning(
      partOfSpeech: json['partOfSpeech'] ?? '',
      definitions: (json['definitions'] as List<dynamic>)
          .map((e) => Definition.fromJson(e))
          .toList(),
    );
  }
}

class Definition {
  final String definition;
  final String? example;

  Definition({
    required this.definition,
    this.example,
  });

  factory Definition.fromJson(Map<String, dynamic> json) {
    return Definition(
      definition: json['definition'],
      example: json['example'],
    );
  }
}