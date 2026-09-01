# Fasobiblio Flutter

Application Android native de Fasobiblio, sans WebView. Elle consomme directement le catalogue Firebase et l’API existante, tandis que l’administration reste sur le web.

## Fonctions

- accueil éditorial, rayons et nouveautés ;
- recherche et filtres ;
- favoris et liste « à lire » hors ligne ;
- comptes Fasobiblio et session invitée ;
- assistant pédagogique ;
- offres et ouvrages Premium ;
- lecture, téléchargement et partage des PDF.

## Compiler

```bash
flutter pub get
flutter build apk --release
```

APK généré : `build/app/outputs/flutter-apk/app-release.apk`.

Le workflow `.github/workflows/android-apk.yml` permet aussi de compiler
automatiquement l’APK depuis GitHub Actions (bouton **Run workflow**).
