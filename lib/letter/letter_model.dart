class Letter {
  final int letterCode;
  final int diaryCode;
  final String letterContents;
  final DateTime createdAt;

  Letter({
    required this.letterCode,
    required this.diaryCode,
    required this.letterContents,
    required this.createdAt,
  });

  factory Letter.fromJson(Map<String, dynamic> json) {
    return Letter(
      letterCode: json['letterCode'],
      diaryCode: json['diaryCode'],
      letterContents: json['letterContents'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}