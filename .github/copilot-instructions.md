# Japonais App — Contexte projet pour Copilot

## Vue d'ensemble
Application Flutter d'apprentissage du japonais avec quiz et consultation de phrases.
L'objectif principal est d'apprendre à parler un japonais fluide, très orienté oral et conversation courante.
L'interface est entièrement en français. Le nom affiché est "1mois pour parler japonais".

## Stack technique
- **Framework** : Flutter (Dart SDK ^3.11.4, Material 3)
- **Packages** : `flutter_tts` (synthèse vocale japonaise), `shared_preferences` (persistance locale)
- **Plateformes** : Android, iOS, Web, Windows, Linux, macOS

## Architecture des fichiers
```
lib/
├── main.dart              # Point d'entrée, MaterialApp, thème bleu
├── data/
│   └── phrase_repository.dart  # Charge phrases.json depuis les assets
├── enums/
│   └── quiz_mode.dart     # QuizMode {mix, frenchToJapanese, japaneseToFrench}, AppRoute {home, training}
├── models/
│   └── phrase.dart        # Modèles Phrase et PhraseDialogLine
├── screens/
│   ├── home_page.dart     # Page quiz (sélection pondérée, score, TTS, modes)
│   └── all_phrases_page.dart  # Liste de toutes les phrases avec recherche
└── widgets/
    ├── app_drawer.dart    # Drawer de navigation (Accueil / Entraînement)
    ├── phrase_card.dart   # Carte expansible avec japonais/romanji/français/contexte/dialogue
    └── score_box.dart     # Indicateur visuel du score (-5 à +5, rouge→vert)
```

## Données (assets/phrases.json)
- Structure : objet JSON avec des catégories comme clés (`"Base"`, etc.)
- Chaque catégorie contient un tableau d'objets phrase
- Champs d'une phrase : `japanese`, `romanji`, `french`, `context` (optionnel), `dialog` (optionnel)
- Un dialog est un tableau d'objets avec `japanese`, `romanji`, `french`

## Logique du quiz (HomePage)
- **3 modes** : Français→Japonais, Japonais→Français, Mixte
- **Score** : chaque phrase a un score de -5 à +5 (persisté dans SharedPreferences sous la clé `phrasePerformance`)
- **Sélection pondérée** : poids = `(5 - score).clamp(1, 10)` — les phrases mal maîtrisées apparaissent plus souvent
- **Clé unique phrase** : `"$japanese|$romanji|$french"`
- Boutons "Réussi" (+1) / "Raté" (-1) après avoir dévoilé la réponse
- TTS japonais (vitesse 0.45, pitch 1.0)

## Conventions de code
- Dart idiomatique, classes immutables avec `const` constructors
- Widgets StatelessWidget quand possible, StatefulWidget sinon
- Pas de state management externe (setState uniquement)
- Pas de navigation nommée, utilisation de `Navigator.push` avec MaterialPageRoute
- Commentaires en français si nécessaire

## Commandes utiles
- `flutter run` — lancer l'app
- `flutter build apk` — build Android
- `flutter analyze` — vérifier le code
- `flutter test` — lancer les tests (aucun test écrit pour l'instant)
