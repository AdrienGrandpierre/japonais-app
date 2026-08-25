class VerbFormExample {
  final String japanese;
  final String romanji;
  final String french;

  const VerbFormExample({
    required this.japanese,
    required this.romanji,
    required this.french,
  });

  factory VerbFormExample.fromJson(Map<String, dynamic> json) {
    return VerbFormExample(
      japanese: json['japanese'] as String,
      romanji: json['romanji'] as String,
      french: json['french'] as String,
    );
  }
}

class VerbForm {
  final String key;
  final String japanese;
  final String romanji;
  final String french;
  final String register;
  final VerbFormExample example;

  const VerbForm({
    required this.key,
    required this.japanese,
    required this.romanji,
    required this.french,
    required this.register,
    required this.example,
  });

  factory VerbForm.fromJson(String key, Map<String, dynamic> json) {
    return VerbForm(
      key: key,
      japanese: json['japanese'] as String,
      romanji: json['romanji'] as String,
      french: json['french'] as String,
      register: json['register'] as String? ?? 'neutre',
      example: VerbFormExample.fromJson(
        json['example'] as Map<String, dynamic>,
      ),
    );
  }
}

class Verb {
  final String id;
  final String japanese;
  final String romanji;
  final String french;
  final Map<String, VerbForm> forms;

  const Verb({
    required this.id,
    required this.japanese,
    required this.romanji,
    required this.french,
    required this.forms,
  });

  factory Verb.fromJson(String id, Map<String, dynamic> json) {
    final formsJson = json['forms'] as Map<String, dynamic>;
    final forms = <String, VerbForm>{};
    for (final entry in formsJson.entries) {
      forms[entry.key] = VerbForm.fromJson(
        entry.key,
        entry.value as Map<String, dynamic>,
      );
    }
    return Verb(
      id: id,
      japanese: json['japanese'] as String,
      romanji: json['romanji'] as String,
      french: json['french'] as String,
      forms: forms,
    );
  }
}
