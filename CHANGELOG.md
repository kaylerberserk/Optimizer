# Changelog

Toutes les modifications notables de ce projet sont documentees ici.
Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
et ce projet adhere au [Semantic Versioning](https://semver.org/lang/fr/).

## [Unreleased] - 2026-06-XX

### Securite
- Templates sanitises pour `Game Configs/Fortnite` et `Game Configs/Valorant`
  (PII retirees : UUID Epic, EDID moniteur, historique shop, dates).
- Documentation ajoutee sur l'usage de `git filter-repo` pour purger l'historique
  Git des fichiers PII retraites.

### Fixed
- Bug B1 : 4 lignes `powercfg` utilisant un GUID inexistant
  (`bae08b81-2d5e-4688-ad6a-13243356654b`) retirees - etaient des no-op silencieux.
- Bug B2 : `bcdedit /set bootuxdisabled on` desactive desormais uniquement en
  profil LATENCE (preserve l'EXPERIENCE EQUILIBRE).
- Bug B3 : restauration AMD Core Parking ecrivait la meme valeur (100) que la
  desactivation. Reecrit pour restaurer le defaut Windows (0).
- 5 labels dead (`:COMMON_SECURITE_NON`, `:COMMON_DEFENDER_NON`,
  `:COMMON_ANIMATIONS_NON`, `:COMMON_IA_NON`, `:COMMON_UAC_NON`) supprimes.
  La fonction `:COMMON_YES_NO` n'utilisait jamais `%~2`.

### Removed
- `Tools/O&O ShutUp10/OOSU10.exe` (79 MB, jamais reference par le script).
- `Tools/Timer & Interrupt/SetTimerResolution.exe - Raccourci.lnk` (raccourci
  Windows commit par erreur, le script cree son propre raccourci au runtime).

### Added
- `LICENSE` (MIT) - etait manquant alors que le README clamait MIT.
- `CHANGELOG.md` - ce fichier.
- `SECURITY.md` - politique de securite formelle.
- `Game Configs/Fortnite/GameUserSettings.ini.template`
- `Game Configs/Valorant/GameUserSettings.ini.template`

## [2026.02.11] - 2026-02-11

### Changed
- Version 2026.02 publiee.

## [Earlier]

Voir l'historique Git : `git log --oneline`.
