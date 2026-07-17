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
- [🚀 Démarrage rapide](#-démarrage-rapide)
- [🛠️ Guide des fonctionnalités](#️-guide-des-fonctionnalités)
- [❓ FAQ (Foire aux questions)](#-faq-foire-aux-questions)

---

## 📖 À propos du projet

**Windows Optimizer** est un script d'automatisation professionnel conçu pour transformer une installation Windows standard en une station de travail ou de jeu haute performance. 

Ce script privilégie une configuration lisible et des profils explicites pour Windows 10 et 11. Le résultat dépend toutefois de la version de Windows, des pilotes, du matériel et des logiciels installés. Créez un point de restauration et lisez les avertissements avant les options sensibles (sécurité, Edge, OneDrive et nettoyage avancé).

---

## 🚀 Démarrage rapide

```powershell
irm "https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main/launcher.ps1" | iex
```
Collez cette commande dans **PowerShell non administrateur**. Le launcher valide la source officielle, demande l'élévation UAC, prépare le batch téléchargé puis le lance.

> `irm | iex` exécute le contenu distant actuel de la branche `main`. Relisez le dépôt et ses changements avant exécution si vous avez besoin d'une version figée et auditée.

### Premier parcours

1. Appuyez sur **[R]** pour créer un point de restauration.
2. Appuyez sur **[O]** pour le parcours complet.
3. Choisissez l'usage, l'énergie, puis les cinq choix complémentaires proposés : sécurité CPU, Defender, animations, fonctions IA et UAC.
4. Les sections sont ensuite exécutées une fois, sans nouvelle question hors contrôles et confirmations dédiés.
5. Un redémarrage est **recommandé** après un parcours complet et devient nécessaire lorsque Windows, un réglage de sécurité/pilote ou un installateur le signale.
6. **Comptez moins de 5 minutes en général**, plus selon le PC et la connexion.

---

## 🛠️ Guide des fonctionnalités

### 🌟 Système de Profils à 2 Axes (All-in-One [O])

L'option **[O] Tout optimiser** repose sur **deux axes indépendants** qui définissent 4 combinaisons possibles. Le script vous pose quelques questions (profil + options) et en déduit automatiquement la configuration demandée.

Le parcours automatique enchaîne ensuite les sections sans nouvelle question et affiche un résumé final. Les prérequis, téléchargements, installateurs et confirmations destructives conservent leurs contrôles dédiés.

Les sections granulaires reprennent la même logique, mais ne demandent que l'axe réellement utile : par exemple **Mémoire** demande l'énergie, **GPU/Système/Input** demandent l'usage et **Réseau** demande les deux. Le menu **Protections Sécurité** propose séparément trois niveaux explicites.

#### Axe 1 — Usage (`PROFIL_USAGE`)
> *Pilote la **latence applicative** : périphériques d'entrée, pile TCP, latence GPU.*

| Choix | Profil | Réglages clés |
|:---:|:---:|---|
| **[1]** | **GAMING** | Low Latency GPU (MaxFrameLatency=1), VRR OFF, Auto HDR OFF, Nagle/DelACK OFF per-interface, initialRTO=3000 et maxsynretransmissions=2 (= valeurs Windows documentées), Tcp1323Opts=3, BBR2 sur les 5 templates compatibles, TCP Pacing + ECN, heuristics WSH/forcews demandés actifs, RssBaseCpu=1, QoS Fortnite DSCP 46, DisablePagefileEncryption, accélération souris OFF, Win8 Scaling. En MaxPerf : RSC/LSO et Interrupt Moderation OFF, ITR=200, Rx/Tx buffers jusqu'à 2048 selon le pilote. En Eco : Nagle/DelACK natifs, RSC/LSO ON. |
| **[2]** | **NORMAL** | Tcp1323Opts=3, BBR2 sur les 5 templates compatibles, TCP Pacing + ECN, heuristics WSH/forcews demandés actifs, initialRTO=3000 et maxsynretransmissions=2 (= valeurs Windows documentées), VRR ON, veille GPU préservée, Nagle/DelACK natifs, SystemResponsiveness=20, accélération trackpad légère sur portable. Si les ressources NVIDIA compatibles sont présentes localement, le script tente aussi de restaurer de façon ciblée les valeurs modifiées par son preset Gaming. |

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

| Combinaison | Comportement principal |
|---|---|
| **Gaming + MaxPerf** | Réglages de latence les plus agressifs : Nagle/DelACK, RSC/LSO et Interrupt Moderation coupés, ITR=200 lorsque le pilote le permet. |
| **Gaming + Eco** | Réglages gaming GPU/input, mais comportement réseau natif pour Nagle/DelACK et offloads conservés afin de privilégier autonomie et stabilité. |
| **Normal + MaxPerf** | Plan et énergie MaxPerf sans les réglages réseau gaming agressifs ; RSC/LSO et propriétés de latence exclusives sont restaurés. |
| **Normal + Eco** | Configuration la plus conservatrice : comportement réseau natif, gestion d'énergie active et plan Équilibré. |

#### Règle d'attribution (design interne)
Chaque réglage est principalement piloté par **un seul axe**, sauf les exceptions explicites ci-dessous :
- **Latence applicative** (input, I/O, stack TCP Nagle/timers, low-latency GPU) → `PROFIL_USAGE`
- **Énergie / tuning NIC / plan d'alimentation** → `PROFIL_POWER`

Exceptions réseau :
- **RSC/LSO/RscIPv6** : coupés uniquement en **GAMING + MAX PERF** (préservent débit/stabilité en Normal/Eco).
- **initialRTO / maxsynretransmissions** : 3000 ms / 2 pour tous les profils, soit les valeurs Windows documentées pour l'établissement TCP (SYN) ; initialRTO ne règle pas le RTO des paquets après connexion.
- **BBR2 / heuristics** : BBR2 est demandé sur Internet, InternetCustom, Datacenter, DatacenterCustom et Compat avec `wsh=enabled forcews=enabled`. Le correctif loopback IPv4/IPv6 (`loopbacklargemtu=disabled`) est appliqué dans la même section pour préserver les applications locales comme Steam, Battle.net et Hyper-V.
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

- **[N] Nettoyage Avancé** : Nettoyage système en 26 étapes : temporaires, corbeille, dumps, caches Windows/applications, journaux archivés, npm, OneDrive/Defender et autres diagnostics. `Windows.old` n'est supprimé qu'après une confirmation séparée.
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
| **[4]** | **IA & Widgets** | Activation ou désactivation de Copilot et des Widgets sur Windows 11. Recall dépend de la version/édition de Windows et peut être absent ou non pris en charge. |
| **[5]** | **OneDrive** | Désinstallation complète, arrêt de la synchronisation et suppression des dossiers OneDrive restants, dont `%USERPROFILE%\OneDrive`. |
| **[6]** | **Microsoft Edge** | Désinstallation de Microsoft Edge avec WebView2 préservé. Recherche, Widgets, météo et certaines PWA peuvent être affectés. |
| **[7]** | **Runtimes** | Installation du Visual C++ v14 actuel et de DirectX June 2010. |
| **[8]** | **Bloatwares** | Suppression des apps préinstallées inutiles (News, Solitaire, Skype, etc.). |
| **[M]** | **Retour** | Retour au menu principal. |

> **Note** : la gestion des protections sécurité (VBS/HVCI, CFG, Credential Guard et mitigations CPU) se trouve dans le menu principal sous **[8] Protections Securite**. Le script indique **Gaming** comme choix recommandé ; Défaut Windows active VBS/HVCI/CFG, configure l'hyperviseur sur Auto, restaure les mitigations CPU Microsoft et laisse LSA/Credential Guard non configurés afin que Windows ou les stratégies de l'organisation décident selon l'édition, l'appartenance à une entreprise et le matériel. Performance Max réduit davantage la sécurité.

## ❓ FAQ (Foire aux questions)

### 🏠 Installation & Sécurité

**Q : Est-ce que ce script peut provoquer une incompatibilité ?**
R : Oui, comme tout outil qui modifie des stratégies, services, pilotes ou paramètres réseau. Créez d'abord un point de restauration, choisissez le profil Normal/Eco en cas de doute et évitez les options de sécurité ou de désinstallation dont vous n'avez pas besoin.

**Q : Mon antivirus détecte le script, pourquoi ?**  
R : Les commandes d'administration, les téléchargements et les modifications de sécurité peuvent déclencher une alerte. Ne supposez pas automatiquement qu'il s'agit d'un faux positif : vérifiez le dépôt, le diff et les fichiers téléchargés avant exécution.

**Q : Puis-je lancer le script plusieurs fois ?**  
R : Oui pour les profils principaux : Gaming/Normal et Performance Max/Eco remplacent leurs réglages exclusifs et nettoient plusieurs vestiges connus. Un parcours **Tout optimiser** n'exécute chaque section qu'une fois, mais vous pouvez relancer ensuite une section depuis le menu. Les suppressions, désinstallations, caches et autres actions destructives ne sont pas toutes répétables ni réversibles. Un point de restauration ne récupère pas nécessairement les fichiers supprimés, les désinstallations, la corbeille, les caches ou `Windows.old`.

### 🎮 Performance & Gaming

**Q : Quel gain de FPS puis-je espérer ?**  
R : Le gain varie selon le matériel et la charge. Il peut surtout se manifester par une latence ou une stabilité plus régulière ; aucun gain de FPS n'est garanti.

**Q : Pourquoi modifier les mitigations Spectre/Meltdown (Option 8) ?**
R : Certaines protections ajoutent une charge selon le processeur et la charge de travail. Le mode Gaming conserve VBS/HVCI/CFG mais désactive SEHOP, réduit des mitigations CPU et demande la désactivation des configurations locales Credential Guard/LSA ; Performance Max conserve VBS/CFG mais désactive HVCI/SEHOP et réduit davantage les protections. Défaut Windows restaure VBS/HVCI, rend LSA et Credential Guard à Windows ou aux stratégies de l'organisation, supprime les surcharges SEHOP et blocklist, restaure les mitigations CPU Microsoft (`FeatureSettingsOverride=0`, masque `3`), force CFG actif et configure l'hyperviseur sur Auto.

**Q : Pourquoi Performance Max ne désactive-t-il pas toutes les protections ?**
R : Il vise des performances régulières, pas toutes les valeurs à zéro. VBS reste actif pour éviter certaines régressions ; CFG reste actif car son coût est faible. HVCI et SEHOP sont désactivés, les mitigations CPU coûteuses sont réduites et les configurations locales Credential Guard/LSA sont retirées. Une stratégie ou un verrou UEFI peut toutefois les maintenir actives. Le lancement de l'hyperviseur reste configuré sur Auto.

Une ancienne version ayant activé Credential Guard avec verrou UEFI peut nécessiter la procédure Microsoft avec confirmation physique pour retirer ce verrou ; une écriture registre seule ne peut pas garantir sa suppression.

**Q : Quelle différence entre Gaming et Performance Max pour les anti-cheats ?**
R : Gaming conserve VBS/HVCI/CFG pour Valorant et FACEIT. Performance Max coupe HVCI et peut donc être refusé si l'anti-cheat exige Memory Integrity. TPM, Secure Boot, la virtualisation et parfois IOMMU restent à activer dans le BIOS.

**Q : Est-ce compatible avec tous les jeux en ligne ?**
R : Aucune compatibilité universelle ne peut être garantie. Le mode Gaming conserve VBS/HVCI/CFG pour limiter les conflits avec les anti-cheats modernes, mais désactive SEHOP — sans garantir les exigences futures de chaque jeu ou anti-cheat.

### 🌐 Maintenance & Divers

**Q : Est-ce que le nettoyage (Option N) supprime mes documents ?**  
R : Il ne cible pas directement les dossiers Documents/Images/Vidéos actuels. Il vide toutefois la corbeille et supprime des caches, dumps, rapports d'erreur et journaux archivés. Si `Windows.old` existe, sa suppression définitive est proposée séparément et peut inclure d'anciennes données utilisateur. Les journaux Event Viewer actifs, l'historique Windows Update et les autres fichiers de récupération sont conservés.

**Q : Puis-je réinstaller OneDrive ou Edge plus tard ?**  
R : Oui, les deux sont réinstallables. OneDrive se réinstalle via `winget install Microsoft.OneDrive` ou depuis le site Microsoft. Edge aussi (`winget install Microsoft.Edge` ou microsoft.com/edge) — les politiques de blocage posées par le script empêchent uniquement la réinstallation automatique par Windows Update, pas une installation manuelle. Les données utilisateur (favoris Edge, dossier OneDrive) supprimées lors de la désinstallation ne sont toutefois pas récupérables.

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

**Q : Dois-je redémarrer après l'optimisation ?**
R : Un redémarrage est recommandé après un parcours complet. Il est nécessaire si le script, Windows ou un installateur le signale, notamment pour certains changements VBS/HVCI/SEHOP, pilotes, alimentation ou codes installateur `3010`/`1641`.

### 🛡️ Sécurité & fiabilité

**Q : Comment les téléchargements distants sont-ils vérifiés ?**
R : `irm | iex`, MAS et WinUtil utilisent du contenu distant susceptible d'évoluer. Le launcher contrôle l'hôte, le format et la structure minimale du batch, mais n'utilise pas de hash ou de signature embarquée. Visual C++ et DirectX sont contrôlés par taille et signature Authenticode Microsoft avant exécution. Les outils du dépôt (NVIDIA Profile Inspector, SetTimerResolution) sont contrôlés surtout par chemin, taille et compatibilité, sans validation Authenticode systématique.

**Q : Certains outils sont-ils exécutés automatiquement ?**
R : NVIDIA Profile Inspector et son profil peuvent être exécutés automatiquement en Gaming sur un GPU NVIDIA compatible. SetTimerResolution peut être installé, ajouté au démarrage et lancé en MaxPerf. La configuration O&O, les modèles de `Game Configs\` et les autres outils Timer & Interrupt ne sont pas lancés automatiquement par le batch actuel.

**Q : Credential Guard et LSA peuvent-ils rester actifs malgré le script ?**
R : Les profils demandent la suppression ou l'application de configurations locales, mais une stratégie d'entreprise ou un verrou UEFI peut conserver une protection active malgré les changements de registre.

**Q : Quelles fonctionnalités essentielles sont conservées ?**
R : Windows Update, Microsoft Store et WebView2 ne sont pas volontairement supprimés. Les fonctions dépendantes d'Edge, OneDrive ou d'une autre application retirée peuvent néanmoins changer.

---

<div align="center">

**Développé avec passion par Kayler**  
*Optimisez votre expérience Windows dès aujourd'hui.*

[**📥 Télécharger All in One.cmd**](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd)

</div>
