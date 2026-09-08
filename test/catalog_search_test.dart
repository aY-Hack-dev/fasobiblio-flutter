import 'package:flutter_test/flutter_test.dart';
import 'package:fasobiblio/models/book.dart';
import 'package:fasobiblio/services/catalog_search.dart';

void main() {
  final sea = Book.fromJson('sea', {
    'title': "Et si la mer n'était pas bleue",
    'author': 'Joseph Zobel',
  });
  final absence = Book.fromJson('absence', {
    'title': 'Absence',
    'author': 'Camille Bouchard',
  });
  test('finds a title in a page request without author', () {
    expect(
      searchCatalog(
        [absence, sea],
        'Explique-moi la page 7 de et si la mer était pas bleue',
      ).first.book.id,
      'sea',
    );
  });
  test('finds a distinctive fragment of a title', () {
    expect(
      searchCatalog([absence, sea], 'Explique la mer').first.book.id,
      'sea',
    );
  });
  test('tolerates a spelling error', () {
    expect(
      searchCatalog([absence, sea], 'Explique Absance').first.book.id,
      'absence',
    );
  });
  test('does not resolve a generic page request to an arbitrary book', () {
    expect(searchCatalog([absence, sea], 'explique moi la page 7'), isEmpty);
  });
  test('preserves ambiguity and uses author when supplied', () {
    final other = Book.fromJson('other', {
      'title': 'Absence',
      'author': 'Autre Auteur',
    });
    expect(searchCatalog([other, absence], 'Absence'), hasLength(2));
    expect(
      searchCatalog([
        other,
        absence,
      ], 'Absence de Camille Bouchard').first.book.id,
      'absence',
    );
  });
}
