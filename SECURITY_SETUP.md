# Configuration locale des accès

L’application ne contient plus de mot de passe écrit dans le code source.
Les quatre valeurs d’accès doivent être fournies au lancement.

## Première configuration

1. Copier `auth_config.example.json` vers `auth_config.json`.
2. Remplacer les quatre valeurs par des identifiants privés.
3. Choisir deux mots de passe différents contenant au moins huit caractères,
   une lettre et un chiffre.
4. Ne jamais ajouter `auth_config.json` à Git.

Sous PowerShell :

```powershell
Copy-Item auth_config.example.json auth_config.json
Add-Content .git\info\exclude "auth_config.json"
flutter run -d chrome --web-port 57474 --dart-define-from-file=auth_config.json
```

## Vérification avant chaque commit

```powershell
git status --short
```

`auth_config.json` ne doit jamais apparaître dans la liste des fichiers à
ajouter au commit.

## Limite de cette protection

Cette configuration évite de publier les mots de passe dans le dépôt Git et
sépare les fonctions propriétaire et employé. Une application Flutter Web
reste toutefois exécutée sur le poste client. Pour une protection forte contre
un utilisateur ayant accès au navigateur, aux fichiers ou à la base locale,
l’authentification et les autorisations devront être vérifiées par un serveur.
