# Manuel utilisateur du site UniCity

Ce document décrit uniquement le frontend de l'application UniCity, tel qu'il est visible par un utilisateur final dans le navigateur ou dans l'application mobile.

Le texte est rédigé pour une personne qui découvre le site pour la première fois. Il explique quoi voir, quoi cliquer, ce qui change selon le rôle, et à quoi servent les différentes pages. Les captures d'écran ne sont pas intégrées ici : chaque figure indique précisément l'image attendue pour que tu puisses la prendre ensuite.

## Table des matières

### Partie commune

- [1. Comment lire ce manuel](#1-comment-lire-ce-manuel)
- [3. Structure générale de l'interface](#3-structure-générale-de-linterface)
- [18. Fiche technique pour un usage confortable](#18-fiche-technique-pour-un-usage-confortable)

### Partie citoyen non connecté

- [2. Les rôles et leurs différences](#2-les-rôles-et-leurs-différences)
- [4. Se connecter, s'inscrire et quitter son compte](#4-se-connecter-sinscrire-et-quitter-son-compte)
- [5. La page d'accueil](#5-la-page-daccueil)
- [6. Signalements](#6-signalements)
- [7. Agenda](#7-agenda)
- [10. Informations utiles](#10-informations-utiles)

### Partie citoyen connecté

- [2. Les rôles et leurs différences](#2-les-rôles-et-leurs-différences)
- [5. La page d'accueil](#5-la-page-daccueil)
- [8. Sondages](#8-sondages)
- [9. Actualités et messagerie avec la mairie](#9-actualités-et-messagerie-avec-la-mairie)
- [11. Mon compte](#11-mon-compte)

### Partie élus et personnel de mairie

- [2. Les rôles et leurs différences](#2-les-rôles-et-leurs-différences)
- [8. Sondages](#8-sondages)
- [9. Actualités et messagerie avec la mairie](#9-actualités-et-messagerie-avec-la-mairie)
- [12. Mairie / quartiers](#12-mairie--quartiers)

### Partie administrateur global

- [2. Les rôles et leurs différences](#2-les-rôles-et-leurs-différences)
- [13. Gestion des comptes utilisateurs](#13-gestion-des-comptes-utilisateurs)
- [14. Création multiple d'utilisateurs](#14-création-multiple-dutilisateurs)
- [15. Partage des identifiants](#15-partage-des-identifiants)

### Références de fin de document

- [16. Résumé final pour un utilisateur débutant](#16-résumé-final-pour-un-utilisateur-débutant)
- [17. Glossaire](#17-glossaire)
- [19. Bibliographie / références internes](#19-bibliographie--références-internes)

---

## 1. Comment lire ce manuel

Le site est découpé en pages. Chaque page a un but simple. Quand on parle de "vue", cela désigne ce que l'utilisateur voit à l'écran à un moment donné : une page d'accueil, un formulaire, une boîte de dialogue, une liste filtrable, ou un écran d'attente.

Dans ce manuel, les pages sont classées dans l'ordre le plus utile pour un citoyen :

- d'abord les pages accessibles à tous ;
- ensuite les pages accessibles uniquement après connexion ;
- enfin les vues réservées aux élus, aux agents et aux administrateurs.

Cette organisation est importante, car le site ne montre pas exactement la même chose à tout le monde. Les boutons et les menus apparaissent selon le rôle de la personne connectée.

**Figure 1 : Page d'accueil avec la navigation principale**  
Capture attendue : la page d'accueil sur ordinateur, avec le bandeau du haut, le logo, les cartes centrales et les zones secondaires visibles.

**Figure 2 : Page d'accueil sur écran étroit ou mobile**  
Capture attendue : la même page sur un petit écran, pour montrer le passage en disposition verticale et le menu compact.

---

## 2. Les rôles et leurs différences

Le frontend distingue plusieurs profils. Pour un utilisateur, la différence principale n'est pas seulement ce qu'il peut faire, mais surtout ce qu'il voit.

### 2.1. Citoyen non connecté

Un citoyen non connecté peut consulter les contenus publics du site. Il a accès à :

- l'accueil ;
- les signalements ;
- l'agenda ;
- les informations utiles ;
- l'inscription ;
- la connexion.

Dans le menu, il ne voit pas les pages privées comme "Mon compte", "Actualités" ou "Sondages" si ces pages demandent une session ouverte.

Ce profil sert surtout à découvrir le site, lire les informations publiques et décider ensuite de créer un compte.

### 2.2. Citoyen connecté

Une fois connecté, le citoyen voit davantage de rubriques et de contrôles. Il peut :

- revenir à l'accueil avec une vue enrichie ;
- accéder à "Mon compte" ;
- consulter les actualités ;
- consulter les sondages ;
- créer un signalement ;
- envoyer un message à la mairie depuis la page actualités ;
- voter si le sondage correspond à son profil.

Le citoyen connecté reste un utilisateur standard : il ne voit pas les outils d'administration des comptes, des quartiers ou des contenus réservés.

### 2.3. Élu

L'élu a les droits d'un citoyen connecté, mais le frontend lui affiche aussi des pages supplémentaires et des actions de gestion.

Différences visibles côté interface :

- un bouton ou une entrée de navigation supplémentaire vers la page "Mairie / quartiers" ;
- des droits de gestion sur les sondages ;
- des interactions de type staff dans la boîte de réception des messages ;
- parfois des options plus larges sur les contenus administratifs.

En pratique, l'élu n'est pas là pour gérer les comptes utilisateurs en masse. Cette partie reste réservée à l'administrateur global.

### 2.4. Agent municipal

Le rôle agent n'ajoute pas forcément une page dédiée dans le menu principal, mais il compte dans les vues de type "staff".

Concrètement, un agent peut apparaître comme personnel de mairie dans :

- la boîte de réception des messages ;
- certains contenus administratifs visibles pour le personnel ;
- les pages où le site distingue les citoyens du personnel de la mairie.

L'idée importante est la suivante : l'agent n'a pas le même niveau qu'un administrateur global, mais il n'est pas non plus un simple visiteur. Il appartient à la catégorie des profils de service.

### 2.5. Administrateur global

L'administrateur global est le profil le plus complet dans le frontend.

Il peut voir et utiliser :

- la page "Mairie / quartiers" ;
- la page "Gestion des comptes utilisateurs" ;
- la création multiple d'utilisateurs ;
- la page de partage des identifiants ;
- l'édition des informations utiles ;
- les fonctions d'administration dans les sondages ;
- les fonctions de suivi dans la boîte de réception du site.

Il a également accès à tous les éléments visibles pour les citoyens connectés.

### 2.6. Résumé comparatif des rôles

| Rôle | Ce qu'il voit en plus | Ce qu'il peut faire en plus |
|---|---|---|
| Citoyen non connecté | Pages publiques uniquement | Consulter, s'inscrire, se connecter |
| Citoyen connecté | Mon compte, actualités, sondages | Voter, signaler, écrire à la mairie, modifier son profil |
| Élu | Mairie / quartiers, outils de gestion des sondages | Gérer certains contenus et répondre comme staff |
| Agent municipal | Vues staff de la messagerie et contenus de service | Traiter les messages, participer aux vues réservées au personnel |
| Administrateur global | Tous les écrans d'administration | Gérer les comptes, les quartiers, les identifiants, les contenus de la commune |

**Figure 3 : Comparaison visuelle des menus selon le rôle**  
Capture attendue : une suite de captures ou un montage montrant le bandeau supérieur pour un citoyen non connecté, un citoyen connecté, un élu et un administrateur global.

---

## 3. Structure générale de l'interface

Avant de détailler chaque page, il faut comprendre les éléments récurrents du site.

### 3.1. Le bandeau du haut

Le bandeau supérieur sert de point de repère. Il contient :

- le logo ;
- les boutons de navigation ;
- le menu de profil si l'utilisateur est connecté ;
- les boutons de connexion ou d'inscription si l'utilisateur est invité.

Le logo ramène toujours à l'accueil. Cela permet de revenir en arrière sans réfléchir au chemin exact parcouru.

### 3.2. Le menu compact sur petit écran

Quand l'écran est étroit, les boutons de navigation se regroupent dans une version compacte. Le but est le même : permettre d'aller vers les pages principales sans encombrer l'écran.

Sur un téléphone ou une fenêtre réduite, l'utilisateur n'a pas besoin de comprendre la technique ; il doit seulement savoir que le menu existe toujours, mais sous une forme plus condensée.

### 3.3. Les en-têtes de page

Beaucoup de pages du site utilisent un en-tête commun avec :

- une icône ;
- un titre ;
- une courte description ;
- parfois un fil d'Ariane, appelé breadcrumb.

Le fil d'Ariane sert à se repérer. Il indique où l'on se trouve et permet parfois de revenir à la page précédente.

**Figure 4 : En-tête de page avec titre, description et fil d'Ariane**  
Capture attendue : un exemple de page secondaire où l'on voit le titre, l'icône et le breadcrumb en haut.

### 3.4. Les états d'attente et les retours visuels

Le site affiche parfois des écrans de chargement, des squelettes de contenu, des overlay de chargement ou des messages temporaires.

Ils servent à éviter que l'utilisateur pense que la page est vide ou bloquée. Ce point est important dans un manuel utilisateur : une zone grisée ou un cercle de chargement signifie souvent que le contenu est simplement en train d'arriver.

**Figure 5 : Écran de chargement pendant l'initialisation**  
Capture attendue : la page de chargement avec l'animation circulaire au centre.

---

## 4. Se connecter, s'inscrire et quitter son compte

### 4.1. L'écran de connexion

L'écran de connexion sert à accéder aux pages réservées.

Il contient :

- un champ identifiant ;
- un champ mot de passe ;
- un bouton de validation ;
- un lien pour revenir à l'accueil ;
- un lien pour créer un compte.

Le site vérifie que les champs ne sont pas vides. Si les informations sont incorrectes, le message d'erreur s'affiche directement sur la page.

Le rôle du citoyen n'est pas choisi ici. Le site le récupère automatiquement une fois la connexion réussie.

**Figure 6 : Écran de connexion complet**  
Capture attendue : le formulaire avec les deux champs, le bouton de connexion et le lien vers la création de compte.

### 4.2. L'écran de création de compte

L'inscription permet à un citoyen de créer lui-même son profil.

Champs demandés :

- prénom ;
- nom ;
- adresse ;
- e-mail ;
- identifiant ;
- mot de passe ;
- confirmation du mot de passe.

Le site vérifie :

- que les champs obligatoires sont remplis ;
- que l'adresse e-mail est valide ;
- que l'identifiant ne contient pas d'espace ;
- que le mot de passe est suffisamment long ;
- que la confirmation est identique au mot de passe.

Quand tout est correct, la création du compte se termine et l'utilisateur est envoyé vers l'écran de connexion.

**Figure 7 : Écran de création de compte citoyen**  
Capture attendue : le formulaire d'inscription complet, avec tous les champs visibles et les aides de validation.

### 4.3. Le menu de profil et la déconnexion

Quand l'utilisateur est connecté, un menu de profil apparaît dans le bandeau supérieur.

Dans ce menu, on peut généralement :

- accéder à "Mon compte" ;
- se déconnecter.

La déconnexion remet l'utilisateur dans l'état visiteur et retire les pages privées du menu.

**Figure 8 : Menu de profil ouvert**  
Capture attendue : le menu déroulant du profil avec l'accès au compte personnel et l'action de déconnexion.

---

## 5. La page d'accueil

La page d'accueil est la première page utile du site. Elle sert de tableau de bord de lecture.

### 5.1. Les grandes cartes centrales

La zone principale présente de grandes cartes. Elles sont là pour orienter rapidement l'utilisateur vers les rubriques importantes.

Selon le niveau de connexion, les cartes ne sont pas les mêmes. Un visiteur voit surtout les accès publics. Un citoyen connecté voit un ensemble plus large.

Les cartes les plus importantes sont :

- **Signalements** : consulter ou créer un problème signalé ;
- **Agenda** : voir les événements de la commune ;
- **Informations utiles** : trouver l'adresse, le téléphone et les horaires de la mairie ;
- **Sondages** : consulter et répondre aux consultations ;
- **Actualités** : lire les publications et écrire à la mairie.

Chaque carte utilise un titre, une courte phrase de présentation et parfois un indicateur numérique pour aider à comprendre l'état du service.

### 5.2. Le panneau secondaire

Sur la droite, ou sous les cartes sur petit écran, la page d'accueil affiche des blocs plus petits. Ils donnent des indications complémentaires :

- activité récente ;
- résumé des informations utiles ;
- contexte général du site.

### 5.3. Différence entre visiteur et utilisateur connecté

Un visiteur comprend le site à travers les services de base.

Un utilisateur connecté voit plus de contenu et peut agir sur certaines pages. Cette différence est volontaire : la page d'accueil doit rester simple pour une personne qui ne connaît rien au site.

**Figure 9 : Accueil côté visiteur**  
Capture attendue : la page d'accueil avec les cartes publiques seulement.

**Figure 10 : Accueil côté utilisateur connecté**  
Capture attendue : la même page après connexion, avec davantage de cartes et le menu de profil.

**Figure 11 : Panneau latéral de l'accueil**  
Capture attendue : un zoom sur les blocs secondaires affichés à droite ou sous la zone principale.

---

## 6. Signalements

La page des signalements est destinée aux problèmes concrets observés dans la ville.

### 6.1. Ce que l'on cherche sur cette page

Le citoyen peut y voir la liste des signalements déjà créés. Chaque carte de signalement rassemble les informations essentielles pour comprendre rapidement la situation.

Ces informations sont généralement :

- le sujet ou l'intitulé du signalement ;
- la nature du problème ;
- l'adresse ou la zone concernée ;
- la date de création ;
- l'état actuel du dossier.

### 6.2. La recherche et les filtres

La page propose une barre de recherche et plusieurs filtres. Cela permet à un utilisateur de ne pas parcourir une liste trop longue à la main.

Les filtres visibles servent à limiter l'affichage selon :

- la période de date ;
- le type de problème ;
- l'état du signalement ;
- l'adresse ou la zone.

Le tri aide à changer l'ordre des résultats. C'est utile si l'on veut voir d'abord les plus récents ou retrouver un dossier ancien.

### 6.3. Création d'un signalement

Lorsqu'un utilisateur est connecté, un bouton d'action flottant permet d'ouvrir le formulaire de création.

Le formulaire sert à décrire le problème de façon claire :

- ce qui ne va pas ;
- où se situe le problème ;
- ce qui rend la situation urgente ou importante ;
- tout détail utile pour aider à l'analyse.

Le principe est simple : mieux le problème est décrit, plus il est facile à traiter.

### 6.4. Comprendre l'état d'un signalement

Le statut d'un signalement indique son évolution. Le site affiche des états lisibles, par exemple :

- en attente ;
- en cours ;
- traité ;
- clos ou résolu.

Pour un débutant, il suffit de retenir qu'un état plus avancé signifie généralement que la mairie ou le service compétent a déjà commencé à s'en occuper.

**Figure 12 : Liste des signalements avec recherche et filtres**  
Capture attendue : la page des signalements complète, avec plusieurs cartes et les contrôles de recherche visibles.

**Figure 13 : Formulaire de création d'un signalement**  
Capture attendue : la boîte de dialogue ou la page de création de signalement avec les champs et les boutons de validation.

**Figure 14 : Exemple d'état de signalement**  
Capture attendue : une carte de signalement où l'on voit clairement le statut et les informations principales.

---

## 7. Agenda

La page Agenda sert à voir les événements de la commune de manière très visuelle.

### 7.1. Le calendrier

La partie principale est un calendrier mensuel. Certains jours portent de petits marqueurs indiquant qu'il existe un ou plusieurs événements ce jour-là.

Le fonctionnement est pensé pour être compréhensible sans mode d'emploi technique :

1. on regarde le mois affiché ;
2. on repère les jours marqués ;
3. on clique sur un jour ;
4. on lit la liste des événements proposés.

Quand on clique sur une date, une fenêtre s'ouvre et affiche les événements de ce jour-là.

### 7.2. La liste des événements futurs

Sous le calendrier, la page affiche aussi les événements à venir sous forme de cartes. Cette vue est utile si l'utilisateur veut simplement savoir ce qui est prévu sans explorer le calendrier date par date.

La carte d'événement peut contenir :

- le titre ;
- l'heure ou la date ;
- le thème ;
- une courte description.

La liste est paginée : si les événements sont nombreux, l'utilisateur passe à la page suivante sans perdre le fil.

### 7.3. La recherche et le tri

La page peut proposer des filtres par thème et une recherche par mot-clé. Cela aide à retrouver un événement précis, par exemple une réunion, une activité culturelle ou un rendez-vous local.

### 7.4. Ce que le citoyen doit retenir

L'agenda n'est pas une page d'administration. C'est une page de lecture et de consultation.

Pour un citoyen, le plus important est de savoir :

- à quelle date a lieu l'événement ;
- dans quel ordre les événements sont affichés ;
- comment ouvrir le détail d'un jour ;
- où voir les événements à venir.

**Figure 15 : Calendrier mensuel de l'agenda**  
Capture attendue : le calendrier avec plusieurs journées marquées par des points ou des indicateurs d'événements.

**Figure 16 : Fenêtre détaillée d'une journée**  
Capture attendue : la fenêtre qui s'ouvre après un clic sur une date, avec la liste des événements du jour.

**Figure 17 : Liste paginée des événements à venir**  
Capture attendue : la partie de la page qui montre plusieurs cartes d'événements et les contrôles de pagination.

---

## 8. Sondages

La page Sondages permet de lire les consultations en cours et de voter lorsque l'utilisateur a le droit de le faire.

### 8.1. Présentation des cartes de sondage

Chaque sondage est affiché sous forme de carte. Une carte sert à résumer rapidement la consultation.

On y trouve en général :

- le titre du sondage ;
- sa description ;
- les options de réponse ;
- l'information sur le public visé ;
- l'état du sondage.

### 8.2. Les outils de lecture

La page permet de :

- chercher un sondage par texte ;
- trier les résultats ;
- choisir combien de cartes apparaissent par ligne ;
- filtrer selon le type de citoyen visé quand le rôle le permet.

Ces options ne sont pas là pour compliquer la lecture, mais pour rendre le site lisible même lorsqu'il y a beaucoup de consultations.

### 8.3. Qui peut voter ?

La possibilité de voter dépend de deux choses :

- le fait d'être connecté ;
- la correspondance entre le profil de l'utilisateur et la cible du sondage.

Un sondage peut être :

- ouvert à tous les citoyens ;
- réservé à un profil précis ;
- ouvert à certaines catégories seulement.

Un administrateur global peut généralement voter sans restriction sur les sondages visibles. Un élu peut aussi gérer des sondages. Un citoyen ne peut voter que si son profil correspond à la cible du sondage.

### 8.4. Création, modification et suppression

Les actions de gestion des sondages sont réservées aux élus et aux administrateurs globaux.

Ils peuvent :

- créer un sondage ;
- modifier un sondage ;
- supprimer un sondage ;
- changer la cible du sondage.

Un citoyen standard ne voit pas ces commandes.

**Figure 18 : Liste des sondages côté citoyen**  
Capture attendue : la page montrant plusieurs cartes de sondages lisibles sans action d'administration.

**Figure 19 : Écran de vote sur un sondage**  
Capture attendue : un sondage ouvert avec ses options de réponse visibles et le bouton de validation.

**Figure 20 : Formulaire d'administration d'un sondage**  
Capture attendue : l'écran réservé aux élus ou administrateurs avec les champs de création ou de modification.

---

## 9. Actualités et messagerie avec la mairie

Cette page est plus riche que les autres, car elle mélange un flux d'information, une galerie d'images et une messagerie.

### 9.1. Le fil d'actualité

La première partie affiche des contenus de type publication. Pour un citoyen, cela ressemble à un mur d'informations locales.

Le fil sert à voir rapidement :

- les annonces de la commune ;
- les informations pratiques ;
- les événements en cours ;
- les communications importantes.

### 9.2. La galerie photo

Une autre zone présente des photos. Elle rend la page plus vivante et aide à comprendre une actualité sans devoir lire un long texte.

### 9.3. Envoyer un message à la mairie

Le citoyen peut aussi écrire à la mairie à l'aide d'un formulaire.

Le formulaire demande au minimum :

- un sujet ;
- un message.

Le site vérifie que le contenu n'est pas vide avant l'envoi.

### 9.4. La boîte de réception

Sous le formulaire, une boîte de réception affiche les messages envoyés.

Il existe deux logiques de lecture :

- côté citoyen : suivre les messages envoyés et leur état ;
- côté personnel de mairie : lire, classer et répondre aux messages.

Les onglets permettent souvent de séparer les messages en attente et ceux déjà traités.

### 9.5. Différence entre citoyen et staff

Pour le citoyen, cette page sert à communiquer.

Pour l'élu, l'agent ou l'administrateur, elle sert aussi à traiter les demandes.

Cette différence est importante, car les mêmes cartes ne donnent pas les mêmes boutons selon le rôle : un citoyen voit surtout la lecture, le personnel de mairie voit des actions de réponse.

**Figure 21 : Fil d'actualité et galerie photo**  
Capture attendue : la page Actualités avec le flux à gauche et la galerie photo à droite.

**Figure 22 : Formulaire de contact avec la mairie**  
Capture attendue : le formulaire d'envoi d'un message avec le sujet, le corps du message et le bouton d'envoi.

**Figure 23 : Boîte de réception côté citoyen**  
Capture attendue : les onglets de suivi des messages avec les cartes de conversations visibles.

**Figure 24 : Boîte de réception côté staff**  
Capture attendue : la même zone de messages, mais avec les contrôles de réponse visibles pour le personnel autorisé.

---

## 10. Informations utiles

La page Informations utiles sert à retrouver toutes les données pratiques de la mairie.

### 10.1. Version lecture seule

Dans sa version normale, cette page présente :

- le nom de la mairie ;
- l'adresse ;
- le code postal ;
- la ville ;
- le téléphone ;
- l'adresse e-mail ;
- le site internet ;
- les horaires d'ouverture ;
- les liens vers les réseaux sociaux quand ils existent.

Cette page est pensée pour répondre aux questions très simples : où aller, quand venir, qui appeler, comment écrire.

### 10.2. Les sections de la page

Les informations sont regroupées en blocs distincts :

- bloc mairie ;
- bloc horaires ;
- bloc contact ;
- bloc réseaux sociaux.

Si une partie est vide, le site évite d'afficher une zone cassée et montre plutôt un état vide ou une section absente.

### 10.3. Le mode édition

L'administrateur global peut ouvrir la page en mode édition.

Dans ce mode, la page devient un formulaire. On peut modifier :

- les données de la mairie ;
- les contacts ;
- les réseaux sociaux ;
- les horaires détaillés de chaque jour.

Le formulaire est plus technique que la version lecture, mais le principe reste simple : modifier puis enregistrer.

**Figure 25 : Informations utiles en lecture seule**  
Capture attendue : la page affichant clairement les sections mairie, horaires, contact et réseaux sociaux.

**Figure 26 : Informations utiles en mode édition**  
Capture attendue : le formulaire d'administration avec tous les champs modifiables.

---

## 11. Mon compte

La page Mon compte est la page personnelle du citoyen connecté.

### 11.1. Ce que la page affiche

Le formulaire permet de voir et de modifier :

- le prénom ;
- le nom ;
- l'adresse e-mail ;
- le nom d'utilisateur.

### 11.2. Les sections du formulaire

La page sépare les informations en deux parties :

- les informations personnelles ;
- les informations de connexion.

Cette séparation aide à comprendre ce que l'on modifie. Le citoyen voit immédiatement ce qui concerne son identité et ce qui concerne son accès au site.

### 11.3. Changer son mot de passe

Un bouton ouvre une boîte de dialogue de changement de mot de passe.

Cette boîte demande généralement :

- le mot de passe actuel ;
- le nouveau mot de passe ;
- la confirmation du nouveau mot de passe.

### 11.4. Réinitialiser et enregistrer

La page propose aussi :

- un bouton pour remettre les champs à leur valeur d'origine ;
- un bouton pour sauvegarder les modifications.

Quand l'enregistrement réussit, le site affiche un retour visuel clair pour informer l'utilisateur.

### 11.5. États de chargement et d'erreur

Si les données du compte ne sont pas encore prêtes, un écran de chargement ou un squelette peut apparaître.

Si une erreur survient, le site affiche un message explicite et propose de réessayer.

**Figure 27 : Page Mon compte**  
Capture attendue : le formulaire complet du profil utilisateur avec les informations personnelles et de connexion.

**Figure 28 : Fenêtre de changement de mot de passe**  
Capture attendue : la boîte de dialogue avec les trois champs de mot de passe.

**Figure 29 : État d'erreur ou de chargement du compte**  
Capture attendue : un écran montrant soit le squelette, soit le message d'erreur avec le bouton de réessai.

---

## 12. Mairie / quartiers

Cette page est réservée aux profils autorisés. Elle n'apparaît pas pour un simple citoyen.

### 12.1. Ce que la page gère

La page sert à gérer les quartiers ou secteurs associés à la commune.

Les fonctions visibles sont :

- créer un quartier ;
- modifier un quartier ;
- supprimer un quartier ;
- rechercher un quartier dans une liste ;
- parcourir la liste avec pagination.

### 12.2. Comment la page se présente

La page est organisée autour d'une liste de cartes. Chaque carte représente un quartier.

Les actions usuelles sont simples :

- ouvrir un formulaire de création ;
- ouvrir un formulaire d'édition ;
- confirmer la suppression dans une boîte de dialogue ;
- revenir à la liste après chaque action.

La suppression est toujours confirmée pour éviter une erreur de clic.

### 12.3. Ce qu'un citoyen doit comprendre

Cette page n'est pas un service de consultation générale. C'est une page de gestion interne. Si vous ne voyez pas cette page, ce n'est pas une erreur : c'est un comportement normal lié au rôle.

**Figure 30 : Page de gestion des quartiers**  
Capture attendue : la liste des quartiers avec la recherche, les cartes et les actions de création, modification ou suppression.

---

## 13. Gestion des comptes utilisateurs

Cette page est réservée à l'administrateur global.

### 13.1. Ce que l'on peut faire

La page permet de :

- consulter la liste des comptes ;
- rechercher des utilisateurs ;
- trier la liste ;
- filtrer selon certains critères ;
- ouvrir un formulaire de création ;
- ouvrir un formulaire d'édition ;
- supprimer un compte si le profil le permet ;
- gérer les demandes en attente quand elles existent.

### 13.2. Les demandes en attente

En haut ou au début de la page, une section spécifique affiche parfois les utilisateurs en attente de traitement.

Cette partie sert à distinguer les comptes déjà actifs des comptes qui doivent encore être examinés ou validés.

### 13.3. Le menu d'actions

Un bouton d'action flottant ouvre un menu avec plusieurs choix :

- créer un utilisateur ;
- créer plusieurs utilisateurs.

Le comportement est important : l'administrateur n'a pas besoin de chercher dans plusieurs pages, tout est regroupé dans le même menu.

### 13.4. Les états visuels

La page peut afficher :

- un voile de chargement si l'opération dure longtemps ;
- un message d'erreur si la liste ne peut pas être chargée ;
- un message de succès après suppression ou modification.

**Figure 31 : Gestion des comptes utilisateurs**  
Capture attendue : la page d'administration montrant la liste des comptes et les filtres.

**Figure 32 : Menu d'ajout d'utilisateur ouvert**  
Capture attendue : le bouton flottant déployé avec les actions de création simple et de création multiple.

---

## 14. Création multiple d'utilisateurs

Cette page est l'une des plus techniques du frontend. Elle sert à créer plusieurs comptes sans les saisir un par un sur plusieurs écrans.

### 14.1. Deux modes d'utilisation

Le site propose deux façons de travailler :

- **mode manuel** : l'administrateur remplit une carte utilisateur, puis l'ajoute à une liste de brouillon ;
- **mode CSV** : l'administrateur importe un fichier contenant plusieurs utilisateurs.

Les deux modes servent au même objectif : préparer plusieurs comptes avant leur création finale.

### 14.2. Le mode manuel

Le mode manuel ressemble à une série de petits formulaires.

On peut y saisir :

- le prénom ;
- le nom ;
- le nom d'utilisateur ;
- l'adresse e-mail ;
- le rôle.

Le site propose parfois un nom d'utilisateur automatique à partir du prénom et du nom. L'administrateur peut le modifier si besoin.

Les brouillons d'utilisateurs peuvent être modifiés avant validation finale.

### 14.3. Le mode CSV

Le mode CSV permet d'importer plusieurs lignes d'un seul coup.

Le fichier d'exemple rappelle les colonnes attendues. Le site vérifie le contenu avant de lancer l'import final.

Colonnes minimales attendues :

- `first_name` ;
- `last_name` ;
- `username` ;
- `email`.

Une colonne de rôle peut aussi exister.

Le site peut accepter le fichier de plusieurs façons :

- sélection dans le système de fichiers ;
- glisser-déposer sur la zone prévue ;
- import depuis un fichier déjà préparé.

### 14.4. Validation et erreurs CSV

Avant la création, le frontend vérifie les données.

Si des erreurs sont détectées, le site ne fait pas semblant de réussir. Il affiche une liste détaillée avec :

- la ligne concernée ;
- la colonne concernée ;
- un message explicite.

Ce point est très important pour un administrateur débutant, car il évite de perdre du temps à chercher une erreur dans un fichier trop long.

### 14.5. Les brouillons et la sauvegarde locale

La page peut conserver les brouillons d'utilisateurs pour éviter de perdre les données en cas de fermeture accidentelle.

Cela signifie qu'un administrateur peut revenir plus tard et retrouver une partie du travail déjà préparé.

### 14.6. Les sorties après création

Une fois les comptes préparés et créés, le frontend peut produire des identifiants à partager.

**Figure 33 : Création multiple en mode manuel**  
Capture attendue : l'écran avec plusieurs cartes utilisateur en brouillon.

**Figure 34 : Import CSV et zone de dépôt**  
Capture attendue : la zone d'import, le bouton de sélection de fichier et le fichier exemple.

**Figure 35 : Validation CSV avec erreurs détaillées**  
Capture attendue : la fenêtre affichant les lignes et colonnes en erreur.

**Figure 36 : Liste des comptes en brouillon avant création finale**  
Capture attendue : l'écran montrant les utilisateurs préparés avant validation.

---

## 15. Partage des identifiants

Cette page s'ouvre avec un lien ou un état de partage spécial. Elle sert à montrer les identifiants de connexion d'une personne à qui l'on vient de créer un compte.

### 15.1. Ce que la page affiche

La page peut montrer :

- le prénom ;
- le nom ;
- le nom d'utilisateur ;
- l'adresse e-mail ;
- parfois le mot de passe.

### 15.2. Ce que l'utilisateur peut faire

Chaque valeur peut être copiée séparément. C'est utile pour transmettre les informations à la bonne personne sans retaper les données à la main.

Si le partage n'est pas valide ou si les données sont absentes, la page affiche un message d'indisponibilité plutôt qu'un écran vide.

### 15.3. Pourquoi cette vue existe

Elle sert à faciliter la distribution des identifiants après une création de compte en masse ou une création par l'administration.

**Figure 37 : Page de partage des identifiants**  
Capture attendue : la carte montrant les identifiants avec les boutons de copie et le message d'information.

**Figure 38 : État indisponible du partage**  
Capture attendue : l'écran d'erreur ou d'indisponibilité lorsque le lien de partage est invalide.

---

## 16. Résumé final pour un utilisateur débutant

Si l'on simplifie tout, il faut retenir ceci :

- un citoyen non connecté lit les pages publiques ;
- un citoyen connecté peut agir davantage et gérer son profil ;
- un élu voit des fonctions de gestion supplémentaires ;
- un agent municipal intervient surtout dans les vues de type staff ;
- un administrateur global a les écrans les plus complets.

Le frontend ne montre pas tout à tout le monde. C'est normal. Le site a été construit pour adapter l'écran à la personne qui le consulte.

Pour un manuel utilisateur, la meilleure façon de prendre les captures est de suivre ce découpage : accueil, connexion, inscription, signalements, agenda, sondages, actualités, informations utiles, mon compte, puis les vues réservées à l'administration.

---

## 17. Glossaire

Voici les mots les plus utiles pour comprendre le site.

- **Accueil** : première page du site, utilisée pour entrer dans les différentes rubriques.
- **Carte** : bloc visuel cliquable qui présente une fonctionnalité ou un contenu.
- **Fil d'Ariane** : petite ligne de navigation qui indique où l'on se trouve dans le site.
- **Vue** : écran ou partie d'écran visible à un moment donné.
- **Formulaire** : ensemble de champs à remplir avant d'envoyer une information.
- **Signalement** : déclaration d'un problème dans la ville.
- **Agenda** : calendrier des événements de la commune.
- **Sondage** : consultation à laquelle on peut répondre en donnant son avis.
- **Actualités** : contenus de communication et d'information de la commune.
- **Boîte de réception** : zone où l'on voit les messages envoyés à la mairie.
- **Breadcrumb** : autre mot pour fil d'Ariane.
- **Staff** : personnel de mairie ou utilisateur ayant un rôle de traitement des demandes.
- **Élu** : utilisateur ayant un rôle politique avec des droits de gestion supplémentaires.
- **Administrateur global** : utilisateur ayant les droits les plus larges dans le site.
- **Pagination** : découpage d'une liste sur plusieurs pages.
- **Filtre** : outil qui réduit les résultats pour n'afficher que ce qui correspond à un critère.
- **Tri** : changement de l'ordre d'affichage des résultats.
- **Squelette de chargement** : version temporaire d'un écran pendant l'arrivée des données.
- **Modal** : fenêtre qui s'ouvre au-dessus de la page pour afficher ou demander quelque chose.
- **Carte de contenu** : bloc qui résume un signalement, un événement, un sondage ou une actualité.

---

## 18. Fiche technique pour un usage confortable

Cette fiche sert à utiliser l'application web dans de bonnes conditions et à éviter les problèmes les plus courants côté navigateur.

### 18.1. Navigateur recommandé

Pour l'utilisation web, il est recommandé d'utiliser une version récente de :

- Google Chrome ;
- Microsoft Edge ;
- Mozilla Firefox récent.

Le site étant une application Flutter Web, il est plus confortable sur un navigateur moderne et à jour.

### 18.2. Réglages conseillés

- activer JavaScript ;
- autoriser le chargement normal des images et des feuilles de style ;
- éviter le mode de compatibilité ancien ;
- garder le navigateur à jour ;
- autoriser les cookies de session si le navigateur les bloque agressivement.

### 18.3. Conditions d'utilisation confortables

Pour éviter les ralentissements ou les comportements bizarres :

- garder une connexion internet stable ;
- éviter d'ouvrir trop d'onglets du site en même temps ;
- attendre la fin du chargement avant de cliquer plusieurs fois sur le même bouton ;
- rafraîchir la page si un écran semble figé trop longtemps ;
- vider le cache du navigateur après une mise à jour majeure si l'interface semble incohérente.

### 18.4. Résolution et affichage

L'interface fonctionne aussi bien sur ordinateur que sur mobile, mais elle est plus confortable sur un écran large.

Repères utiles :

- ordinateur de bureau : à partir de 1366 × 768 environ, l'affichage est plus lisible ;
- tablette : la page s'adapte en conservant les blocs principaux ;
- mobile : le menu et les cartes se réorganisent en colonne.

### 18.5. Bonnes pratiques pour éviter les erreurs utilisateur

- ne pas actualiser la page pendant un envoi en cours ;
- ne pas fermer la fenêtre pendant une sauvegarde ;
- vérifier les champs marqués comme obligatoires avant validation ;
- utiliser les filtres plutôt que de chercher à l'œil dans les longues listes ;
- se déconnecter quand on change d'utilisateur sur un poste partagé.

### 18.6. Signes qu'il faut recharger la page

Il vaut mieux recharger l'application si :

- un bouton reste bloqué sur un état de chargement très long ;
- une liste ne se met pas à jour après une action ;
- un formulaire semble garder de vieilles valeurs ;
- la navigation ne correspond plus au rôle attendu.

### 18.7. Ce qu'il faut retenir

L'application est pensée pour le web moderne. Pour un usage confortable, le plus important est d'utiliser un navigateur récent, une connexion stable et de laisser le temps au site de charger les données avant de cliquer à nouveau.

---

## 19. Bibliographie / références internes

Ce manuel a été rédigé à partir des éléments visibles dans le frontend de l'application. Les principales références internes utilisées sont :

- [frontend/lib/config/router.dart](frontend/lib/config/router.dart)
- [frontend/lib/config/app_routes.dart](frontend/lib/config/app_routes.dart)
- [frontend/lib/ui/widgets/app_banner.dart](frontend/lib/ui/widgets/app_banner.dart)
- [frontend/lib/features/home/presentation/pages/home_page.dart](frontend/lib/features/home/presentation/pages/home_page.dart)
- [frontend/lib/features/reports/presentation/pages/reports_page.dart](frontend/lib/features/reports/presentation/pages/reports_page.dart)
- [frontend/lib/features/agenda/presentation/pages/agenda_page.dart](frontend/lib/features/agenda/presentation/pages/agenda_page.dart)
- [frontend/lib/features/surveys/presentation/pages/surveys_page.dart](frontend/lib/features/surveys/presentation/pages/surveys_page.dart)
- [frontend/lib/features/news/presentation/pages/news_page.dart](frontend/lib/features/news/presentation/pages/news_page.dart)
- [frontend/lib/features/useful_info/presentation/pages/useful_info_page.dart](frontend/lib/features/useful_info/presentation/pages/useful_info_page.dart)
- [frontend/lib/features/users/presentation/pages/my_account_page.dart](frontend/lib/features/users/presentation/pages/my_account_page.dart)
- [frontend/lib/features/town_hall/presentation/pages/town_hall_page.dart](frontend/lib/features/town_hall/presentation/pages/town_hall_page.dart)
- [frontend/lib/features/users/presentation/pages/user_accounts_page.dart](frontend/lib/features/users/presentation/pages/user_accounts_page.dart)
- [frontend/lib/features/users/presentation/pages/bulk_user_creation_page.dart](frontend/lib/features/users/presentation/pages/bulk_user_creation_page.dart)
- [frontend/lib/features/users/presentation/pages/credentials_share_page.dart](frontend/lib/features/users/presentation/pages/credentials_share_page.dart)

Cette liste n'est pas une bibliographie académique. Elle sert de repère technique pour retrouver rapidement les écrans réellement décrits par le manuel.

## Table des figures

- Figure 1 : Page d'accueil avec la navigation principale
- Figure 2 : Page d'accueil sur écran étroit ou mobile
- Figure 3 : Comparaison visuelle des menus selon le rôle
- Figure 4 : En-tête de page avec titre, description et fil d'Ariane
- Figure 5 : Écran de chargement pendant l'initialisation
- Figure 6 : Écran de connexion complet
- Figure 7 : Écran de création de compte citoyen
- Figure 8 : Menu de profil ouvert
- Figure 9 : Accueil côté visiteur
- Figure 10 : Accueil côté utilisateur connecté
- Figure 11 : Panneau latéral de l'accueil
- Figure 12 : Liste des signalements avec recherche et filtres
- Figure 13 : Formulaire de création d'un signalement
- Figure 14 : Exemple d'état de signalement
- Figure 15 : Calendrier mensuel de l'agenda
- Figure 16 : Fenêtre détaillée d'une journée
- Figure 17 : Liste paginée des événements à venir
- Figure 18 : Liste des sondages côté citoyen
- Figure 19 : Écran de vote sur un sondage
- Figure 20 : Formulaire d'administration d'un sondage
- Figure 21 : Fil d'actualité et galerie photo
- Figure 22 : Formulaire de contact avec la mairie
- Figure 23 : Boîte de réception côté citoyen
- Figure 24 : Boîte de réception côté staff
- Figure 25 : Informations utiles en lecture seule
- Figure 26 : Informations utiles en mode édition
- Figure 27 : Page Mon compte
- Figure 28 : Fenêtre de changement de mot de passe
- Figure 29 : État d'erreur ou de chargement du compte
- Figure 30 : Page de gestion des quartiers
- Figure 31 : Gestion des comptes utilisateurs
- Figure 32 : Menu d'ajout d'utilisateur ouvert
- Figure 33 : Création multiple en mode manuel
- Figure 34 : Import CSV et zone de dépôt
- Figure 35 : Validation CSV avec erreurs détaillées
- Figure 36 : Liste des comptes en brouillon avant création finale
- Figure 37 : Page de partage des identifiants
- Figure 38 : État indisponible du partage

