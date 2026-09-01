import 'package:flutter/material.dart';
import '../core/theme.dart';

enum InformationKind { about, terms, privacy, legal, downloads }

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key, required this.kind});
  final InformationKind kind;

  String get title => switch (kind) {
    InformationKind.about => 'À propos de Fasobiblio',
    InformationKind.terms => 'Conditions d’utilisation',
    InformationKind.privacy => 'Politique de confidentialité',
    InformationKind.legal => 'Mentions légales',
    InformationKind.downloads => 'Lecture et téléchargements',
  };

  List<(String, String)> get sections => switch (kind) {
    InformationKind.about => const [
      ('Notre mission', 'Fasobiblio est une bibliothèque numérique conçue pour rapprocher les ouvrages, cours et ressources pédagogiques des apprenants du Burkina Faso et d’ailleurs.'),
      ('Une vraie application mobile', 'Le catalogue, le lecteur PDF, la bibliothèque personnelle et les paiements sont intégrés à l’application. Les documents déjà ouverts restent disponibles sans connexion.'),
      ('Apprendre, comprendre, réussir', 'Nous sélectionnons et organisons les ressources pour faciliter la découverte, la lecture et la progression de chaque apprenant.'),
    ],
    InformationKind.terms => const [
      ('Utilisation du service', 'L’application est destinée à un usage personnel, éducatif et légal. L’utilisateur s’engage à respecter les droits attachés aux documents proposés.'),
      ('Compte', 'Le titulaire du compte est responsable de la confidentialité de son pseudo et de son mot de passe. Les achats et abonnements sont rattachés au compte connecté.'),
      ('Contenus Premium', 'L’accès est activé après confirmation du paiement par le serveur. Une interruption réseau peut retarder momentanément l’affichage de la confirmation.'),
      ('Disponibilité', 'Fasobiblio peut faire évoluer le catalogue et les fonctionnalités pour améliorer le service, la sécurité ou respecter les obligations applicables.'),
    ],
    InformationKind.privacy => const [
      ('Données utilisées', 'Fasobiblio traite les informations nécessaires au compte, à la récupération, aux achats, aux abonnements et à la synchronisation de votre bibliothèque.'),
      ('Stockage local', 'Les favoris, la liste de lecture, le catalogue récent et les PDF mis en cache sont enregistrés sur votre téléphone afin d’assurer le mode hors connexion.'),
      ('Paiements', 'Les paiements Mobile Money sont traités par MoneyFusion. Fasobiblio vérifie uniquement le statut de la transaction et ne stocke pas votre code secret Mobile Money.'),
      ('Vos choix', 'Vous pouvez vous déconnecter à tout moment. La suppression de l’application efface les données privées stockées dans son espace local, mais pas nécessairement les fichiers exportés dans Téléchargements.'),
    ],
    InformationKind.legal => const [
      ('Éditeur', 'Fasobiblio — bibliothèque numérique, Burkina Faso.'),
      ('Contact', 'WhatsApp / téléphone : +226 57 15 90 44'),
      ('Propriété intellectuelle', 'Les marques, l’interface et les contenus éditoriaux propres à Fasobiblio sont protégés. Les ouvrages restent soumis aux droits de leurs auteurs et éditeurs respectifs.'),
      ('Responsabilité', 'Les informations pédagogiques sont fournies comme ressources d’apprentissage. Elles ne remplacent pas les conseils d’un professionnel qualifié lorsque ceux-ci sont nécessaires.'),
    ],
    InformationKind.downloads => const [
      ('Lecture intégrée', 'Quand vous ouvrez un PDF, il est conservé dans l’espace privé de l’application et reste lisible hors connexion.'),
      ('Dossier public', 'Le bouton Télécharger crée une copie dans Download/Fasobiblio. Vous pouvez ensuite la retrouver avec l’application Fichiers de votre téléphone.'),
      ('Mises à jour', 'Une copie déjà enregistrée peut rester sur le téléphone même si une nouvelle version du document est publiée en ligne.'),
    ],
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
      children: [
        if (kind == InformationKind.about) Center(child: Image.asset('assets/branding/logo-full.jpg', width: 180, height: 130, fit: BoxFit.contain)),
        if (kind == InformationKind.about) const SizedBox(height: 10),
        ...sections.map((section) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(section.$1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 8),
            Text(section.$2, style: const TextStyle(height: 1.55, color: AppColors.muted)),
          ]),
        )),
        const Padding(padding: EdgeInsets.only(top: 10), child: Text('Dernière mise à jour : septembre 2026', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppColors.muted))),
      ],
    ),
  );
}
