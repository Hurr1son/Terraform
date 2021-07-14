resource "google_storage_bucket" "chisto_state" {
  project       = "deploy-315515"
  name          = "chisto-state"
  location      = "us-east1"
  force_destroy = true
  storage_class = "standard"
  versioning {
    enabled = true
  }
}

terraform{
backend "gcs"{
bucket = "chisto-state"
prefix = "gcppoj/terraform.tfstate"
credentials = "terraform.json"
}
}
