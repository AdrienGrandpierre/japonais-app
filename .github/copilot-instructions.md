# Japonais App — Contexte projet pour Copilot

## Vue d'ensemble
Application Flutter d'apprentissage du japonais avec quiz de phrases, jeu de verbes, et consultation complète des phrases.
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
│   ├── phrase_repository.dart    # Charge phrases.json depuis les assets
│   └── verb_repository.dart      # Charge verbs.json depuis les assets
├── enums/
│   └── quiz_mode.dart     # QuizMode {mix, frenchToJapanese, japaneseToFrench}
│                          # AppRoute {home, training, verbs}
│                          # VerbDifficulty {easy, normal, hard}
├── models/
│   ├── phrase.dart        # Modèles Phrase et PhraseDialogLine
│   └── verb.dart          # Modèles Verb, VerbForm, VerbFormExample
├── screens/
│   ├── home_page.dart     # Page quiz (sélection pondérée, score, TTS, modes)
│   ├── all_phrases_page.dart  # Liste de toutes les phrases avec recherche
│   └── verb_game_page.dart    # Jeu QCM sur les conjugaisons de verbes
└── widgets/
    ├── app_drawer.dart    # Drawer de navigation (Accueil / Entraînement / Verbes)
    ├── phrase_card.dart   # Carte expansible avec japonais/romanji/français/contexte/dialogue
    └── score_box.dart     # Indicateur visuel du score (-5 à +5, rouge→vert)
```

## Données (assets/phrases.json)
- Structure : objet JSON avec des catégories comme clés (`"Base"`, etc.)
- Chaque catégorie contient un tableau d'objets phrase
- Champs d'une phrase : `japanese`, `romanji`, `french`, `context` (optionnel), `dialog` (optionnel)
- Un dialog est un tableau d'objets avec `japanese`, `romanji`, `french`

## Données (assets/verbs.json)
- Structure : objet JSON avec l'id romanji du verbe comme clé (ex: `"taberu"`, `"iku"`)
- Chaque verbe contient : `japanese` (forme dictionnaire), `romanji`, `french` (infinitif, ex: "Manger"), `forms` (objet)
- Clés de forms : `past_polite`, `past_casual`, `negative_polite`, `negative_casual`, `want`, `progressive`, `permission`, `potential`, `imperative`, `try` (libellés FR dans `_formLabel` de VerbGamePage)
- Chaque form contient : `japanese`, `romanji`, `french` (phrase conjuguée, ex: "J'ai mangé (poli)"), `register` (optionnel, défaut: "neutre"), `example` (objet)
- Chaque example contient : `japanese`, `romanji`, `french`

## Logique du quiz de phrases (HomePage)
- **3 modes** : Français→Japonais, Japonais→Français, Mixte
- **Score** : chaque phrase a un score de -5 à +5 (persisté dans SharedPreferences sous la clé `phrasePerformance`)
- **Sélection pondérée** : poids = `(5 - score).clamp(1, 10)` — les phrases mal maîtrisées apparaissent plus souvent
- **Clé unique phrase** : `"$japanese|$romanji|$french"`
- Boutons "Réussi" (+1) / "Raté" (-1) après avoir dévoilé la réponse
- TTS japonais (vitesse 0.45, pitch 1.0)

## Logique du jeu de verbes (VerbGamePage)
- **Format** : QCM à 4 choix (japonais + romanji), sélecteur de difficulté fixé en haut de l'écran (ChoiceChips, hors du scroll)
- **Facile** : affiche l'infinitif français (ex: "Venir") → trouver le verbe brut parmi 4 verbes
- **Normal** (défaut) : verbe en petit (japonais + romanji sur la même ligne, français en dessous) + phrase conjuguée en français en grand (sans « (poli) »/« (familier) ») + chips forme et registre coloré (poli bleu, familier orange, neutre masqué) → distracteurs pris d'abord dans la même famille de formes (`_formFamilies` : passé/négatif poli/familier, formes en -te, vouloir/potentiel/impératif)
- **Difficile** : phrase conjuguée en français + chips forme/registre seulement → 4 verbes différents à la même forme
- **Après réponse** : vert/rouge sur les choix, détail de chaque choix, feedback avec la bonne réponse (terminaison colorée par rapport à la forme dictionnaire, sauf en facile) et l'exemple (sauf en facile), bouton "Suivant"
- **TTS** : prononce la bonne réponse quand l'utilisateur répond juste
- Pas de score persisté pour les verbes

## Navigation et Routes
- **AppRoute enum** : `home` (HomePage), `training` (AllPhrasesPage), `verbs` (VerbGamePage)
- **AppDrawer** : affiche les 3 options de navigation, highlight l'écran actif
- **Navigation** : utilise `Navigator.push` avec `MaterialPageRoute`, pas de navigation nommée

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
