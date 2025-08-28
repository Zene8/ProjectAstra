class Task {
  final String id; // Unique ID for the task
  final String title;
  bool isDone;
  final DateTime? dueDate;

  Task({required this.id, required this.title, this.isDone = false, this.dueDate});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      isDone: json['isDone'] as bool? ?? false,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
      'dueDate': dueDate?.toIso8601String(),
    };
  }
}