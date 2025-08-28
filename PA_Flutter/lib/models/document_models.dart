class Document {
  final String id;
  final String title;
  final String? content; // Optional, as content might be fetched separately
  final String? mimeType;
  final DateTime? lastModified;

  Document({required this.id, required this.title, this.content, this.mimeType, this.lastModified});

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      mimeType: json['mimeType'] as String?,
      lastModified: json['lastModified'] != null ? DateTime.parse(json['lastModified']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'mimeType': mimeType,
      'lastModified': lastModified?.toIso8601String(),
    };
  }
}