# 🏛️ Musées de France - Application Shiny

Cette application **R Shiny** permet de visualiser, rechercher et explorer les musées de France en utilisant les données publiques fournies par l’API du Ministère de la Culture.

---

## 🚀 Fonctionnalités principales

- 🗺️ Carte interactive avec filtres par **région** et **département**
- 📋 Table de tous les musées avec **export CSV**
- 🔍 Recherche dynamique par **nom**
- 📊 Statistiques sur les **top 10 régions** et **top 10 départements**
- 📍 Recherche des **musées proches d’une adresse** avec :
  - Rayon ajustable (1 à 50 km)
  - Carte dynamique
  - Liste exportable en `.csv`

---

## ▶️ Lancer l’application en local

### Prérequis

- R (version 4.x ou plus)
- RStudio (optionnel mais recommandé)

### Packages nécessaires

```r
install.packages(c("shiny", "shinythemes", "tidyverse", "leaflet", "DT", "httr", "jsonlite", "tmaptools", "geosphere"))
```

### Lancement

```r
shiny::runApp()
```

Depuis le dossier racine contenant les fichiers : `app.R`, `global.R`, `libraries.R`

---

## 📁 Structure du dépôt

```
musees_france_app/
├── app.R             # UI + Server Shiny
├── global.R          # Chargement & nettoyage des données API
├── libraries.R       # Chargement des packages
├── README.md         # Ce fichier
├── www/              # (si besoin d’images/icônes)
```

---

## 🌐 Données utilisées

- API publique : [data.culture.gouv.fr - Musées de France](https://data.culture.gouv.fr/explore/dataset/liste-et-localisation-des-musees-de-france)

---

## 💡 Auteur

Projet développé pour l’étude de cas **données culturelles interactives**.

> N'hésitez pas à forker ou proposer des améliorations 🚀

---

## 🌍 Accès public à l'application

👉 Lancer l'application en ligne : [https://museesdefrance.shinyapps.io/musees_france_app/](https://museesdefrance.shinyapps.io/musees_france_app/)
