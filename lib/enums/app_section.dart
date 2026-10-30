import 'package:flutter/material.dart';

/// Onglets de la barre de navigation, dans l'ordre d'affichage.
enum AppSection {
  home('Accueil', Icons.home_outlined, Icons.home),
  phrases('Phrases', Icons.chat_bubble_outline, Icons.chat_bubble),
  verbs('Verbes', Icons.translate_outlined, Icons.translate),
  reading('Lecture', Icons.signpost_outlined, Icons.signpost);

  const AppSection(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
