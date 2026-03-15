# CheReh — Rôles et Rubriques

> Description des tableaux de bord et des actions disponibles par profil utilisateur.

---

## 1. Bénéficiaire

### Dashboard principal

Le dashboard du bénéficiaire affiche l'état de son évaluation de santé en cours et l'accès rapide aux rapports.

**Éléments affichés :**
- Carte hero avec le statut de l'évaluation en cours (% de complétion)
- Bouton "Continuer l'évaluation" ou "Démarrer une évaluation"
- Liste des rapports récents avec niveau de risque
- Parlez à quelqu'un (accedez à la phase premium pour parler à un conseillez ou prendre un rdv medicale)
- Dépistage de Proximité (trouvez un site )

---

### Rubriques du bénéficiaire

#### Accueil
- Voir l'état de l'évaluation en cours (progression)
- Démarrer ou reprendre une évaluation
- Accéder aux derniers rapports

#### Mes Évaluations 
- Files de historiques des evalution 
    -- Affiche titre (terminé /en cours ) reprendre , 
    --affiche la liste comme de discustion chats

#### Rapports (`/reports`)
- Consulter la liste de tous les rapports générés
- Ouvrir un rapport détaillé (score, niveau de risque, recommandations)
- Niveaux de risque : faible / modéré / élevé / très élevé
- Voir les spécialités recommandées

#### Mon profil (`/profile/settings`)

**Identité personnelle**
- Modifier le prénom et le nom
- Renseigner la date de naissance
- Choisir la langue
- Indiquer le niveau d'études
- Sélectionner la commune de résidence

**Informations médicales**
- Numéro CMU
- Taille et poids
- Groupe sanguin
- Allergies
- Statut de grossesse / allaitement / ménopause
- Antécédents de cancer
- Informations de dépistage
- Historique sexuel
- Exposition à la fumée
- Notes complémentaires

**Sécurité (`/profile/security`)**
- Modifier le code PIN (4 à 6 chiffres)
- Activer/désactiver le déverrouillage biométrique
- Activer/désactiver le déverrouillage par agent
- Verrouillage d'urgence (panic lock)

**Autres**
- Aide et support (`/profile/help`)
- Préférences de notifications (`/profile/notifications`)
- Déconnexion

---

## 2. Ambassadeur

### Dashboard principal (`/profile` — vue ambassadeur)

Le dashboard ambassadeur intègre les deux rôles : le bénéficiaire (avec ses propres évaluations) et l'espace de partage par lien de parrainage.

**Éléments affichés :**
- Badge de rôle "Ambassadeur / Ambassadrice"
- Accès aux mêmes fonctionnalités que le bénéficiaire
- Onglet ou tiroir dédié au parrainage

---

### Rubriques de l'ambassadeur

#### Accueil
Identique au bénéficiaire (voir section 1 — Accueil).

#### Partager — onglet Parrainage
**Génération de liens**
- Générer un lien de parrainage par canal : WhatsApp, SMS, QR code, autre
- Copier le lien dans le presse-papier
- Partager directement sur WhatsApp
- Voir le quota hebdomadaire restant
- Voir la date d'expiration du lien

**Métriques de parrainage**
- Nombre total de parrainages créés
- Nombre de parrainages actifs
- Nombre d'utilisations complètes
- Badges obtenus
- Niveau actuel : Starter / Bronze / Argent / Or / Platine

**Gestion des liens**
- Liste des liens actifs avec date de création et statut
- Révoquer un lien actif
- Voir si un lien a été utilisé ou expiré

#### Évaluation, Rapports, Mon profil
Identiques au bénéficiaire (voir section 1).

---

## 3. Agent de terrain

### Dashboard principal — vue agent

Le dashboard de l'agent de terrain propose un double mode : l'agent peut gérer sa propre évaluation **et** enregistrer / évaluer des patients.

**Éléments affichés :**
- Badge de rôle "Agent de terrain"
- Sélecteur de mode : "Mon évaluation" / "Évaluer un patient"
- Formulaire d'enregistrement de patient (mode patient)
- Progression de sa propre évaluation (mode personnel)

---

### Rubriques de l'agent de terrain

#### Accueil — Mode "Mon évaluation"
- Voir la progression de sa propre évaluation (% de complétion)
- Démarrer ou continuer sa propre évaluation
- Accéder à ses propres rapports
- Identique au bénéficiaire pour la suite

#### Patients — onglet Patients

**Enregistrement d'un patient**
- Saisir le numéro de téléphone du patient (avec sélection du pays)
- Validation du format de numéro (8 chiffres minimum)
- Vérifier si le patient existe déjà dans le système
- Créer automatiquement un compte si nouveau patient
- Lancer une évaluation assistée pour le patient (`/flow?subject={id}`)

**Session assistée**
- Conduire l'évaluation au nom du patient
- Même interface que l'évaluation standard
- Les réponses sont enregistrées sous l'identité du patient

#### Évaluation, Rapports, Mon profil
Identiques au bénéficiaire (voir section 1).

---

