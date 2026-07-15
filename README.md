<div align="center">

# WINDOWS OPTIMIZER

### 🚀 Le script ultime d'optimisation pour Windows 10 & 11
*Maximisez vos performances, réduisez votre latence et reprenez le contrôle sur votre système.*

[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-2026.07-orange?style=for-the-badge)](https://github.com/kaylerberserk/WindowsOptimizer)
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

Ce script privilégie une configuration lisible et des profils explicites pour Windows 10 et 11. Le résultat dépend toutefois de la version de Windows, des pilotes, du matériel et des logiciels installés. Créez un point de restauration et lisez les avertissements avant les options sensibles (sécurité, Edge, OneDrive et nettoyage avancé).

---

## 🚀 Démarrage rapide

### Option A — PowerShell (recommandé)
```powershell
irm "https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main/launcher.ps1" | iex
```
Collez cette commande dans **PowerShell (non-admin)** — elle utilise toujours la version présente sur la branche `main`, s'élève automatiquement en administrateur et lance le script.

### Option B — Téléchargement manuel
1. **Téléchargement** : Accédez au fichier [**All in One.cmd**](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd) et cliquez sur le bouton **Download**.
2. **Exécution** : Clic droit sur le fichier → **Exécuter en tant qu'administrateur**.
3. **Sécurité** : Appuyez sur **[R]** pour créer un point de restauration avant toute modification.
4. **Optimisation** : Appuyez sur **[O]** pour tout optimiser d'un coup. Le script vous pose quelques questions (usage, énergie, options) et applique automatiquement le profil correspondant.
5. **Redémarrage** : Un redémarrage est nécessaire pour appliquer l'ensemble des changements.

---

## 🛠️ Guide des Fonctionnalités

### 🌟 Système de Profils à 2 Axes (All-in-One [O])

L'option **[O] Tout optimiser** repose sur **deux axes indépendants** qui définissent 4 combinaisons possibles. Le script vous pose quelques questions (profil + options) et en déduit automatiquement la configuration demandée.

Les sections granulaires reprennent la même logique, mais ne demandent que l'axe réellement utile : par exemple **Mémoire** demande l'énergie, **GPU/Système/Input** demandent l'usage et **Réseau** demande les deux. Le menu **Protections Sécurité** propose séparément trois niveaux explicites.

#### Axe 1 — Usage (`PROFIL_USAGE`)
> *Pilote la **latence applicative** : périphériques d'entrée, pile TCP, latence GPU.*

| Choix | Profil | Réglages clés |
|:---:|:---:|---|
| **[1]** | **GAMING** | Low Latency GPU (MaxFrameLatency=1), VRR OFF, Auto HDR OFF, Nagle/DelACK OFF per-interface, initialRTO=3000 et maxsynretransmissions=2 (= valeurs Windows documentées), Tcp1323Opts=3, BBR2 sur les 5 templates compatibles, TCP Pacing + ECN, heuristics WSH/forcews demandés actifs, RssBaseCpu=1, QoS Fortnite DSCP 46, DisablePagefileEncryption, accélération souris OFF, Win8 Scaling. En MaxPerf : RSC/LSO et Interrupt Moderation OFF, ITR=200, Rx/Tx buffers jusqu'à 2048 selon le pilote. En Eco : Nagle/DelACK natifs, RSC/LSO ON. |
| **[2]** | **NORMAL** | Tcp1323Opts=3, BBR2 sur les 5 templates compatibles, TCP Pacing + ECN, heuristics WSH/forcews demandés actifs, initialRTO=3000 et maxsynretransmissions=2 (= valeurs Windows documentées), VRR ON, veille GPU préservée, valeurs NVIDIA du preset Gaming restaurées de façon ciblée, Nagle/DelACK natifs, SystemResponsiveness=20, accélération trackpad légère sur portable. |

#### Axe 2 — Énergie (`PROFIL_POWER`)
> *Pilote **l'énergie, le niveau de tuning NIC et le plan d'alimentation**.*

| Choix | Profil | Réglages clés |
|:---:|:---:|---|
| **[1]** | **ECO** | Plan Équilibré (plans OEM/personnalisés conservés), RSC/LSO/checksum ON, gestion d'énergie NIC activée, propriétés pilote modifiées par MaxPerf restaurées, compression mémoire active, MSI USB actif. |
| **[2]** | **MAX PERF** | Plan Ultimate Performance, RSC/LSO et Interrupt Moderation OFF en Gaming (restaurés en Normal/Eco), RscIPv6 OFF en Gaming+MaxPerf, Flow Control OFF, ITR=200 en Gaming, EEE/GigaLite/GreenGbe/PacketCoalescing OFF, Power Management NIC OFF, ReceiveBuffers/TransmitBuffers jusqu'à 2048 selon le pilote, gestion énergie USB désactivée (selective suspend + USB 3 LPM), compression mémoire OFF (RAM > 8 Go), MSI USB actif, économies d'énergie coupées. |

> **Sur PC fixe comme portable** : les deux questions sont posées, pour permettre un desktop silencieux/économe ou un laptop branché en **MAX PERF**.
> **Sur PC portable** : la combinaison **GAMING + ECO** est autorisée avec un avertissement — Nagle/DelACK revient au comportement Windows natif (batterie avant tout), tandis qu'initialRTO=3000 et maxsynretransmissions=2 restent aux valeurs Windows documentées ; les optimisations GPU/input/CPU restent agressives.
>
> Les quatre combinaisons sont convergentes : changer de profil annule explicitement les réglages exclusifs laissés par le profil précédent.


#### Règle d'attribution (design interne)
Chaque réglage est principalement piloté par **un seul axe**, sauf les exceptions explicites ci-dessous :
- **Latence applicative** (input, I/O, stack TCP Nagle/timers, low-latency GPU) → `PROFIL_USAGE`
- **Énergie / tuning NIC / plan d'alimentation** → `PROFIL_POWER`

Exceptions réseau :
- **RSC/LSO/RscIPv6** : coupés uniquement en **GAMING + MAX PERF** (préservent débit/stabilité en Normal/Eco).
- **initialRTO / maxsynretransmissions** : 3000 ms / 2 pour tous les profils, soit les valeurs Windows documentées pour l'établissement TCP (SYN) ; initialRTO ne règle pas le RTO des paquets après connexion.
- **BBR2 / heuristics** : BBR2 est appliqué à Internet, InternetCustom, Datacenter, DatacenterCustom et Compat. Le script demande `wsh=enabled forcews=enabled` ; les versions récentes de Windows peuvent accepter la commande tout en continuant d'afficher WSH legacy comme désactivé.
- **Nagle/DelACK** : agressif en Gaming+MaxPerf, natif Windows en Eco et en Normal+MaxPerf.

### ⚙️ Optimisations Granulaires

- **[1] Système** : Optimisation du noyau (Kernel), de la planification CPU et suppression de la télémétrie.
- **[2] Mémoire** : Ajustement de la gestion RAM et de la compression mémoire selon le profil d'énergie.
- **[3] Disques** : TRIM et maintenance Windows conservés, chemins longs activés.
- **[4] GPU** : Configuration des priorités graphiques et des options de latence prises en charge par le pilote.
- **[5] Réseau** : Optimisation de la pile TCP/IP (TCP Pacing + ECN, TcpMaxDataRetransmissions=5, MSI cartes réseau) et tuning fin de la carte réseau selon le profil (Eco : RSC/LSO/checksum ON, énergie préservée, Interrupt Moderation restaurée ; MaxPerf : EEE/GreenGbe/PacketCoalescing OFF, RSC/LSO et Interrupt Moderation OFF en Gaming, ITR=200 en Gaming+MaxPerf, Rx/Tx buffers jusqu'à 2048 selon le pilote).
- **[6] Input** : Ajustement de la réponse clavier/souris, des files d'entrée et du mode MSI des contrôleurs compatibles.
- **[7] Énergie** : Gestion des plans d'alimentation et déblocage de l'Ultimate Performance, avec choix d'usage pour appliquer le bon tuning NIC.
- **[8] Sécurité** : Choix entre Défaut Windows, Gaming et Performance Max pour VBS/HVCI, CFG, mitigations processeur et liste de pilotes vulnérables.

### 🧰 Outils & Utilitaires

- **[N] Nettoyage Avancé** : Nettoyage système complet en 26 étapes (fichiers temporaires, caches W11, Widgets/Copilot/Recall, icônes, OneDrive, Defender, etc.).
- **[R] Point de Restauration** : Crée un point de restauration système avant toute modification.
- **[G] Gestion Windows** : Menu dédié (Defender, UAC, animations, IA/Widgets, Edge, OneDrive…).
- **[W] MAS** : Lance le script officiel MAS depuis son URL de mise à jour continue. À utiliser dans le respect des licences Windows/Office.
- **[T] WinUtil** : Lance la dernière version officielle disponible de WinUtil.
- **[Q] Quitter** : Ferme le script.

### 📂 Gestion Windows & Maintenance (Menu [G])

| Touche | Fonction | Description |
|:---:|---|---|
| **[1]** | **Windows Defender** | Activation ou désactivation étendue de Defender (temps réel, cloud, ASR, SmartScreen, services et pilotes associés). |
| **[2]** | **UAC** | Gestion fine des notifications du Contrôle de Compte Utilisateur. |
| **[3]** | **Animations** | Choix entre une interface visuelle riche ou ultra-réactive. |
| **[4]** | **IA & Widgets** | Activation ou désactivation de Copilot, Recall et des Widgets Windows 11. |
| **[5]** | **OneDrive** | Désinstallation complète de OneDrive. |
| **[6]** | **Microsoft Edge** | Désinstallation complète de Microsoft Edge (WebView2 préservé). |
| **[7]** | **Runtimes** | Installation du Visual C++ v14 actuel et de DirectX June 2010. |
| **[8]** | **Bloatwares** | Suppression des apps préinstallées inutiles (News, Solitaire, Skype, etc.). |
| **[M]** | **Retour** | Retour au menu principal. |

> **Note** : la gestion des protections sécurité (VBS/HVCI, CFG, Credential Guard et mitigations CPU) se trouve dans le menu principal sous **[8] Protections Securite**. Le script indique **Gaming** comme choix recommandé ; Défaut Windows active VBS/HVCI/CFG, configure l'hyperviseur sur Auto, restaure les mitigations CPU Microsoft et laisse LSA/Credential Guard non configurés afin que Windows ou les stratégies de l'organisation décident selon l'édition, l'appartenance à une entreprise et le matériel. Performance Max réduit davantage la sécurité.

---

## 🛡️ Sécurité & Fiabilité

- **Mode Gaming orienté anti-cheat** : ce mode conserve **VBS/HVCI** et **CFG** afin de limiter les incompatibilités, sans garantir les exigences futures de chaque jeu ou anti-cheat.
- **Réversibilité** : L'option **[R]** crée un point de restauration et plusieurs menus proposent un retour aux valeurs Windows. Certains choix destructifs (données OneDrive/Edge, bloatwares, caches et journaux) ne sont pas annulés automatiquement.
- **Transparence** : le script principal est ouvert et auditable. MAS et WinUtil utilisent leurs liens officiels continuellement mis à jour ; leur contenu peut donc évoluer entre deux exécutions. Les installateurs Microsoft téléchargés sont contrôlés par signature Authenticode. Certains fichiers de `Tools\` et `Game Configs\` sont des ressources ou modèles archivés et ne sont pas invoqués automatiquement.
- **Fonctions essentielles préservées** : Windows Update, Microsoft Store et WebView2 ne sont pas volontairement supprimés. Les fonctions dépendantes d'une application retirée peuvent néanmoins changer.
- **Edge/OneDrive optionnels** : Contrairement aux bloatwares, Edge et OneDrive sont conservés par défaut mais peuvent être désinstallés via le menu **[G] → [5]** (OneDrive) ou **[G] → [6]** (Edge).

---

## ❓ FAQ (Foire Aux Questions)

### 🏠 Installation & Sécurité

**Q : Est-ce que ce script peut provoquer une incompatibilité ?**
R : Oui, comme tout outil qui modifie des stratégies, services, pilotes ou paramètres réseau. Créez d'abord un point de restauration, choisissez le profil Normal/Eco en cas de doute et évitez les options de sécurité ou de désinstallation dont vous n'avez pas besoin.

**Q : Mon antivirus détecte le script, pourquoi ?**  
R : Les commandes d'administration, les téléchargements et les modifications de sécurité peuvent déclencher une alerte. Ne supposez pas automatiquement qu'il s'agit d'un faux positif : vérifiez le dépôt, le diff et les fichiers téléchargés avant exécution.

**Q : Puis-je lancer le script plusieurs fois ?**  
R : Oui pour les profils principaux : Gaming/Normal et Performance Max/Eco remplacent leurs anciens réglages exclusifs, nettoient les vestiges connus des anciennes versions et évitent les doubles passages dans Tout optimiser. Les actions destructives ou hors profil ne sont toutefois pas toutes répétables ni réversibles ; relisez le résumé et les confirmations à chaque exécution.

### 🎮 Performance & Gaming

**Q : Quel gain de FPS puis-je espérer ?**  
R : Le gain varie selon le matériel et la charge. Il peut surtout se manifester par une latence ou une stabilité plus régulière ; aucun gain de FPS n'est garanti.

**Q : Pourquoi modifier les mitigations Spectre/Meltdown (Option 8) ?**
R : Certaines protections ajoutent une charge selon le processeur et la charge de travail. Le mode Gaming conserve VBS/HVCI/CFG mais désactive SEHOP et réduit des mitigations CPU et Credential Guard ; Performance Max conserve VBS/CFG mais désactive HVCI/SEHOP et réduit davantage les protections. Défaut Windows restaure VBS/HVCI, rend LSA et Credential Guard à Windows, supprime les surcharges SEHOP et blocklist, restaure les mitigations CPU Microsoft (`FeatureSettingsOverride=0`, masque `3`), force CFG actif et configure l'hyperviseur sur Auto.

**Q : Pourquoi Performance Max ne désactive-t-il pas toutes les protections ?**
R : Il vise des performances régulières, pas toutes les valeurs à zéro. VBS reste actif pour éviter certaines régressions ; CFG reste actif car son coût est faible. HVCI, SEHOP, Credential Guard et les mitigations CPU coûteuses sont désactivés, tandis que le lancement de l'hyperviseur est explicitement configuré sur Auto.

Une ancienne version ayant activé Credential Guard avec verrou UEFI peut nécessiter la procédure Microsoft avec confirmation physique pour retirer ce verrou ; une écriture registre seule ne peut pas garantir sa suppression.

**Q : Quelle différence entre Gaming et Performance Max pour les anti-cheats ?**
R : Gaming conserve VBS/HVCI/CFG pour Valorant et FACEIT. Performance Max coupe HVCI et peut donc être refusé si l'anti-cheat exige Memory Integrity. TPM, Secure Boot, la virtualisation et parfois IOMMU restent à activer dans le BIOS.

**Q : Est-ce compatible avec tous les jeux en ligne ?**
R : Aucune compatibilité universelle ne peut être garantie. Le mode Gaming conserve VBS/HVCI/CFG pour limiter les conflits avec les anti-cheats modernes, mais désactive SEHOP ; chaque jeu et chaque politique de sécurité peuvent évoluer.

### 🌐 Maintenance & Divers

**Q : Est-ce que le nettoyage (Option N) supprime mes documents ?**  
R : Il ne cible pas les dossiers Documents/Images/Vidéos. Il vide toutefois la corbeille, des caches, des dumps et d'anciens journaux de diagnostic. Les journaux Event Viewer actifs, l'historique Windows Update et les fichiers de récupération sont conservés.

**Q : Puis-je réinstaller OneDrive ou Edge plus tard ?**  
R : OneDrive peut être réinstallé depuis Microsoft. Pour Edge, retirez d'abord les valeurs `InstallDefault` et `Install{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}` sous `HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate` si la stratégie de blocage est active, puis utilisez l'installateur Microsoft.

**Q : Quels "Bloatwares" sont supprimés ?**  
R : Le script cible une liste explicite d'applications préinstallées non essentielles et vérifie leur suppression. Leur absence peut néanmoins modifier certaines intégrations Windows.

#### 🗑️ Supprimé
| Catégorie | Applications |
| :--- | :--- |
| **Jeux & Pubs** | Candy Crush (Saga & Soda), Solitaire Collection. |
| **Social / Liens** | Skype, People, Microsoft Family. |
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
R : Les sections principales prennent généralement quelques minutes. Le nettoyage DISM, les téléchargements de runtimes et les installateurs peuvent durer nettement plus longtemps selon le PC et la connexion.
---

<div align="center">

**Développé avec passion par Kayler**  
*Optimisez votre expérience Windows dès aujourd'hui.*

[**📥 Télécharger All in One.cmd**](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd)

</div>
