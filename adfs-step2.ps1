Install-WindowsFeature ADfs-federation

Add-KdsRootKey -EffectiveTime (Get-Date).AddHours(-10)

Import-Module ADFS

Install-AdfsFarm `
-CertificateThumbprint:"${azurerm_key_vault_certificate.example.thumbprint}" `
-FederationServiceDisplayName:"The Sandpit" `
-FederationServiceName:"adfs-sandpit.australiaeast.cloudapp.azure.com" `
-GroupServiceAccountIdentifier:"SANDPIT\adfs`$"

# New – ADServiceAccount – name gmsa1 – DNSHostNamedc1.example.com – PrincipalsAllowedToRetrieveManagedPassword "gmsa1Group"

# New-ADServiceAccount -Name adfs`$ -DNSHostName  adfs-sandpit.sandpit.local
# ????

# https://adfs-sandpit.atfldev.com/FederationMetadata/2007-06/FederationMetadata.xml

# UserPrincipalName
# mail
# GivenName
# sn

# https://sentry.atfldev.com/saml/metadata/sentry/