# Politique de Securite

## Versions supportees

| Version | Supportee |
|---------|-----------|
| 2026.x  | Oui       |
| 2025.x  | Bug fixes uniquement |
| < 2025  | Non       |

## Signaler une vulnerabilite

**NE PAS ouvrir d'issue publique** pour les vulnerabilites de securite.

Envoyer un email a : kaylerberserk@[...] (cf README)
OU ouvrir une [GitHub Security Advisory](https://github.com/kaylerberserk/WindowsOptimizer/security/advisories/new) privee.

Delai de reponse attendu : 7 jours ouvrables.

## Ce que ce projet FAIT

- Desactive des fonctionnalites Windows (animations, telemetrie, UAC, Defender)
- Telecharge des binaires tiers (NVIDIA Inspector, SetTimerResolution)
- Execute des scripts distants (MAS, Chris Titus WinUtil) via `irm | iex`
- Modifie des cles de registre systeme

## Ce que ce projet NE FAIT PAS

- Ne contient pas de payload malveillant (auditable, code source ouvert)
- Ne telecharge pas de binaire sans possibilite de verifier le SHA-256
  (a ameliorer - voir issues)

## Recommandations avant utilisation

1. **Creer un point de restauration** Windows avant execution
2. **Lire le code source** de ce qui va etre execute
3. **Examiner les URL** de telechargement
4. **Tester sur une machine non critique** d'abord
5. **Ne PAS utiliser** sur une machine partagee/multi-utilisateur

## Reversibilite

Chaque optimisation a son inverse dans le menu :
- `[8] Gerer Protections Securite` - desactiver/restaurer
- `[N] Nettoyage Avance` - nettoyage (avec confirmation)

## PII (donnees personnelles)

Les fichiers de configuration de jeux dans `Game Configs/` sont des
**TEMPLATES**. Les fichiers reels contiennent des identifiants personnels
(Epic UUID, EDID moniteur) et ne doivent JAMAIS etre commites.
