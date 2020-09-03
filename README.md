Create a Sandpit AD FS Service
==============================

1. Build a Windows VM
 * Enable winrm basic auth because that's what our client library needs
 * Deploy with a Let's Encrypt signed cert because we'll need that too
2. Install Active Directory Domain Services (AD DS aka AD)
 * Ensure the AD support tools (RSAT AD DS Tools) are installed as well ??? Maybe 
3. Configure AD DS
4. Add a normal user to AD DS
5. Add a gMSA (group managed service account)
5. Install AD FS
6. Run the magic add key thing
7. Configure AD FS
 * Use the same cert that we used for winrm when creating the VM
 * Use the gmsa created earlier  