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
irm "https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/238d9d3d0ad4097c316052b3ec1cdf18b02dec1d/launcher.ps1" | iex
```
Collez cette commande dans **PowerShell non administrateur**. Le launcher valide la source officielle, demande l'élévation UAC, prépare le batch téléchargé puis le lance.

> Le bootstrap est épinglé sur un commit Git immuable. Lors d'une nouvelle publication, remplacez volontairement le SHA dans cette commande et dans `launcher.ps1` après audit du contenu.

### Premier parcours

1. Appuyez sur **[R]** pour créer un point de restauration.
2. Appuyez sur **[O]** pour le parcours complet.
3. Choisissez l'usage, l'énergie, puis les cinq choix complémentaires proposés : protections Windows, Defender, animations, fonctions IA et UAC.
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
| **[1]** | **GAMING** | Low Latency GPU (MaxFrameLatency=1), VRR OFF, Auto HDR OFF, Nagle/DelACK OFF per-interface, initialRTO=3000 et maxsynretransmissions=2 (= valeurs Windows documentées), Tcp1323Opts=3, BBR2 sur les 5 templates compatibles, TCP Pacing + ECN, heuristics WSH/forcews demandés actifs, RssBaseCpu=1, QoS Fortnite DSCP 46, DisablePagefileEncryption, accélération souris OFF, Win8 Scaling. En MaxPerf : RSC/LSO OFF, Interrupt Moderation ON avec délais pilote au minimum annoncé, Rx/Tx buffers jusqu'à 2048 selon le pilote. En Eco : Nagle/DelACK natifs, RSC/LSO ON. |
| **[2]** | **NORMAL** | Tcp1323Opts=3, BBR2 sur les 5 templates compatibles, TCP Pacing + ECN, heuristics WSH/forcews demandés actifs, initialRTO=3000 et maxsynretransmissions=2 (= valeurs Windows documentées), VRR ON, veille GPU préservée, Nagle/DelACK natifs, SystemResponsiveness=20, accélération trackpad légère sur portable. Si les ressources NVIDIA compatibles sont présentes localement, le script tente aussi de restaurer de façon ciblée les valeurs modifiées par son preset Gaming. |

#### Axe 2 — Énergie (`PROFIL_POWER`)
> *Pilote **l'énergie, le niveau de tuning NIC et le plan d'alimentation**.*

| Choix | Profil | Réglages clés |
|:---:|:---:|---|
| **[1]** | **ECO** | Plan Équilibré (plans OEM/personnalisés conservés), RSC/LSO/checksum ON, gestion d'énergie NIC activée, propriétés pilote modifiées par MaxPerf restaurées, ARP Offload / NS Offload ON et Wake on Pattern OFF si pris en charge, compression mémoire active, MSI USB actif. |
| **[2]** | **MAX PERF** | Plan Ultimate Performance, RSC/LSO OFF en Gaming (restaurés en Normal/Eco), Interrupt Moderation ON avec délais pilote au minimum annoncé en Gaming, RscIPv6 OFF en Gaming+MaxPerf, Flow Control OFF, EEE/GigaLite/GreenGbe/PacketCoalescing OFF, ARP Offload / NS Offload / Wake on Pattern OFF si pris en charge, Power Management NIC OFF, ReceiveBuffers/TransmitBuffers jusqu'à 2048 selon le pilote, gestion énergie HID/USB désactivée sans forçage global ACPI/PCI, preset timer expérimental (`disabledynamictick=yes`, `useplatformtick=no`, HPET désactivé), compression mémoire OFF (RAM > 8 Go), MSI USB actif, économies d'énergie ciblées. |

> **Sur PC fixe comme portable** : les deux questions sont posées, pour permettre un desktop silencieux/économe ou un laptop branché en **MAX PERF**.
> **Sur PC portable** : la combinaison **GAMING + ECO** est autorisée avec un avertissement — Nagle/DelACK revient au comportement Windows natif (batterie avant tout), tandis qu'initialRTO=3000 et maxsynretransmissions=2 restent aux valeurs Windows documentées ; les optimisations GPU/input/CPU restent agressives.
>
> Les quatre combinaisons sont convergentes : changer de profil annule explicitement les réglages exclusifs laissés par le profil précédent.

| Combinaison | Comportement principal |
|---|---|
| **Gaming + MaxPerf** | Réglages de latence les plus agressifs : Nagle/DelACK et RSC/LSO coupés, Interrupt Moderation active avec les délais exposés réglés au minimum annoncé par le pilote. Sur Realtek, le script applique aussi le niveau `Low` et l'intervalle `0` définis par l'INF du pilote. |
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
- **[5] Réseau** : Optimisation de la pile TCP/IP (TCP Pacing + ECN, TcpMaxDataRetransmissions=5, MSI cartes réseau) et tuning fin de la carte réseau selon le profil (Eco : RSC/LSO/checksum, Interrupt Moderation et ARP/NS Offload ON ; MaxPerf : EEE/GreenGbe/PacketCoalescing et ARP/NS Offload OFF, RSC/LSO OFF en Gaming, délais pilote au minimum annoncé, Rx/Tx buffers jusqu'à 2048 selon le pilote).
- **[6] Input** : Ajustement de la réponse clavier/souris, des files d'entrée et du mode MSI des contrôleurs compatibles.
- **[7] Énergie** : Gestion des plans d'alimentation et déblocage de l'Ultimate Performance, avec choix d'usage pour appliquer le bon tuning NIC.
- **[8] Sécurité** : Choix entre 3 modes pour VBS/HVCI/CFG/SEHOP, mitigations processeur, LSA/Credential Guard, hyperviseur BCD et liste de pilotes vulnérables.

| Mode | Sécurité VBS / HVCI | Anti-Cheats (Valorant / FACEIT) | Usage Recommandé |
| :--- | :---: | :---: | :--- |
| **1 - Défaut Windows** | ✅ Selon l'état Windows | ✅ Compatible | Snapshot restauré ; sinon overrides de l'outil retirés |
| **2 - Gaming (Recommandé) ★** | ✅ Activé | ✅ Compatibilité élevée | Équilibre performances / sécurité pour tous types de jeux |
| **3 - Performance Max ⚠️** | ❌ Désactivé | ⚠️ Selon les jeux | Gain maximal pour les machines dédiées exclusivement à la performance brute |

> ### 💡 Vue d'ensemble des 3 modes
>
> * **Gaming (Recommandé ★)** : Conserve **VBS / HVCI** et **LSA Protection** (`RunAsPPL=2` sans verrou UEFI) pour limiter les conflits avec les anti-cheats modernes, laisse **CFG** à `NOTSET` (défaut Windows), désactive **SEHOP**, réduit les mitigations CPU et demande la désactivation de la blocklist.
> * **Défaut Windows** : restaure le snapshot capturé avant un profil de sécurité. Sans snapshot, il retire uniquement les overrides gérés par l'outil et laisse Windows, les pilotes et les stratégies décider de l'état effectif.
> * **Performance Max ⚠️ (Déconseillé)** : Désactive VBS, HVCI et SEHOP, conserve CFG et **LSA Protection** (`RunAsPPL=2` sans verrou UEFI), réduit les mitigations CPU et demande la désactivation de la blocklist.

> ### 🔍 Notes & Précisions techniques
>
> * **Champs modifiés** : les modes *Gaming* et *Performance Max* modifient uniquement CFG et SEHOP dans `MitigationOptions` pour préserver les autres mitigations de processus. *Défaut Windows* restaure les valeurs capturées ou retire les overrides de l'outil lorsqu'aucun snapshot n'existe.
> * **Mitigations CPU (Spectre/Meltdown)** : `33554435/3` (0x2000003) correspond aux modes *Gaming* et *Perf Max*. Le mode *Défaut Windows* ne force plus `0/3` : il restaure l'état précédent ou laisse Windows gérer l'absence d'override.
> * **Blocklist de pilotes** : *Gaming* conserve HVCI actif. Si HVCI, Smart App Control ou le mode S restent actifs, Windows peut continuer d'imposer la blocklist même si la désactivation a été demandée.
> * **Application automatique** : dans **Tout optimiser**, la question *Protections Windows* applique directement les réglages *Défaut Windows* en usage Normal ou *Gaming* en usage Gaming. Elle ne demande pas de choisir un second mode de sécurité. *Performance Max* reste accessible séparément depuis le menu Sécurité.

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

**Q : Que fait le preset timer de Performance Max ?**
R : Performance Max applique `disabledynamictick=yes`, `useplatformtick=no`, supprime les éventuels overrides `useplatformclock`/`tscsyncpolicy` et désactive le périphérique HPET. Ce combo a produit un polling rate plus régulier dans MouseTester sur la configuration testée, mais Microsoft classe ces options BCD comme des réglages de débogage : le preset reste expérimental et aucun gain universel n'est garanti. Le profil Eco supprime les quatre overrides BCD et réactive HPET pour rendre la sélection des timers à Windows. Un redémarrage est nécessaire après le changement.

**Q : Pourquoi modifier les mitigations Spectre/Meltdown (Option 8) ?**
R : Certaines protections ajoutent une charge selon le processeur et la charge de travail. Gaming conserve VBS/HVCI, laisse CFG au défaut Windows, désactive SEHOP, réduit les mitigations CPU et demande la désactivation de la blocklist. HVCI peut néanmoins maintenir cette blocklist active. Performance Max désactive VBS/HVCI/SEHOP, laisse CFG au défaut Windows, réduit les mitigations CPU et demande aussi la désactivation de la blocklist. Défaut Windows restaure le snapshot de sécurité ou retire les overrides de l'outil sans imposer une valeur brute universelle. Les trois modes suppriment la surcharge BCD `hypervisorlaunchtype` lorsqu'ils la gèrent ; les stratégies et verrous externes restent prioritaires.

**Q : Changer plusieurs fois de mode de sécurité laisse-t-il les anciens réglages actifs ?**
R : Le premier passage Gaming ou Performance Max capture les valeurs ciblées et la valeur BCD avant modification. Défaut Windows réimporte ensuite ce snapshot de façon ciblée ; sans snapshot, il retire seulement les overrides connus de l'outil. Une stratégie d'entreprise ou un verrou UEFI peut cependant réimposer une valeur extérieure au script.

**Q : Performance Max désactive-t-il toutes les protections ?**
R : Non. Performance Max désactive VBS, HVCI, SEHOP et Credential Guard local/policy, laisse CFG à `NOTSET` (dont le défaut Windows effectif est ON), demande la désactivation de la blocklist, réduit les mitigations CPU, mais conserve LSA Protection avec `RunAsPPL=2` sans verrou UEFI et laisse les Kernel Shadow Stacks inchangées. Smart App Control, le mode S ou une stratégie peuvent maintenir la blocklist active. La valeur BCD `hypervisorlaunchtype` est supprimée (`deletevalue`). Une ancienne configuration Credential Guard verrouillée en UEFI peut nécessiter une procédure avec confirmation physique pour retirer ce verrou.

**Q : Quelle différence entre Gaming et Performance Max pour les anti-cheats ?**
R : Gaming conserve VBS/HVCI/CFG pour Valorant (CFG requis par Vanguard) et FACEIT. Performance Max désactive VBS/HVCI mais conserve CFG ; sa compatibilité dépend donc des exigences de chaque anti-cheat. TPM, Secure Boot, la virtualisation et parfois IOMMU restent à activer dans le BIOS.

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
R : Un redémarrage est recommandé après un parcours complet. Il est nécessaire si le script, Windows ou un installateur le signale, notamment pour certains changements VBS/HVCI/SEHOP, pilotes ou alimentation.

### 🛡️ Sécurité & fiabilité

**Q : Comment les téléchargements distants sont-ils vérifiés ?**
R : Le launcher exige désormais un commit SHA-1 complet du dépôt officiel au lieu d'une branche mutable. MAS et WinUtil restent des outils externes explicitement sélectionnés, limités à leurs deux URLs autorisées. Visual C++ et DirectX sont contrôlés par taille et signature Authenticode Microsoft avant exécution. Les outils du dépôt (NVIDIA Profile Inspector, SetTimerResolution) sont contrôlés surtout par chemin, taille et compatibilité, sans validation Authenticode systématique.

**Q : Certains outils sont-ils exécutés automatiquement ?**
R : NVIDIA Profile Inspector et son profil peuvent être exécutés automatiquement en Gaming sur un GPU NVIDIA compatible. SetTimerResolution peut être installé, ajouté au démarrage et lancé en MaxPerf. La configuration O&O, les modèles de `Game Configs\` et les autres outils Timer & Interrupt ne sont pas lancés automatiquement par le batch actuel.

**Q : Credential Guard et LSA peuvent-ils rester actifs malgré le script ?**
R : Oui, volontairement pour LSA Protection. Les trois modes de sécurité configurent `RunAsPPL=2` sans verrou UEFI et suppriment `RunAsPPLBoot` ainsi que la valeur de stratégie locale concurrente afin de converger vers le même état. Gaming et Performance Max désactivent séparément Credential Guard avec `LsaCfgFlags=0` localement et dans la stratégie Device Guard ; Défaut Windows le laisse non configuré. Une stratégie d'entreprise ou un verrou UEFI antérieur peut néanmoins imposer un autre état.

**Q : Quelles fonctionnalités essentielles sont conservées ?**
R : Windows Update, Microsoft Store et WebView2 ne sont pas volontairement supprimés. Les fonctions dépendantes d'Edge, OneDrive ou d'une autre application retirée peuvent néanmoins changer.

---

<div align="center">

**Développé avec passion par Kayler**  
*Optimisez votre expérience Windows dès aujourd'hui.*

[**📥 Télécharger All in One.cmd**](https://github.com/kaylerberserk/WindowsOptimizer/blob/main/All%20in%20One.cmd)

</div>
