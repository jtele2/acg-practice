# EC2 Readme

## Host Setup

- Install [ansible-galaxy cloud.terraform collection](https://github.com/ansible-collections/cloud.terraform)
- Install golang
- Install terraform
- Install uv
- Install ansible with uv

```shell
ansible-galaxy collection install cloud.terraform
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
brew install go uv 
uv add ansible
```

## Terraform Setup

1. First run `tfa -auto-approve`
2. Update the `ansible/inventory.yml` with the public ip of the instance
3. Run `ansible learn -m ping -i ansible/inventory.yml`
4. Run `ansible-playbook -i ansible/inventory.yml ansible/playbook.yml`
