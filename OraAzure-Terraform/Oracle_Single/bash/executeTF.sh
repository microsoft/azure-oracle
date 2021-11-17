cd ..
export ANSIBLE_HOST_KEY_CHECKING=False
terraform init -var-file=oracle_template.tfvars
terraform apply -auto-approve -var-file=oracle_template.tfvars
