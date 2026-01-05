<div align="center">

# ⚡ OPTIMIZER

### 🚀 Windows 10/11 Performance & Gaming Optimization Suite

[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-2025-orange?style=for-the-badge)](https://github.com/kaylerberserk/Optimizer)
[![License](https://img.shields.io/badge/License-Free-green?style=for-the-badge)](LICENSE)
[![Download](https://img.shields.io/badge/Download-Latest-blue?style=for-the-badge&logo=github)](https://github.com/kaylerberserk/Optimizer/archive/refs/heads/main.zip)

---

**Script tout-en-un pour optimiser Windows 10/11**  
*Latence réduite • FPS maximisés • Télémétrie désactivée • Système ultra-réactif*

</div>

---

## 📋 Description

**Optimizer** est un script batch complet d'optimisation Windows conçu pour :
- 🎮 **Joueurs compétitifs** (Fortnite, Valorant, etc.)
- 💼 **Utilisateurs bureautiques** recherchant un système fluide
- 🔒 **Soucieux de leur vie privée** (télémétrie Microsoft désactivée)

Le script détecte automatiquement si vous êtes sur **PC fixe** ou **portable** et adapte les optimisations.

---

## ✨ Fonctionnalités

### 🖥️ Optimisations Système
| Fonctionnalité | Description |
|----------------|-------------|
| Priorités CPU | Configuration csrss.exe, IRQ, Win32PrioritySeparation |
| Profil Gaming MMCSS | Scheduling Category High, GPU Priority 8 |
| Interface Windows | Menu contextuel classique, délais UI à 0ms |
| Services Windows | Désactivation 50+ services inutiles |
| Démarrage rapide | StartupDelayInMSec à 0, animation boot désactivée |

### 🧠 Optimisations Mémoire
| Fonctionnalité | Description |
|----------------|-------------|
| PageFile optimisé | Kernel en RAM, pas de clear au shutdown |
| SysMain/Prefetch | Configuration optimale pour SSD |
| Memory Compression | Désactivée pour réduire l'overhead CPU |
| SvcHostSplitThreshold | Réduit le nombre de processus svchost |

### 💾 Optimisations Disques
| Fonctionnalité | Description |
|----------------|-------------|
| NTFS optimisé | 8dot3 OFF, LastAccess OFF, compression OFF |
| TRIM automatique | Exécuté sur tous les SSD détectés |
| NVMe natif | Performance mode activé |
| Chemins longs | Support des chemins >260 caractères |

### 🎮 Optimisations GPU
| Fonctionnalité | Description |
|----------------|-------------|
| GameDVR désactivé | Supprime l'overhead d'enregistrement |
| Game Mode | Conservé pour prioriser les jeux |
| VRR/Flip Model | Activé pour DirectX |
| NVIDIA Profile | Profil optimisé via NVIDIA Inspector |
| Télémétrie NVIDIA | Désactivée |

### 🌐 Optimisations Réseau
| Fonctionnalité | Description |
|----------------|-------------|
| BBR2 Congestion | Algorithme moderne pour meilleur débit |
| Nagle/DelACK OFF | Réduit la latence TCP |
| DNS optimisé | Cache optimisé, DoH activé |
| QoS Gaming | DSCP 46 pour Fortnite |
| NIC optimisé | EEE OFF, Interrupt Moderation minimal |
| ISATAP/Teredo OFF | Protocoles tunneling désactivés |

### ⚡ Optimisations Énergie (PC Bureau)
| Fonctionnalité | Description |
|----------------|-------------|
| Ultimate Performance | Plan d'alimentation max perfs |
| Timer Coalescing OFF | Désactivé pour latence minimale |
| Power Throttling OFF | Pas de bridage CPU |
| SetTimerResolution | Timer à 0.5ms au démarrage |
| USB Selective Suspend | Désactivé pour périphériques gaming |
| ASPM OFF | Pas d'économie PCIe |

### 🔒 Vie Privée & Télémétrie
| Fonctionnalité | Description |
|----------------|-------------|
| Télémétrie Microsoft | Complètement désactivée |
| Activity History | Désactivée (Timeline OFF) |
| Publicités Windows | Bloquées |
| Bing/Cortana | Désactivés dans la recherche |
| Bloatware | Content Delivery Manager désactivé |
| Fichier hosts | Domaines télémétrie bloqués |

### 🛡️ Gestion Windows (Menu dédié)
| Option | Description |
|--------|-------------|
| Windows Defender | Activer/Désactiver |
| UAC | Activer/Désactiver |
| Animations | Activer/Désactiver (5 options conservées) |
| Copilot/Widgets/Recall | Activer/Désactiver (Windows 11) |
| OneDrive | Désinstallation complète |
| Microsoft Edge | Désinstallation complète |

---

## 📁 Structure du Projet

```
Optimizer/
├── 📜 All in One.cmd           # Script principal d'optimisation
├── 📁 Tools/
│   ├── 📁 TCPOptimizer/        # Optimisation réseau
│   ├── 📁 NVIDIA Inspector/    # Paramètres GPU
│   ├── 📁 O&O ShutUp10/        # Anti-télémétrie
│   └── 📁 Timer & Interrupt/   # Timer Resolution + MSI Mode
└── 📁 Game Configs/
    ├── 📁 Fortnite/            # GameUserSettings optimisés
    └── 📁 Valorant/            # GameUserSettings optimisés
```

---

## 🚀 Installation

### Méthode Rapide
1. **Téléchargez** le repository ([Download ZIP](https://github.com/kaylerberserk/Optimizer/archive/refs/heads/main.zip))
2. **Extrayez** le dossier
3. **Exécutez** `All in One.cmd` **en tant qu'Administrateur**
4. Choisissez vos optimisations dans le menu

### Options du Menu Principal
| Touche | Action |
|--------|--------|
| `1-5` | Optimisations individuelles (Système, Mémoire, Disques, GPU, Réseau) |
| `6-9` | Optimisations PC Bureau (Périphériques, Énergie, Sécurité) |
| `D` | **Tout optimiser (PC Bureau)** |
| `L` | **Tout optimiser (PC Portable)** |
| `G` | Gestion Windows (Defender, Edge, OneDrive, etc.) |
| `N` | Nettoyage avancé Windows |
| `R` | Créer un point de restauration |

---

## ⚠️ Avertissements

> **⚠️ CRÉEZ UN POINT DE RESTAURATION** avant d'appliquer ces optimisations.

> **🎮 Compatibilité Anti-Cheat** : Le script conserve HVCI et CFG activés pour Valorant/Fortnite.

> **💻 PC Portable** : L'hibernation et certaines économies d'énergie sont conservées.

---

## 🔧 Outils Inclus

| Outil | Usage |
|-------|-------|
| **TCPOptimizer** | Configuration réseau avancée |
| **NVIDIA Inspector** | Profil GPU optimisé |
| **O&O ShutUp10** | Anti-télémétrie graphique |
| **SetTimerResolution** | Timer système à 0.5ms |
| **GoInterruptPolicy** | Configuration MSI Mode |

---

## 📊 Résultats Attendus

- ✅ Réduction du DPC Latency
- ✅ Moins de micro-stutters en jeu
- ✅ Boot Windows plus rapide
- ✅ Système plus réactif
- ✅ Moins de données envoyées à Microsoft
- ✅ Espace disque libéré (hibernation off, nettoyage)

---

## 🔄 Mises à jour 2025-2026

- ✅ Support Windows 11 24H2
- ✅ Désactivation Recall/AI/Copilot
- ✅ BBR2 congestion provider
- ✅ Optimisations CPU hybrides (P-cores/E-cores Intel)
- ✅ Activity History OFF

---

<div align="center">

**Made with ❤️ by Kayler**

⭐ **Star ce repo si ça t'a aidé !** ⭐

</div>
