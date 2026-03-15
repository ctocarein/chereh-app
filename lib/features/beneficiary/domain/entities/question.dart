import 'dart:convert';

enum QuestionType {
  info,
  boolean,
  selectOne,
  selectMultiple,
  radio,
  checkbox,
  slider,
  scale,
  date,
  time,
  rating,
  file,
  image,
  audio,
  video,
  location,
  text,
  number,
  custom,
  valide;

  static QuestionType fromString(String s) => switch (s) {
        'boolean' => QuestionType.boolean,
        // select
        'select_one' => QuestionType.selectOne,
        'select_multiple' => QuestionType.selectMultiple,
        'radio' => QuestionType.radio,
        'checkbox' => QuestionType.checkbox,
        // numeric input types
        'slider' => QuestionType.slider,
        'scale' => QuestionType.scale,
        'rating' => QuestionType.rating,
        // date/time
        'date' => QuestionType.date,
        'time' => QuestionType.time,
        // text
        'text' || 'textarea' => QuestionType.text,
        'number' || 'integer' => QuestionType.number,
        // media
        'file' => QuestionType.file,
        'image' => QuestionType.image,
        'audio' => QuestionType.audio,
        'video' => QuestionType.video,
        // geo
        'location' || 'map' => QuestionType.location,
        // meta
        'custom' => QuestionType.custom,
        'valide' => QuestionType.valide,
        // info, hidden, dynamic → acquittement
        _ => QuestionType.info,
      };
}

class Question {
  final String id;
  final QuestionType type;
  final String text;

  /// Labels affichés dans l'UI (chips, listes…).
  final List<String>? options;

  /// Valeurs soumises à l'API. Si null, [options] fait office de valeurs.
  final List<String>? optionValues;

  final double? min;
  final double? max;
  final double? step;
  final bool? required;
  final int? stepIndex;
  final int? totalSteps;

  const Question({
    required this.id,
    required this.type,
    required this.text,
    this.options,
    this.optionValues,
    this.min,
    this.max,
    this.step,
    this.required,
    this.stepIndex,
    this.totalSteps,
  });

  /// Valeur à envoyer à l'API pour le label [label].
  /// Renvoie [label] si aucune table de correspondance n'est disponible.
  String valueForLabel(String label) {
    if (optionValues == null || options == null) return label;
    final i = options!.indexOf(label);
    if (i < 0 || i >= optionValues!.length) return label;
    return optionValues![i];
  }

  /// Label à afficher pour la valeur [value] reçue ou soumise.
  String labelForValue(String value) {
    if (optionValues == null || options == null) return value;
    final i = optionValues!.indexOf(value);
    if (i < 0 || i >= options!.length) return value;
    return options![i];
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final list = _toList(rawOptions);
    return Question(
      id: json['id'].toString(),
      type: QuestionType.fromString(json['type'] as String? ?? 'info'),
      text: json['text'] as String? ?? '',
      options: list != null ? _extractLabels(list) : null,
      optionValues: list != null ? _extractValues(list) : null,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      step: (json['step'] as num?)?.toDouble(),
      required: json['required'] as bool?,
      stepIndex: json['step_index'] as int?,
      totalSteps: json['total_steps'] as int?,
    );
  }

  static List? _toList(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) return raw;
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return null;
  }

  /// Extrait les labels (champ "label" si objet, sinon la valeur brute).
  static List<String> _extractLabels(List list) =>
      list.map((e) {
        if (e is Map) {
          return (e['label'] ?? e['value'] ?? '').toString();
        }
        return e.toString();
      }).toList();

  /// Extrait les valeurs à soumettre (champ "value" si objet, sinon le label).
  static List<String> _extractValues(List list) =>
      list.map((e) {
        if (e is Map) {
          return (e['value'] ?? e['label'] ?? '').toString();
        }
        return e.toString();
      }).toList();

  Map<String, dynamic> toJson() {
    // Persiste les options comme objets {value, label} si les deux existent.
    List<dynamic>? serializedOptions;
    if (options != null) {
      if (optionValues != null && optionValues!.length == options!.length) {
        serializedOptions = List.generate(options!.length, (i) => {
              'value': optionValues![i],
              'label': options![i],
            });
      } else {
        serializedOptions = options;
      }
    }

    return {
      'id': id,
      'type': type.name,
      'text': text,
      'options': ?serializedOptions,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (step != null) 'step': step,
      if (required != null) 'required': required,
      if (stepIndex != null) 'step_index': stepIndex,
      if (totalSteps != null) 'total_steps': totalSteps,
    };
  }

  /// Vrai si le type est une simple validation (pas de saisie).
  bool get isAcknowledgement =>
      type == QuestionType.info ||
      type == QuestionType.custom ||
      type == QuestionType.valide;
}
