/// Modèle de données pour l'échange NDEF entre téléphones
class NdefPayload {
  final String id;
  final String description;

  NdefPayload({
    required this.id,
    required this.description,
  });

  /// Création depuis un Map JSON
  factory NdefPayload.fromJson(Map<String, dynamic> json) {
    return NdefPayload(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  /// Conversion vers Map JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
    };
  }

  /// Validation des données
  bool get isValid => id.isNotEmpty && description.isNotEmpty;

  @override
  String toString() => 'NdefPayload(id: $id, description: $description)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NdefPayload &&
        other.id == id &&
        other.description == description;
  }

  @override
  int get hashCode => id.hashCode ^ description.hashCode;
}