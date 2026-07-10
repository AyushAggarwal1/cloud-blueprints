## New GCP Terraform

- Run the terraform
Login on Cli

```bash
 gcloud auth application-default login
```

Output

```bash
secret_name = "projects/{{project-number}}/secrets/accuknox-sa-key"
service_account_email = "my-service-account@{{project-id}}.iam.gserviceaccount.com"
```

- Steps to extract the secret from GCP Secret Manager:
    - Login to GCP Console
    - From the Left Menu, go to Security -> Secret Manager
    - or, Search in Search Bar `Secret Manager`
    - You'll see `accuknox-sa-key` in the list — click it
    - Click the "Versions" tab
    - Get the Key and Save

- Or via Cloud Shell:
```bash
  gcloud secrets versions access latest \
    --secret="accuknox-sa-key" \
    --project="{{project-id}}"
```