# Pare-feu et filtrage réseau sous Linux

Mise en place d'un pare-feu **firewalld** sur un serveur **Red Hat** selon une politique de sécurité restrictive, fondée sur le principe du moindre privilège, puis validation de l'exposition réseau avec **Nmap**.

Projet réalisé dans le cadre du Master *Cryptographie et Sécurité de l'Information* (Faculté des Sciences, Université Mohammed V de Rabat), année universitaire 2025/2026.

**Auteurs :** Imane Aabouz, Hajar Gasmi
**Encadrant :** Mr Khalid Zinedine

---

## Objectifs

- Comprendre le filtrage réseau par zones.
- Mettre en œuvre une politique de sécurité réseau restrictive.
- Utiliser les commandes d'administration `firewall-cmd`.
- Vérifier la surface d'exposition du serveur avec Nmap.

## Environnement

- Système : Red Hat Enterprise Linux (ou dérivé)
- Pare-feu : firewalld
- Outil d'audit : Nmap 7.92
- Interface réseau : `enp0s3` (zone `public`)

## Démarche

### 1. Audit initial

Avant toute modification, on vérifie l'état du démon et la zone active associée à l'interface réseau :

```bash
systemctl status firewalld
firewall-cmd --get-active-zones
```

L'interface est associée à la zone `public`, qui bloque par défaut tout trafic entrant non explicitement autorisé.

### 2. Application de la politique de filtrage

La politique consiste à n'autoriser que les services nécessaires à l'administration et à l'accès web, et à retirer les services superflus.

```bash
# Autoriser les services nécessaires
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# Retirer les services non essentiels
sudo firewall-cmd --permanent --zone=public --remove-service=cockpit
sudo firewall-cmd --permanent --zone=public --remove-service=dhcpv6-client

# Appliquer et vérifier
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

Résultat attendu : seuls `ssh`, `http` et `https` restent autorisés dans la zone `public`.

### 3. Validation avec Nmap

Le scan permet de vérifier depuis l'extérieur quels ports restent accessibles :

```bash
# À exécuter depuis une machine distincte du serveur, vers son adresse IP
nmap -sS <IP_DU_SERVEUR>
```

> **Remarque :** un scan lancé depuis le serveur lui-même (`nmap -sS localhost`) ne reflète pas l'exposition réseau réelle. Il ne sert que de contrôle de cohérence.

## Résultats

- Seul le port 22 (SSH) est accessible, conformément à la politique définie.
- Les autres ports sont fermés ou filtrés par le pare-feu.
- La configuration finale ne conserve que `ssh`, `http` et `https` dans la zone `public`.

## Alignement avec les référentiels

La configuration s'inscrit dans les bonnes pratiques recommandées par :

- **ANSSI** : réduction de la surface d'attaque.
- **ISO/IEC 27001 (Annexe A.13.1)** : contrôles réseau et documentation des flux.
- **NIST CSF (PR.AC, PR.PT)** : contrôle des accès et protection des communications.

## Limites

- Projet réalisé en environnement de laboratoire, non évalué en production ni sous charge.
- Le scan de validation a été réalisé dans un cadre pédagogique, avec des règles de base uniquement.

## Structure du dépôt

```
pare-feu-linux/
├── README.md
├── docs/        # Rapport (si autorisé)
├── scripts/     # Commandes firewall-cmd regroupées
└── images/      # Captures d'écran
```

## Licence

- **Code** (`scripts/`) : [MIT](LICENSE).
- **Rapport** (`docs/`) : [CC BY-NC 4.0](docs/LICENSE-rapport.md).
