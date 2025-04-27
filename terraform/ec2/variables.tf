# variables.tf
variable "config" {
  description = "Path to the modules config file"
  type        = string
  default     = "config.yml"

  validation {
    condition = can(
      yamldecode(file(var.config)).ansible.host
    )
    error_message = "Your configuration file must contain an 'ansible.host' section."
  }

  validation {
    condition = (
      can(yamldecode(file(var.config)).ansible.host.ansible_user) &&
      can(yamldecode(file(var.config)).ansible.host.ansible_ssh_private_key_file) &&
      can(yamldecode(file(var.config)).ansible.host.ansible_python_interpreter)
    )
    error_message = "The 'ansible.host' section must define ansible_user, ansible_ssh_private_key_file, and ansible_python_interpreter."
  }
}
