# TP5 - AWS SSM + Lambda + IAM least privilege + rotation applicative

## Prérequis
- Une VM Linux ou Windows avec accès Internet
- Terraform installé (`terraform version`)
- AWS CLI installé (`aws --version`)
- Un compte AWS avec des droits suffisants pour créer IAM, Lambda, SSM, KMS et CloudWatch Logs

## Connexion AWS
Configure ton accès AWS avec l'une des méthodes suivantes :
1. `aws configure`
2. variables d'environnement `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` si besoin
3. profil nommé AWS (`AWS_PROFILE=...`)

Teste ensuite :
```bash
aws sts get-caller-identity
```

## Déploiement
```bash
terraform init
terraform apply -var="name_suffix=groupe5"
```

## Vérifications à faire dans AWS
1. **SSM Parameter Store**
   - `/tp5/app/DB_HOST`
   - `/tp5/app/API_TOKEN`
2. **IAM**
   - rôle Lambda avec uniquement `ssm:GetParametersByPath` sur `/tp5/app/*`
3. **Lambda**
   - fonction `tp5-cloudsec-groupe5-ssm-reader`
4. **CloudWatch Logs**
   - aucun secret en clair dans les logs

## Test de la Lambda
### Console AWS
- Ouvre la Lambda
- Clique sur **Test**
- Lance l'exécution avec un event JSON vide `{}`

### AWS CLI
```bash
aws lambda invoke \
  --function-name tp5-cloudsec-groupe5-ssm-reader \
  --payload '{}' \
  response.json

cat response.json
```

## Rotation applicative du token
Le but est de mettre à jour le paramètre sans toucher au code de la Lambda.

```bash
aws ssm put-parameter \
  --name /tp5/app/API_TOKEN \
  --type SecureString \
  --value "DUMMY_TOKEN_V2" \
  --overwrite \
  --region eu-west-3
```

Relance ensuite le test de la Lambda.
Tu dois constater :
- aucun secret affiché
- la **version** du paramètre `API_TOKEN` augmente
- les logs restent propres

## Destruction
```bash
terraform destroy -var="name_suffix=groupe5"
```
