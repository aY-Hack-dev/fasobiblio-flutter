class AppNotification {
  const AppNotification({required this.id, required this.title, required this.message, required this.createdAt, required this.icon, required this.color});
  final String id;
  final String title;
  final String message;
  final int createdAt;
  final String icon;
  final String color;

  factory AppNotification.fromJson(String id, Map<String, dynamic> json) => AppNotification(
    id: id,
    title: _localized(json['title']),
    message: _localized(json['message']),
    createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
    icon: '${json['icon'] ?? 'fa-bell'}',
    color: '${json['color'] ?? ''}',
  );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'message': message, 'createdAt': createdAt, 'icon': icon, 'color': color};

  static String _localized(dynamic value) {
    if (value is Map) return '${value['fr'] ?? (value.values.isNotEmpty ? value.values.first : '')}';
    return '${value ?? ''}';
  }
}

class DocumentReview {
  const DocumentReview({required this.userId, required this.name, required this.comment, required this.stars, required this.createdAt, required this.status});
  final String userId;
  final String name;
  final String comment;
  final int stars;
  final int createdAt;
  final String status;

  factory DocumentReview.fromJson(String id, Map<String, dynamic> json) => DocumentReview(
    userId: id,
    name: '${json['name'] ?? 'Lecteur'}',
    comment: '${json['comment'] ?? ''}',
    stars: (json['stars'] as num?)?.toInt() ?? 0,
    createdAt: (json['ts'] as num?)?.toInt() ?? 0,
    status: '${json['status'] ?? 'pending'}',
  );
}
