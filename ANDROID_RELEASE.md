# Fasobiblio Android 1.1.0

La compilation conserve un APK universel, avec toutes les architectures Android
prises en charge. Elle utilise R8, supprime les ressources inutilisées et
compresse les bibliothèques natives dans l’APK. La première compilation de cette
refonte mesure 39,2 Mo, avant l’ajout des modules Firebase et de la photo/vocal.
La taille finale de chaque compilation est publiée dans son rapport Actions.
La taille installée sur le téléphone peut être supérieure à celle de l’APK.

## Notifications

Fournir `android/app/google-services.json` de l’application `com.fasobiblio.app`
dans le projet Firebase du serveur, ou renseigner le secret GitHub Actions
`FIREBASE_GOOGLE_SERVICES_JSON` contenant le JSON complet. Ne pas utiliser un
compte de service à la place de ce fichier de configuration client.

Sans ce fichier, l’application reste utilisable et les rappels locaux restent
disponibles. Les push sont indiqués comme indisponibles dans les préférences.
Le serveur nécessite aussi les routes mobiles et la file FCM préparées dans
le dépôt fasobiblio-api. Voir son fichier MOBILE_SERVICES.md.

## Mises à jour

Conserver `applicationId = com.fasobiblio.app` et la même clé de signature entre
les versions. Incrémenter le nombre après `+` dans pubspec.yaml pour chaque
version publiée : par exemple 1.1.1+15 après 1.1.0+14.

La clé de signature de l’application déjà installée est nécessaire pour la
mettre à jour sans désinstallation. Une nouvelle clé ne remplace pas une
ancienne signature. Les précédents builds utilisaient une clé de développement,
qui n’est pas conservée dans le dépôt.

La CI accepte les secrets suivants :
- ANDROID_KEYSTORE_BASE64 : contenu du keystore encodé en base64.
- ANDROID_STORE_PASSWORD : mot de passe du keystore.
- ANDROID_KEY_ALIAS : alias de la clé.
- ANDROID_KEY_PASSWORD : mot de passe de la clé.

Les secrets ne sont pas injectés dans les builds de pull requests. En l’absence
de clé de publication, un APK de test est compilé et identifié comme tel dans
le rapport. Ne pas utiliser cet APK pour une diffusion publique définitive.

Pour la distribution, le Play Store gère les mises à jour après publication.
Pour une diffusion directe, publier l’APK signé sur un lien officiel et stable ;
Android demandera à l’utilisateur d’autoriser son installation. Une mise à jour
avec la même signature et un code de version supérieur conserve les données.
