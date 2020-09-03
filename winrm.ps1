#
# Enable Basic auth because that's all that is supported by the
# client library that is used by Terraform.
#

winrm set winrm/config/service/Auth '@{Basic="true"}'
