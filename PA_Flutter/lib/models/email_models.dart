class Email {
  final String sender;
  final String subject;
  final String body;

  Email({required this.sender, required this.subject, required this.body});

  factory Email.fromJson(Map<String, dynamic> json) {
    return Email(
      sender: json['sender'] as String,
      subject: json['subject'] as String,
      body: json['body'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'subject': subject,
      'body': body,
    };
  }
}