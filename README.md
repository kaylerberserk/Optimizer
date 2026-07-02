<div align="center">

# WINDOWS OPTIMIZER

### 🚀 Le script ultime d'optimisation pour Windows 10 & 11
*Maximisez vos performances, réduisez votre latence et reprenez le contrôle sur votre système.*

[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-2026.06-orange?style=for-the-badge)](https://github.com/kaylerberserk/WindowsOptimizer)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

**Conçu pour le Gaming Compétitif, le Multitâche intensif et la Confidentialité.**  
*100% Transparent • Open Source • Script d'optimisation Windows*

</div>

---

## 📌 Sommaire
- [📖 À propos du projet](#-à-propos-du-projet)
- [🚀 Démarrage Rapide](#-démarrage-rapide)
- [🛠️ Guide des Fonctionnalités](#️-guide-des-fonctionnalités)
- [🛡️ Sécurité & Fiabilité](#-sécurité--fiabilité)
- [❓ FAQ (Foire Aux Questions)](#-faq-foire-aux-questions)

---

## 📖 À propos du projet

**Windows Optimizer** est un script d'automatisation professionnel conçu pour transformer une installation Windows standard en une station de travail ou de jeu haute performance. 

Ce script se distingue par sa **stabilité** et sa **polyvalence** : il est universel et a été rigoureusement testé sur tous les environnements, du PC de Gaming au poste de Bureautique, en passant par les Machines Virtuelles (VM). Contrairement aux versions "Lite" modifiées de Windows, ce script ne supprime aucun composant système vital, garantissant un système complet mais parfaitement optimisé.

---

## 🚀 Démarrage Rapide (Moins de 5 minutes)

### Option A — PowerShell (recommandé)
```powershell
irm "https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main/launcher.ps1" | iex
```
Collez cette commande dans **PowerShell (non-admin)** — elle télécharge, s'élève automatiquement en administrateur et lance le script.

### Option B — Téléchargement manuel
1. **Téléchargement** : Accédez au fichier [**All in One.cmd**](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd) et cliquez sur le bouton **Download**.
2. **Exécution** : Clic droit sur le fichier → **Exécuter en tant qu'administrateur**.
3. **Sécurité** : Appuyez sur **[R]** pour créer un point de restauration avant toute modification.
4. **Optimisation** : Appuyez sur **[O]** pour tout optimiser d'un coup. Le script vous pose quelques questions (usage, énergie, options) et applique automatiquement le profil adapté.
5. **Redémarrage** : Un redémarrage est nécessaire pour appliquer l'ensemble des changements.

---

## 🛠️ Guide des Fonctionnalités

### 🌟 Système de Profils à 2 Axes (All-in-One [O])

L'option **[O] Tout optimiser** repose sur **deux axes indépendants** qui définissent 4 combinaisons possibles. Le script vous pose quelques questions (profil + options) et en déduit automatiquement la configuration optimale.

Les sections granulaires reprennent la même logique, mais ne demandent que l'axe réellement utile : par exemple **Mémoire** demande l'énergie, **GPU/Système/Input** demandent l'usage, **Réseau** demande les deux, et **Énergie/Sécurité** redemandent l'usage uniquement quand un réglage dépend de Gaming vs Normal.

#### Axe 1 — Usage (`PROFIL_USAGE`)
> *Pilote la **latence applicative** : périphériques d'entrée, pile TCP, latence GPU.*

| Choix | Profil | Réglages clés |
|:---:|:---:|---|
| **[1]** | **GAMING** | Low Latency GPU (MaxFrameLatency=1), Nagle/DelACK OFF per-interface, initialRTO=1000, maxsynretransmissions=2, BBR2 (tous templates), TCP Pacing + ECN, Tcp1323Opts=3, DefaultTTL=64, TcpTimedWaitDelay=30, RssBaseCpu=1, QoS Fortnite DSCP 46, DisablePagefileEncryption, accélération souris OFF, Win8 Scaling. En MaxPerf : RSC/LSO OFF, ITR=200, Rx/Tx buffers max. En Eco : Nagle neutre, RSC/LSO ON. |
| **[2]** | **NORMAL** | BBR2 (tous templates), TCP Pacing + ECN, Tcp1323Opts=3, VRR ON, veille GPU préservée, Nagle/DelACK défaut Windows (ou neutre en Eco), SystemResponsiveness=20, accélération trackpad légère sur portable. |

#### Axe 2 — Énergie (`PROFIL_POWER`)
> *Pilote **l'énergie, le niveau de tuning NIC et le plan d'alimentation**.*

| Choix | Profil | Réglages clés |
|:---:|:---:|---|
| **[1]** | **ECO** | Plan Équilibré, RSC/LSO/checksum ON, gestion d'énergie NIC activée (WoL coupé), compression mémoire conservée, InterruptModeration adaptatif, MSI USB actif. |
| **[2]** | **MAX PERF** | Plan Ultimate Performance, RSC/LSO OFF en Gaming (ON en Normal), RscIPv6 OFF en Gaming+MaxPerf, Flow Control OFF, InterruptModeration adaptatif (ITR=200 par registre en Gaming), EEE/GigaLite/GreenGbe/PacketCoalescing OFF, Power Management NIC OFF, ReceiveBuffers/TransmitBuffers max, gestion énergie USB désactivée (selective suspend + USB 3 LPM), compression mémoire OFF (RAM > 8 Go), MSI USB actif, économies d'énergie coupées. |

> **Sur PC fixe comme portable** : les deux questions sont posées, pour permettre un desktop silencieux/économe ou un laptop branché en **MAX PERF**.
> **Sur PC portable** : la combinaison **GAMING + ECO** est autorisée avec un avertissement — Nagle/DelACK passe en neutre (batterie avant tout), mais les timers réseau (initialRTO=1000, maxsynretransmissions=2) et les optimisations GPU/input/CPU restent agressifs.


#### Règle d'attribution (design interne)
Chaque réglage est piloté par **un seul axe**, jamais les deux, pour éviter les conflits :
- **Latence applicative** (input, I/O, stack TCP Nagle/timers, low-latency GPU) → `PROFIL_USAGE`
- **Énergie / tuning NIC / plan d'alimentation** → `PROFIL_POWER`

Exceptions réseau :
- **RSC/LSO/RscIPv6** : coupés uniquement en **GAMING + MAX PERF** (préservent débit/stabilité en Normal/Eco).
- **initialRTO/maxsynretransmissions** : agressifs pour tous les profils **GAMING** (ECO ou MaxPerf).
- **Nagle/DelACK** : agressif en Gaming+MaxPerf, neutre en Gaming+ECO.

### ⚙️ Optimisations Granulaires

- **[1] Système** : Optimisation du noyau (Kernel), de la planification CPU et suppression de la télémétrie.
- **[2] Mémoire** : Ajustement de la gestion RAM pour éliminer les micro-saccades (stuttering).
- **[3] Disques** : Optimisation des accès I/O pour accélérer le chargement des jeux et logiciels.
- **[4] GPU** : Configuration des priorités graphiques et réduction du délai d'affichage (latency).
- **[5] Réseau** : Optimisation de la pile TCP/IP (BBR2 tous templates, TCP Pacing + ECN, Tcp1323Opts=3, DefaultTTL=64, TcpMaxDataRetransmissions=5, MSI cartes réseau + USB) et tuning fin de la carte réseau selon le profil (Eco : RSC/LSO/checksum ON, énergie préservée, InterruptModeration adaptatif ; MaxPerf : EEE/GreenGbe/PacketCoalescing OFF, RSC/LSO OFF en Gaming, ITR=200 en Gaming+MaxPerf, Rx/Tx buffers max).
- **[6] Input** : Optimisation de la fréquence d'interrogation pour une souris et un clavier plus réactifs.
- **[7] Énergie** : Gestion des plans d'alimentation et déblocage de l'Ultimate Performance, avec choix d'usage pour appliquer le bon tuning NIC.
- **[8] Sécurité** : Gestion des mitigations processeur (Spectre/Meltdown) pour regagner des cycles CPU, avec choix d'usage pour le mode Gaming/Normal.

### 🧰 Outils & Utilitaires

- **[N] Nettoyage Avancé** : Nettoyage système complet en 26 étapes (fichiers temporaires, caches W11, Widgets/Copilot/Recall, icônes, OneDrive, Defender, etc.).
- **[R] Point de Restauration** : Crée un point de restauration système avant toute modification.
- **[G] Gestion Windows** : Menu dédié (Defender, UAC, VBS/HVCI, Edge, OneDrive…).
- **[W] MAS** : Lien vers l'outil d'activation communautaire pour Windows et Office.
- **[T] WinUtil** : Accès à la boîte à outils de maintenance de Chris Titus Tech.
- **[Q] Quitter** : Ferme le script.

### 📂 Gestion Windows & Maintenance (Menu [G])

| Touche | Fonction | Description |
|:---:|---|---|
| **[1]** | **Windows Defender** | Activation ou désactivation complète de l'antivirus intégré. |
| **[2]** | **UAC** | Gestion fine des notifications du Contrôle de Compte Utilisateur. |
| **[3]** | **VBS / HVCI** | Gestion de l'Isolation du noyau (Memory Integrity) pour les FPS ou la compatibilité Anti-Cheat. **Mode Gaming (option 3)** : active VBS/HVCI/CFG (compatible Vanguard, FaceIT, Ricochet) tout en désactivant les mitigations CPU coûteuses (Spectre/Meltdown). |
| **[4]** | **Animations** | Choix entre une interface visuelle riche ou ultra-réactive. |
| **[5]** | **IA & Widgets** | Suppression de Copilot, Recall et des widgets Windows 11. |
| **[6]** | **OneDrive** | Désinstallation complète de OneDrive. |
| **[7]** | **Microsoft Edge** | Désinstallation complète de Microsoft Edge (WebView2 préservé). |
| **[8]** | **Runtimes** | Installation des bibliothèques essentielles (Visual C++ 2015-2022, DirectX). |
| **[9]** | **Bloatwares** | Suppression des apps préinstallées inutiles (News, Solitaire, Skype, etc.). |
| **[M]** | **Retour** | Retour au menu principal. |

---

## 🛡️ Sécurité & Fiabilité

- **Compatible Anti-Cheat** : Le script propose une configuration optimisée qui maintient l'intégrité du système (**HVCI** et **CFG**) requise par les anti-cheats modernes tels que **Vanguard**, **FaceIT** et **Ricochet**.
- **Réversibilité** : Chaque modification est traçable. L'option **[R]** permet de créer un point de restauration instantané et les paramètres système peuvent être restaurés via les menus dédiés.
- **Transparence** : Script principal 100% ouvert et auditable. Les utilitaires optionnels inclus sont isolés dans `Tools\` et utilisés uniquement par les sections concernées.
- **Zéro perte de fonctions** : Les fonctionnalités vitales (Windows Update, Microsoft Store) restent opérationnelles. Les "Bloatwares" supprimés sont uniquement les apps préinstallées non-essentielles.
- **Edge/OneDrive optionnels** : Contrairement aux bloatwares, Edge et OneDrive sont conservés par défaut mais peuvent être désinstallés via le menu **[G] → [6]** (OneDrive) ou **[G] → [7]** (Edge).

---

## ❓ FAQ (Foire Aux Questions)

### 🏠 Installation & Sécurité

**Q : Est-ce que ce script va "casser" mon Windows ?**  
R : Non. Contrairement aux ISO modifiées, ce script n'altère pas les fichiers système. L'option **[R]** assure une sécurité totale en cas de besoin de retour en arrière.

**Q : Mon antivirus détecte le script, pourquoi ?**  
R : C'est un faux positif. Le script manipule des clés de registre système, ce qui est jugé "suspect" par certains moteurs, bien que les actions soient bénéfiques.

**Q : Puis-je lancer le script plusieurs fois ?**  
R : Oui, le script vérifie l'état actuel avant d'appliquer un changement. Le relancer après une mise à jour majeure de Windows est d'ailleurs recommandé.

### 🎮 Performance & Gaming

**Q : Quel gain de FPS puis-je espérer ?**  
R : Le gain varie selon votre matériel, mais vous constaterez surtout une meilleure stabilité du framerate (moins de drops) et une réponse plus instantanée de vos périphériques.

**Q : Pourquoi désactiver les mitigations Spectre/Meltdown (Option 8) ?**  
R : Ces protections ajoutent une charge au processeur. En les désactivant, on regagne de la performance brute, mais c'est une option réservée aux utilisateurs qui acceptent le risque de sécurité associé. L'option 8 désactive les mitigations CPU (Spectre/Meltdown, CI Policy) tout en conservant VBS/HVCI/CFG actifs pour la compatibilité anti-cheat.

**Q : Est-ce sûr pour le jeu en ligne ?**  
R : Absolument. Le script n'interfère jamais avec les fichiers de jeu. Pour les titres exigeants (Valorant/FaceIT/Ricochet), utilisez l'option **[3] Mode Gaming** dans le menu **[G] → VBS/HVCI** : VBS et HVCI restent activés (exigés par les anti-cheats) mais les mitigations CPU coûteuses sont désactivées pour libérer les performances.

### 🌐 Maintenance & Divers

**Q : Est-ce que le nettoyage (Option N) supprime mes documents ?**  
R : Absolument pas. Il cible uniquement les fichiers temporaires, caches de mises à jour et logs système qui encombrent votre disque.

**Q : Puis-je réinstaller OneDrive ou Edge plus tard ?**  
R : Oui, ils peuvent être réinstallés via le site officiel de Microsoft à tout moment.

**Q : Quels "Bloatwares" sont supprimés ?**  
R : Le script effectue un nettoyage ciblé pour supprimer les éléments publicitaires ou non-essentiels, tout en garantissant la stabilité du système.

#### 🗑️ Supprimé
| Catégorie | Applications |
| :--- | :--- |
| **Jeux & Pubs** | Candy Crush (Saga & Soda), Solitaire Collection. |
| **Social / Liens** | Skype, People, Microsoft Family, Your Phone (Lien avec le téléphone). |
| **Utilitaires** | Cartes (Maps), Feedback Hub, Get Help, Get Started, Mixed Reality Portal, Assistance rapide. |
| **Services** | Office Hub (Web stub), OneConnect (Forfaits mobiles), Bing News (Actualités). |

#### ✅ Conservé
| Catégorie | Applications |
| :--- | :--- |
| **Gaming** | Suite **Xbox** (Game Bar, App), DirectX, Game Mode. |
| **Quotidien** | Météo, Sports, Finances, Alarmes, Caméra, Enregistreur vocal. |
| **Multimédia** | Musique (Groove), Films et TV, Photos, Paint. |
| **Productivité** | Calculatrice, Bloc-notes, Courrier & Calendrier, Sticky Notes. |
| **Système** | Store, Sécurité Windows, Terminal, Capture. |

**Q : Combien de temps dure l'optimisation ?**  
R : Moins de 5 minutes selon les options choisies et la vitesse de votre matériel.
---

<div align="center">

**Développé avec passion par Kayler**  
*Optimisez votre expérience Windows dès aujourd'hui.*

[**📥 Télécharger All in One.cmd**](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd)

</div>
