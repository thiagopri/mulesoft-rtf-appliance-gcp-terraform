terraform {
  backend "gcs" {
    bucket = "rtf-lab-terraform-state-gcs-prod"
    prefix = "PROD"
    credentials = ("../creds/creds-prod.json")
  }
}

