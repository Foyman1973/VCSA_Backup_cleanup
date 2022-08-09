# VMware VCSA 6.7 / 7.0 Backup Cleanup
### This PowerShell script is designed to enforce clean-up of VMware VCSA backups

There is a bug in the VMware VCSA backup retention clean-up for VCSA 6.7 and 7.0.  While the bug has been resolved for 6.7 in U3B, as of this writing the bug is still present in VCSA 7.0 as of U3F.

[VMware KB article 70823](https://kb.vmware.com/s/article/70823)

If you are using a Windows server as an FTPS destination for your VCSA backups, this script can be run as a Scheduled Task to enforce the retention policy clean-up.

Modify lines 2 - 9 for your environment and either run the script manually or via Scheduled Task to clean up older backups.
