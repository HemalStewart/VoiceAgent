class Correction {
  final String original;
  final String corrected;
  final String explanation;

  const Correction({
    required this.original,
    required this.corrected,
    required this.explanation,
  });

  factory Correction.fromJson(Map<String, dynamic> json) {
    return Correction(
      original: json['original'] as String? ?? '',
      corrected: json['corrected'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'original': original,
      'corrected': corrected,
      'explanation': explanation,
    };
  }
}
