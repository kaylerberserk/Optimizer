# WindowsOptimizer

Travaille simplement, avec des corrections locales et proportionnees.

## Regles du projet

- Les fichiers principaux sont `All in One.cmd`, `launcher.ps1` et `README.md`. Le README fait partie du contrat : garde le code, la documentation et la publication alignes.
- `All in One.cmd` est volontairement un script unique, dense et portable. Preserve ce choix : pas de sur-ingenierie, de couches inutiles ni de multiplication de fichiers ; cherche l'equilibre entre fiabilite, lisibilite, efficacite et concision.
- Le launcher n'epingle aucun SHA : `-VerifyOnly` affiche seulement un SHA-256 informatif du batch prepare. Un test local peut utiliser le batch du checkout ; teste toujours la copie distante a part, avec le launcher seul dans un dossier temporaire.
- Pour les profils, controle les parcours manuel et `Tout optimiser`, ainsi que les transitions Normal/Gaming et Eco/Performance Max dans les deux sens.
- Une restauration "par defaut" restaure un etat capture ou applique un fallback Windows documente. Supprimer une valeur n'est pas toujours l'inverse correct.
- Pour les tweaks Windows, fais une recherche Web recente et croise les sources : la documentation Microsoft peut etre incomplete, imprecise, ancienne ou trop prudente. Comprends le mecanisme reel, puis confronte documentation, forums techniques, tests reproductibles et retours terrain.
- Propose les ameliorations utiles en expliquant simplement leur interet, sans compliquer le projet.
- Ne declare pas un travail termine sans tests concrets, mais sans en faire trop non plus.
