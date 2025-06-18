class Document {
  final int? id;
  final String title;
  final String type; // e.g. 'ID card', 'RCA', etc.
  final DateTime expiryDate;

  Document({
    this.id,
    required this.title,
    required this.type,
    required this.expiryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'expiryDate': expiryDate.toIso8601String(),
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      title: map['title'],
      type: map['type'],
      expiryDate: DateTime.parse(map['expiryDate']),
    );
  }
}