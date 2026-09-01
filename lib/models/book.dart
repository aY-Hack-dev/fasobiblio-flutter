class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.description,
    required this.image,
    required this.isPremium,
    required this.price,
    required this.views,
    required this.downloads,
    required this.createdAt,
    required this.language,
    required this.level,
    required this.year,
  });

  final String id;
  final String title;
  final String author;
  final String category;
  final String description;
  final String image;
  final bool isPremium;
  final num price;
  final int views;
  final int downloads;
  final int createdAt;
  final String language;
  final String level;
  final String year;

  factory Book.fromJson(String id, Map<String, dynamic> value) => Book(
    id: id,
    title: '${value['title'] ?? value['titre'] ?? 'Document'}',
    author: '${value['author'] ?? value['auteur'] ?? 'Auteur non renseigné'}',
    category: '${value['category'] ?? value['categorie'] ?? 'autres'}',
    description: '${value['description'] ?? ''}',
    image: '${value['image'] ?? value['coverUrl'] ?? ''}',
    isPremium: value['isPremium'] == true,
    price: _number(value['discountPrice'] ?? value['price'] ?? value['prix']),
    views: _number(value['views']).toInt(),
    downloads: _number(value['downloads']).toInt(),
    createdAt: _number(value['createdAt']).toInt(),
    language: '${value['language'] ?? 'fr'}',
    level: '${value['level'] ?? ''}',
    year: '${value['year'] ?? ''}',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'category': category,
    'description': description,
    'image': image,
    'isPremium': isPremium,
    'price': price,
    'views': views,
    'downloads': downloads,
    'createdAt': createdAt,
    'language': language,
    'level': level,
    'year': year,
  };

  static num _number(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;
}

String categoryLabel(String value) => value
    .replaceAll(RegExp(r'[-_]+'), ' ')
    .split(' ')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');
