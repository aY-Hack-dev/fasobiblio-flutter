import '../models/book.dart';

String normalizeSearch(String value) {
  var text = value.toLowerCase();
  const accents = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'œ': 'oe',
  };
  accents.forEach((key, value) => text = text.replaceAll(key, value));
  return text.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

const _ignored = {
  'explique',
  'expliquer',
  'moi',
  'resume',
  'resumer',
  'page',
  'pages',
  'livre',
  'roman',
  'document',
  'le',
  'la',
  'les',
  'de',
  'du',
  'des',
  'un',
  'une',
  'et',
  'si',
  'a',
  'au',
  'aux',
  'ce',
  'cet',
  'cette',
  'est',
  'il',
  'elle',
  'n',
  'pas',
  'que',
  'qui',
  's',
  'l',
  'd',
  'en',
  'sur',
  'tu',
  'peux',
  'veut',
  'veux',
  'voudrais',
  'je',
};
Set<String> _words(String value) => normalizeSearch(value)
    .split(' ')
    .where(
      (s) => s.length > 1 && !_ignored.contains(s) && int.tryParse(s) == null,
    )
    .toSet();
int _distance(String a, String b) {
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 0; i < a.length; i++) {
    final row = <int>[i + 1];
    for (var j = 0; j < b.length; j++) {
      final substitute = previous[j] + (a[i] == b[j] ? 0 : 1);
      final insert = row[j] + 1;
      final remove = previous[j + 1] + 1;
      row.add([substitute, insert, remove].reduce((a, b) => a < b ? a : b));
    }
    previous = row;
  }
  return previous.last;
}

List<({Book book, double score})> searchCatalog(
  List<Book> books,
  String query,
) {
  final words = _words(query);
  if (words.isEmpty) return [];
  final normalized = normalizeSearch(query);
  final hits = <({Book book, double score})>[];
  for (final book in books) {
    final title = normalizeSearch(book.title);
    final titleWords = _words(book.title);
    if (titleWords.isEmpty) continue;
    var matched = 0.0;
    for (final word in titleWords) {
      if (words.contains(word)) {
        matched++;
      } else if (words.any(
        (w) => w.length >= 4 && word.length >= 4 && _distance(w, word) <= 1,
      )) {
        matched += .75;
      }
    }
    var score = matched / titleWords.length;
    if (title.length > 3 && normalized.contains(title)) score = 1;
    final authorWords = _words(book.author);
    if (matched > 0 &&
        authorWords.isNotEmpty &&
        authorWords.every(words.contains)) {
      score += .25;
    }
    if (score >= .45 && matched > 0) hits.add((book: book, score: score));
  }
  hits.sort((a, b) => b.score.compareTo(a.score));
  return hits.take(8).toList();
}
