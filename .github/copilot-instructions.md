# Hanasō — Contexte projet pour Copilot

## Vue d'ensemble
Application Flutter d'apprentissage du japonais avec quiz de phrases, jeu de verbes, lecture des mots vus au Japon, et consultation complète des phrases.
L'objectif principal est d'apprendre à parler un japonais fluide, très orienté oral et conversation courante.
L'interface est entièrement en français. Le nom affiché est "Hanasō".

## Stack technique
- **Framework** : Flutter (Dart SDK ^3.11.4, Material 3)
- **Packages** : `flutter_tts` (synthèse vocale japonaise), `shared_preferences` (persistance locale)
- **Plateformes** : Android, iOS, Web, Windows, Linux, macOS

## Architecture des fichiers
```
lib/
├── main.dart              # Point d'entrée, MaterialApp (home: MainShell), thème bleu
├── data/
│   ├── performance_repository.dart  # Scores (SharedPreferences), une instance par module : .phrases, .reading
│   ├── phrase_repository.dart    # Charge phrases.json depuis les assets
│   ├── reading_repository.dart   # Charge reading.json depuis les assets
│   └── verb_repository.dart      # Charge verbs.json depuis les assets
├── enums/
│   ├── app_section.dart   # AppSection {home, phrases, verbs, reading} (label + icônes des onglets)
│   └── quiz_mode.dart     # QuizMode {mix, frenchToJapanese, japaneseToFrench}
│                          # VerbDifficulty {easy, normal, hard} (+ label)
├── models/
│   ├── phrase.dart        # Modèles Phrase et PhraseDialogLine
│   ├── reading_word.dart  # Modèle ReadingWord (mot du module Lecture)
│   └── verb.dart          # Modèles Verb, VerbForm, VerbFormExample
├── screens/
│   ├── main_shell.dart    # Racine : NavigationBar + IndexedStack, charge phrases, mots de lecture + scores une seule fois
│   ├── home_page.dart     # Accueil : « Réviser maintenant », stats phrases + lecture, raccourcis modules
│   ├── phrases/
│   │   ├── phrases_section.dart   # AppBar + TabBar Quiz / Liste, bouton reset des scores
│   │   ├── phrase_quiz_page.dart  # Onglet Quiz (sélection pondérée, TTS, modes)
│   │   └── phrase_list_page.dart  # Onglet Liste (recherche, saut par catégorie, scores)
│   ├── reading/
│   │   ├── reading_section.dart     # AppBar + TabBar Facile / Normal / Liste, bouton reset des scores
│   │   ├── reading_choice_page.dart # Onglet Facile (QCM sur le sens)
│   │   ├── reading_recall_page.dart # Onglet Normal (de tête, met à jour le score)
│   │   └── reading_list_page.dart   # Onglet Liste (recherche, groupé par catégorie, scores)
│   └── verbs/
│       ├── verbs_section.dart     # Charge verbs.json, AppBar + TabBar Facile / Normal / Difficile
│       └── verb_quiz_page.dart    # QCM sur les conjugaisons (une instance par difficulté)
└── widgets/
    ├── phrase_card.dart   # Carte expansible avec japonais/romanji/français/contexte/dialogue
    ├── reading_word_views.dart  # ReadingPrompt (mot en grand) + ReadingAnswer (correction)
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
- Clés de forms : `past_polite`, `past_casual`, `negative_polite`, `negative_casual`, `want`, `progressive`, `permission`, `potential`, `imperative`, `try` (libellés FR via `VerbForm.label`)
- Chaque form contient : `japanese`, `romanji`, `french` (phrase conjuguée, ex: "J'ai mangé (poli)"), `register` (optionnel, défaut: "neutre"), `example` (objet)
- Chaque example contient : `japanese`, `romanji`, `french`

## Données (assets/reading.json)
- Structure : objet JSON avec des catégories comme clés (`"Transport"`, `"Directions"`, `"Lieux"`, `"Restaurant"`)
- Chaque catégorie contient un tableau de mots : `japanese`, `romanji`, `french`, `context` (optionnel, « où on le voit »)

## Logique du quiz de phrases (PhraseQuizPage)
- **3 modes** : Français→Japonais, Japonais→Français, Mixte
- **Score** : chaque phrase a un score de -5 à +5 (persisté dans SharedPreferences sous la clé `phrasePerformance` via `PerformanceRepository`), détenu par `MainShell` et partagé avec l'Accueil, le Quiz et la Liste
- **Sélection pondérée** : poids = `(5 - score).clamp(1, 10)` — les phrases mal maîtrisées apparaissent plus souvent
- **Clé unique phrase** : `"$japanese|$romanji|$french"`
- Boutons "Réussi" / "Raté" après avoir dévoilé la réponse (score mis à jour uniquement en mode Français→Japonais) ; le score est une série : réussi → `max(score, 0) + 1`, raté → `min(score, 0) - 1`
- TTS japonais (vitesse 0.45, pitch 1.0)

## Accueil (HomePage)
- Carte « Réviser maintenant » : ouvre Phrases › Quiz en Français→Japonais (via `revisionRequest` incrémenté dans MainShell)
- Stats des phrases et de la lecture (`_ProgressCard`) : maîtrisées (score ≥ 4 = 4 réussites d'affilée), en cours, à revoir (score ≤ -2 = 2 ratés d'affilée)
- Raccourcis vers chaque module (générés depuis `AppSection`)

## Logique du quiz de verbes (VerbQuizPage)
- **Format** : QCM à 4 choix (japonais + romanji) ; la difficulté est choisie via les onglets de l'AppBar (`VerbDifficulty.label`, Normal par défaut) ; contenu scrollable, bouton « Suivant » (ElevatedButton pleine largeur) fixé en bas, désactivé tant qu'on n'a pas répondu
- **Facile** : affiche l'infinitif français (ex: "Venir") → trouver le verbe brut parmi 4 verbes ; la correction montre les formes courantes (`_commonForms` : passé poli, négatif poli, progressif, vouloir)
- **Normal** (défaut) : verbe en petit (japonais + romanji sur la même ligne, français en dessous) + phrase conjuguée en français en grand (sans « (poli) »/« (familier) ») + chips forme et registre coloré (poli bleu, familier orange, neutre masqué) → distracteurs pris d'abord dans la même famille de formes (`_formFamilies` : passé/négatif poli/familier, formes en -te, vouloir/potentiel/impératif)
- **Difficile** : phrase conjuguée en français + chips forme/registre seulement → 4 verbes différents à la même forme
- **Après réponse** : vert/rouge sur les choix, détail de chaque choix, feedback (scroll automatique) avec la bonne réponse (terminaison colorée par rapport à la forme dictionnaire, sauf en facile) et l'exemple (sauf en facile)
- **TTS** : prononce la bonne réponse quand l'utilisateur répond juste
- Pas de score persisté pour les verbes

## Module Lecture (reconnaissance visuelle)
- **Objectif** : reconnaître d'un coup d'œil les kanji et mots vus partout au Japon (panneaux, gares, magasins, menus)
- **Onglets** : Facile / Normal / Liste ; mot affiché en grand (`ReadingPrompt`) ; correction commune (`ReadingAnswer` : romanji, français, « Où on le voit », bouton écouter)
- **Facile** : QCM, mot → 4 sens en français, distracteurs pris d'abord dans la même catégorie (sans doublon de sens) ; TTS si juste ; bouton « Suivant » fixé en bas ; ne met pas à jour le score
- **Normal** : de tête, mot seul → « Dévoiler » → Réussi / Raté ; sélection pondérée (même formule que les phrases, jamais deux fois le même mot d'affilée)
- **Liste** : recherche (français, romanji, japonais), groupée par catégorie, `ScoreBox` + mot + romanji + sens + contexte + TTS
- **Score** : même série -5 à +5 que les phrases, mis à jour uniquement en Normal, persisté sous `readingPerformance` (`PerformanceRepository.reading`) ; clé unique `"$japanese|$romanji"`

## Navigation
- **MainShell** : `NavigationBar` en bas + `IndexedStack` (l'état de chaque onglet est conservé)
- **Onglets** (`AppSection`) : Accueil (défaut) / Phrases / Verbes / Lecture
- **Bouton retour** : `PopScope` dans MainShell → revient à l'Accueil depuis un autre onglet, ne quitte l'app que depuis l'Accueil
- **Phrases** : `TabBar` Quiz / Liste dans l'AppBar ; **Verbes** : `TabBar` Facile / Normal / Difficile ; **Lecture** : `TabBar` Facile / Normal / Liste (`AutomaticKeepAliveClientMixin` sur les onglets)
- **Ajouter un module** : nouvelle valeur dans `AppSection` + cas dans `MainShell._buildSection` (+ sous-titre dans `HomePage`) ; max 5 onglets
- Pas de tiroir, pas de navigation nommée, pas de `Navigator.push` entre modules

## Conventions de code
- Dart idiomatique, classes immutables avec `const` constructors
- Widgets StatelessWidget quand possible, StatefulWidget sinon
- Pas de state management externe (setState uniquement) ; données partagées remontées dans `MainShell` et passées en paramètres + callbacks
- Écrans organisés par module dans `screens/<module>/`
- Commentaires en français si nécessaire

## Commandes utiles
- `flutter run` — lancer l'app
- `flutter build apk` — build Android
- `flutter analyze` — vérifier le code
- `flutter test` — lancer les tests (aucun test écrit pour l'instant)

