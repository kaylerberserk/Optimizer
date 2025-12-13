<div align="center">

# ⚡ OPTIMIZER

### 🚀 Windows Performance & Gaming Optimization Suite

[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-Free-green?style=for-the-badge)](LICENSE)
[![Download](https://img.shields.io/badge/Download-Latest-blue?style=for-the-badge&logo=github)](https://github.com/kaylerberserk/Optimizer/archive/refs/heads/main.zip)

---

**Améliore les performances Windows pour le gaming compétitif**  
*Latence réduite • FPS optimisés • Système allégé*

</div>

---

## 📋 Description

**Optimizer** est une suite complète d'optimisation Windows conçue pour les joueurs compétitifs. Elle inclut un script all-in-one puissant ainsi que des outils et configurations prêts à l'emploi pour maximiser les performances de votre système.

---

## 📁 Structure du Projet

```
Optimizer/
├── 📜 All in One.cmd                  # Script principal d'optimisation
├── 📁 Tools/
│   ├── 📁 TCPOptimizer/               # Optimisation réseau
│   │   ├── TCPOptimizer.exe
│   │   ├── TCP Config.spg             # Config optimisée
│   │   └── TCP Default Config.spg     # Config par défaut (backup)
│   ├── 📁 NVIDIA Inspector/           # Paramètres GPU
│   │   ├── nvidiaProfileInspector.exe
│   │   └── Kaylers_profile.nip        # Profil optimisé
│   ├── 📁 O&O ShutUp10/               # Télémétrie Windows
│   │   ├── OOSU10.exe                 # Exécutable O&O ShutUp10
│   │   └── ooshutup10_kayler.cfg      # Config anti-télémétrie
│   └── 📁 Timer & Interrupt/          # Latence système
│       ├── GoInterruptPolicy.exe      # MSI Mode
│       ├── SetTimerResolution.exe     # Timer 0.5ms
│       ├── SetTimerResolution.exe - Raccourci.lnk  # Raccourci démarrage
│       └── MeasureSleep.exe           # Mesure timer
└── 📁 Game Configs/
    ├── 📁 Fortnite/                   # GameUserSettings optimisés
    └── 📁 Valorant/                   # GameUserSettings optimisés
```

---

## 🛠️ Outils Inclus

### TCPOptimizer
| Fichier | Description |
|---------|-------------|
| `TCPOptimizer.exe` | Optimise les paramètres réseau TCP/IP |
| `TCP Config.spg` | Profil réseau optimisé pour gaming |
| `TCP Default Config.spg` | Profil par défaut pour restaurer |

### NVIDIA Inspector
| Fichier | Description |
|---------|-------------|
| `nvidiaProfileInspector.exe` | Paramètres avancés GPU NVIDIA |
| `Kaylers_profile.nip` | Profil optimisé max FPS |

### O&O ShutUp10
| Fichier | Description |
|---------|-------------|
| `OOSU10.exe` | Exécutable O&O ShutUp10 |
| `ooshutup10_kayler.cfg` | Config pour désactiver la télémétrie Windows |

### Timer & Interrupt
| Fichier | Description |
|---------|-------------|
| `GoInterruptPolicy.exe` | Configure le MSI Mode (latence hardware) |
| `SetTimerResolution.exe` | Active la résolution timer 0.5ms |
| `SetTimerResolution.exe - Raccourci.lnk` | Raccourci à placer dans le démarrage |
| `MeasureSleep.exe` | Vérifie la résolution timer actuelle |

---

## 🚀 Installation

### Méthode Rapide
1. **Téléchargez** le repository ([Download ZIP](https://github.com/kaylerberserk/Optimizer/archive/refs/heads/main.zip))
2. **Extrayez** le dossier
3. **Exécutez** `All in One.cmd` en tant qu'Administrateur

### Utiliser les Outils Individuellement
1. **TCPOptimizer** → Lancer l'exe, charger `TCP Config.spg`
2. **NVIDIA Inspector** → Lancer l'exe, importer `Kaylers_profile.nip`
3. **O&O ShutUp10** → Lancer `OOSU10.exe`, importer `ooshutup10_kayler.cfg`
4. **Timer Resolution** → Copier le raccourci `.lnk` dans `shell:startup`

---

## ⚠️ Avertissement

> **Créez un point de restauration système avant d'appliquer ces optimisations.**  
> Ces modifications sont conçues pour le gaming compétitif et peuvent ne pas convenir à tous les usages.

---

## 📈 Optimisations Appliquées

- ✅ Désactivation de la télémétrie Windows
- ✅ Optimisation des services système
- ✅ Configuration Timer Resolution (0.5ms)
- ✅ Optimisation du stack réseau TCP/IP
- ✅ Configuration GPU NVIDIA optimale
- ✅ Désactivation des effets visuels superflus
- ✅ Configurations gaming prêtes (Fortnite, Valorant)

---

<div align="center">

**Made with ❤️ by Kayler**

⭐ **Star ce repo si ça t'a aidé !** ⭐

</div>
