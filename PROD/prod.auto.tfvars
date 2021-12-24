# PROJECT VARS
# Project Id 
project_id              = "lab-rtf-terraform-prod"
# GCP authentication file
gcp_auth_file           = "../creds/creds-prod.json"
prefix                  = ""
postfix                 = "-prod"
region                  = "northamerica-northeast2"
gcp_user                = "thiagoprispam"
rtf_name                = "rtf-lab-prod"
rtf_version             = ""
rtf_appliance_version   = ""
rtf_activation_data     = ""
rtf_mule_license        = ""
# If you have VPC and subnet shared from another project, you can include the self_link here. Otherwise, a new one will be created
shared_vpc_name         = "projects/lab-rtf-terraform-prod/global/networks/default"
shared_subnet_name      = "projects/lab-rtf-terraform-prod/regions/northamerica-northeast2/subnetworks/default" 
# If you don't have VPC and subnet shared from another project, you must specify the values
vpc_name                = "rtf-vpc"
subnet_name             = "rtf-subnet"
ssh_keys                = ""
create_https_lb         = false
create_http_lb          = false
default_lb_name         = "rtf-lb"
default_lb_external_ip  = "34.149.145.51"
managed_cert_name       = ""
boot_image              = {
          source = "projects/confidential-vm-images/global/images/ubuntu-1804-bionic-v20211214"
          size = "80"
          type = "pd-standard"
}
rtf_cluster         = {
    controllers = {
        controller-1 = {
            ip = "10.188.1.1",
            machine_type = "custom-2-8192",
            tags = ["rtf-controller", "rtf-prod", "allow-health-check"],
            install_role = "leader",
            node_role = "controller_node",
            leader_ip = "",
            zone = "northamerica-northeast2-a",
            disks = {
                1 = {
                    type = "pd-ssd",
                    size = "80" 
                },
                2 = {
                    type = "pd-ssd",
                    size = "250" 
                }
            }
        },
        controller-2 = {
            ip = "10.188.1.2",
            machine_type = "custom-2-8192",
            tags = ["rtf-controller", "rtf-prod", "allow-health-check"],
            install_role = "joiner",
            node_role = "controller_node",
            leader_ip = "10.188.1.1",
            zone = "northamerica-northeast2-b",
            disks = {
                1 = {
                    type = "pd-ssd",
                    size = "80" 
                },
                2 = {
                    type = "pd-ssd",
                    size = "250" 
                }
            }
        },
        controller-3 = {
            ip = "10.188.1.3",
            machine_type = "custom-2-8192",
            tags = ["rtf-controller", "rtf-prod", "allow-health-check"],
            install_role = "joiner",
            node_role = "controller_node",
            leader_ip = "10.188.1.1",
            zone = "northamerica-northeast2-c",
            disks = {
                1 = {
                    type = "pd-ssd",
                    size = "80" 
                },
                2 = {
                    type = "pd-ssd",
                    size = "250" 
                }
            }
        }                  
    },
    workers = {
        worker-1 = {
            ip = "10.188.1.4",
            machine_type = "n2-highmem-2",
            tags = ["rtf-worker", "rtf-prod"],
            install_role = "joiner",
            node_role = "worker_node",
            leader_ip = "10.188.1.1",
            zone = "northamerica-northeast2-a",
            disks = {
                1 = {
                    type = "pd-ssd",
                    size = "250" 
                }
            }
        },
        worker-2 = {
            ip = "10.188.1.5",
            machine_type = "n2-highmem-2",
            tags = ["rtf-worker", "rtf-prod"],
            install_role = "joiner",
            node_role = "worker_node",
            leader_ip = "10.188.1.1",
            zone = "northamerica-northeast2-b",
            disks = {
                1 = {
                    type = "pd-ssd",
                    size = "250" 
                }
            }
        },
        worker-3 = {
            ip = "10.188.1.6",
            machine_type = "n2-highmem-2",
            tags = ["rtf-worker", "rtf-prod"],
            install_role = "joiner",
            node_role = "worker_node",
            leader_ip = "10.188.1.1",
            zone = "northamerica-northeast2-c",
            disks = {
                1 = {
                    type = "pd-ssd",
                    size = "250" 
                }
            }
        }        
    }

  }
