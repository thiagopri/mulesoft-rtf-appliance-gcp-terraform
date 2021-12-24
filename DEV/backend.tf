terraform {
  backend "gcs" {
    bucket = "rtf-lab-terraform-state-gcs-dev"
    prefix = "DEV"
    credentials = ("../creds/creds-dev.json")
  }
}

