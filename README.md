<div align="center">

# ⚡ WINDOWS OPTIMIZER

### 🚀 Windows 10/11 Ultimate Performance & Gaming Optimization Script

[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-2026-orange?style=for-the-badge)](https://github.com/kaylerberserk/Optimizer)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Download](https://img.shields.io/badge/Download-Latest-blue?style=for-the-badge&logo=github)](https://github.com/kaylerberserk/Optimizer/archive/refs/heads/main.zip)

---

**Script batch tout-en-un pour un Windows ultra-rapide et optimisé**  
*Multitâche ultra-réactif • Gaming sans latence • Télémétrie complètement bloquée • Système 100% fonctionnel*

</div>

---

## 📋 Description

**Windows Optimizer** est un script d'optimisation complet et intelligent pour Windows 10 et 11, conçu pour :

- 🎮 **Gamers compétitifs** (Fortnite, Valorant, Call of Duty, etc.) - Réduction maximale de la latence
- 💼 **Professionnels** - Système ultra-réactif pour bureautique, développement, création de contenu
- 🔒 **Utilisateurs sensibles à la vie privée** - Télémétrie Microsoft 100% désactivée et bloquée
- ⚡ **Enthousiastes performance** - Extraction de chaque milliseconde de votre matériel

**⚠️ Philosophie** : Optimiser sans casser. Toutes les fonctionnalités utiles de Windows sont préservées (Xbox Game Pass, Windows Hello, Bluetooth, VPN, etc.).

---

## ✨ Fonctionnalités Principales

### 🖥️ Optimisations Système Core

| Fonctionnalité | Description | Impact |
|----------------|-------------|---------|
| **Priorités CPU Avancées** | IRQ0/IRQ8 à priorité 1, Win32PrioritySeparation=38 | Réactivité système immédiate |
| **Profil Gaming MMCSS** | Scheduling Category High, SFIO Priority High | Pas de micro-freezes en jeu |
| **Interface Windows** | Menu contextuel classique, MenuShowDelay=0 | UI instantanée |
| **Démarrage Optimisé** | StartupDelayInMSec=0, animation boot OFF | Boot en 5-8 secondes |
| **Priorité Foreground** | Applications actives toujours prioritaires CPU | Multitâche fluide |

### 🧠 Optimisations Mémoire & Cache

| Fonctionnalité | Description | Impact |
|----------------|-------------|---------|
| **PageFile Optimisé** | DisablePagingExecutive=1, ClearPageFileAtShutdown=0 | Kernel en RAM |
| **SysMain/Superfetch** | Activé et optimisé pour NVMe/SSD | Apps s'ouvrent en 0.5s |
| **Prefetcher** | EnablePrefetcher=3, EnableSuperfetch=1 | Chargement instantané |
| **Compression Mémoire** | Désactivée via Disable-MMAgent | Moins d'overhead CPU |
| **SvcHost Optimisé** | SplitThreshold adapté à la RAM | Moins de processus svchost |
| **FTH OFF** | Fault Tolerant Heap désactivé | Gain de performance mémoire |

### 💾 Optimisations Stockage & I/O

| Fonctionnalité | Description | Impact |
|----------------|-------------|---------|
| **NTFS Optimisé** | 8dot3 OFF, LastAccess OFF, TRIM activé | Accès fichiers ultra-rapide |
| **NVMe Natif** | Windows 11 24H2+ natif mode activé | Performance SSD maximale |
| **DirectStorage** | FUA=0, ForceIOPriority=1 | Chargement jeux instantané |
| **Chemins Longs** | LongPathsEnabled=1 | Support >260 caractères |
| **Cache Icônes** | Max Cached Icons=8192 | Dossiers lourds instantanés |
| **SysMain Auto** | Détecte SSD/HDD et optimise automatiquement | Adaptatif intelligent |

### 🎮 Optimisations GPU & Gaming

| Fonctionnalité | Description | Impact |
|----------------|-------------|---------|
| **GameDVR OFF** | Enregistrement Xbox complètement désactivé | 0% overhead GPU |
| **Game Mode** | Optimisé pour Windows 11 24H2/25H2 | Priorité automatique jeux |
| **HAGS** | Hardware Accelerated GPU Scheduling ON | Latence GPU réduite |
| **VRR/Flip Model** | VRROptimizeEnable=1, SwapEffectUpgradeEnable=1 | DirectX ultra-smooth |
| **NVIDIA Profile** | Profil optimisé téléchargé automatiquement | Paramètres pro gaming |
| **Télémétrie GPU** | NVIDIA et AMD telemetry OFF | Moins de processus background |
| **Timer Resolution** | 0.5ms au démarrage (SetTimerResolution) | Input lag minimal |

### 🌐 Optimisations Réseau Ultra-Rapide

| Fonctionnalité | Description | Impact |
|----------------|-------------|---------|
| **BBR2 Congestion** | Algorithme moderne remplace CUBIC | Débit maximum, ping stable |
| **Nagle/DelACK OFF** | TcpAckFrequency=1, TCPNoDelay=1 | Latence TCP minimale |
| **DNS Optimisé** | Cache avancé + DoH automatique | Résolution DNS instantanée |
| **QoS Gaming** | DSCP 46 pour jeux UDP/TCP | Priorité paquets gaming |
| **NIC Optimisé** | EEE OFF, Interrupt Moderation minimal | Réactivité réseau maximale |
| **ISATAP/Teredo OFF** | Protocoles tunneling inutiles désactivés | Moins de trafic réseau |
| **LLMNR OFF** | Multicast DNS désactivé | Réduction trafic réseau |

### ⚡ Optimisations Énergie (Mode Bureau)

| Fonctionnalité | Description | Impact |
|----------------|-------------|---------|
| **Ultimate Performance** | Plan d'alimentation maximal | CPU toujours à fond |
| **Timer Coalescing OFF** | Désactivé complètement | Latence minimale |
| **Power Throttling OFF** | Aucun bridage CPU | Performances constantes |
| **Core Parking OFF** | Tous les cœurs actifs | Pas de latence CPU |
| **ASPM OFF** | Active State Power Management OFF | PCIe à fond |
| **USB Suspend OFF** | Selective Suspend désactivé | Périphériques gaming stables |
| **Fast Startup OFF** | Désactivé pour stabilité | Boot propre sans bugs |

### 🛡️ Télémétrie & Vie Privée (Bloquée à 100%)

| Composant | Action | Impact |
|-----------|--------|--------|
| **DiagTrack** | Service télémétrie principal OFF | Arrêt collecte données |
| **dmwappushservice** | Push service télémétrie OFF | Plus de notifications push MS |
| **WerSvc** | Windows Error Reporting OFF | Pas d'envoi rapports crash |
| **Tâches Planifiées** | 25+ tâches télémétrie OFF | Arrêt analyse comportement |
| **Autologgers** | AppModel, DiagLog, SQMLogger OFF | Arrêt logs diagnostic |
| **Fichier hosts** | 30+ domaines télémétrie bloqués | Bloquage réseau |
| **Registre** | 50+ clés télémétrie à 0 | Désactivation profonde |
| **Activity History** | Timeline, collecte activités OFF | Vie privée préservée |
| **Publicités** | Windows Ads, suggestions OFF | Interface propre |
| **Cortana/Bing** | Recherche web, assistant OFF | Recherche locale uniquement |

### 🎯 Gestion Windows (Menu Interactif)

| Option | Description | Réversible |
|--------|-------------|------------|
| **Windows Defender** | Activer/Désactiver complètement | ✅ Oui |
| **UAC** | Niveau normal ou complètement OFF | ✅ Oui |
| **Animations** | Mode Performance ou Complet (5 options ON) | ✅ Oui |
| **Copilot** | Bouton + Fonctionnalités IA ON/OFF | ✅ Oui |
| **Widgets** | Barre des tâches ON/OFF | ✅ Oui |
| **Recall** | Windows 11 24H2+ snapshot OFF | ✅ Oui |
| **OneDrive** | Désinstallation complète (app + registre + dossiers utilisateur) | ✅ Réinstallable |
| **Edge** | Désinstallation complète (app + composants système) | ✅ Réinstallable |

---

## 📦 Contenu du Repository

```
Optimizer/
├── 📜 All in One.cmd              # Script principal (2500+ lignes)
├── 📄 README.md                    # Ce fichier
├── 📁 Tools/
│   ├── 📁 TCPOptimizer/           # Configuration réseau avancée
│   │   ├── TCP Config.spg         # Profil gaming BBR2
│   │   └── TCP Default Config.spg # Sauvegarde paramètres
│   ├── 📁 NVIDIA Inspector/       # Profil GPU optimisé
│   │   └── nvidiaProfileInspector.exe
│   ├── 📁 O&O ShutUp10/           # Outil anti-télémétrie GUI
│   │   └── OOSU10.exe
│   └── 📁 Timer & Interrupt/      # Outils timer et MSI
│       └── SetTimerResolution.exe
└── 📁 Game Configs/               # Configs jeux optimisés
    ├── 📁 Fortnite/
    │   └── GameUserSettings.ini   # Paramètres compétitifs
    └── 📁 Valorant/
        └── GameUserSettings.ini   # Paramètres compétitifs
```

---

## 🚀 Guide d'Utilisation

### Méthode Rapide (Recommandée)

1. **Téléchargez** le repository : [📥 Download ZIP](https://github.com/kaylerberserk/Optimizer/archive/refs/heads/main.zip)
2. **Extrayez** le dossier `Optimizer-main` sur votre Bureau
3. **Clic droit** sur `All in One.cmd` → **"Exécuter en tant qu'administrateur"**
4. **Choisissez votre profil** dans le menu :
   - `D` → **PC Bureau** (toutes optimisations)
   - `L` → **PC Portable** (conserve batterie)
   - `1-9` → Optimisations individuelles
   - `G` → Gestion Windows (Defender, Edge, etc.)
   - `N` → Nettoyage avancé

### Menu Principal

```
╔══════════════════════════════════════════════════════════════╗
║                   MENU PRINCIPAL                             ║
╠══════════════════════════════════════════════════════════════╣
║  [1] Optimisations Systeme                                   ║
║  [2] Optimisations Memoire                                   ║
║  [3] Optimisations Disques                                   ║
║  [4] Optimisations GPU                                       ║
║  [5] Optimisations Reseau                                    ║
║  [6] Optimisations Peripheriques                             ║
║  [7] Optimisations Energie (PC Bureau)                       ║
║  [8] Desactiver Protections Securite                         ║
║  [D] TOUT OPTIMISER (PC Bureau) ⭐ RECOMMANDE                ║
║  [L] TOUT OPTIMISER (PC Portable)                            ║
║  [G] Menu Gestion Windows (Defender, UAC, etc.)              ║
║  [N] Nettoyage Avance Windows                                ║
║  [R] Creer Point de Restauration                             ║
╚══════════════════════════════════════════════════════════════╝
```

---

## ⚠️ Avertissements Importants

### 🛡️ Sécurité & Compatibilité

> **✅ Compatibilité Anti-Cheat** : Le script conserve **HVCI** et **CFG** activés. Valorant, Fortnite, Easy Anti-Cheat fonctionnent parfaitement.

> **✅ Fonctionnalités préservées** : Windows Hello, Bluetooth, VPN, Xbox Game Pass, imprimantes, etc. Tout fonctionne normalement.

> **⚠️ Point de restauration** : Créez un point de restauration (`Option R` dans le menu) avant la première utilisation.

> **⚠️ Redémarrage** : Un redémarrage est nécessaire pour appliquer toutes les modifications.

---

## 📝 FAQ

### Le script est-il sûr ?
**Oui.** Toutes les modifications sont réversibles. Même la désinstallation d'OneDrive ou Edge est réversible en les réinstallant depuis Microsoft.

Le script préserve toutes les fonctionnalités critiques (Bluetooth, VPN, Xbox, etc.).

### Puis-je l'utiliser sur un PC portable ?
**Oui.** Utilise l'option `L` (PC Portable) qui conserve l'hibernation et certaines économies d'énergie tout en appliquant les optimisations gaming.

### Est-ce que ça marche avec les anti-cheat ?
**Oui.** Le script conserve HVCI et CFG activés, requis par Valorant, Fortnite, et autres jeux avec anti-cheat.

### Puis-je revenir en arrière ?
**Oui.** Créez un point de restauration avant (`Option R`). Vous pouvez aussi relancer le script et choisir les options inverses.

### Le nettoyage supprime-t-il mes données ?
**Non.** Le nettoyage ne touche que :
- Fichiers temporaires
- Logs système
- Cache navigateurs (pas les cookies/sessions)
- Cache Windows Update
- Miniatures

Vos documents, photos, jeux, et paramètres sont 100% préservés.

### Puis-je utiliser le script plusieurs fois ?
**Oui.** Le script est idempotent - vous pouvez le relancer sans problème. Les modifications déjà appliquées restent, les nouvelles sont ajoutées.

### Que se passe-t-il si je désinstalle OneDrive ?
**OneDrive est complètement désinstallé** : l'application, toutes les entrées de registre, et les dossiers de synchronisation sont supprimés proprement.
- ✅ **Désinstallation propre** : Rien ne reste sur le système
- ✅ **Réinstallable** : Vous pouvez réinstaller OneDrive depuis [onedrive.com](https://www.microsoft.com/microsoft-365/onedrive/download) ou le Microsoft Store
- ✅ Vos fichiers locaux restent sur votre PC (dans votre dossier utilisateur)
- ✅ Aucune donnée personnelle n'est perdue

### Que se passe-t-il si je désinstalle Edge ?
**Edge est complètement désinstallé** : l'application et tous ses composants système sont supprimés proprement.
- ✅ **Désinstallation propre** : Pas de fichiers résiduels
- ✅ **Réinstallable** : Vous pouvez réinstaller Edge depuis [microsoft.com/edge](https://www.microsoft.com/edge) ou le Microsoft Store
- ✅ Le système reste stable (Windows fonctionne parfaitement sans Edge)
- ✅ Vous pouvez utiliser un autre navigateur (Chrome, Firefox, Brave, etc.)

---

## 🤝 Contribution

Les contributions sont les bienvenues ! Si vous avez des suggestions d'optimisations :

1. **Testez** sur votre machine
2. **Vérifiez** qu'il n'y a pas de régression
3. **Créez** une issue avec les détails techniques

---

## 📄 License

Ce projet est sous license MIT. Vous pouvez l'utiliser, le modifier, et le redistribuer librement.

---

## 🙏 Crédits

**Créé par Kayler** avec ❤️ pour la communauté gaming et performance.

---

<div align="center">

### ⭐ Si ce projet vous a aidé, laissez une star ! ⭐

**[📥 Télécharger la dernière version](https://github.com/kaylerberserk/Optimizer/archive/refs/heads/main.zip)**

</div>
