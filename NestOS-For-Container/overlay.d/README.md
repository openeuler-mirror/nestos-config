05core
-----

This overlay matches `nestos-base.yaml`; core Ignition+ostree bits.



11install
---------

Scripts and config template for quickly installing OS on hard disk

14NetworkManager-plugins
------------------------

Disables the Red Hat Linux legacy `ifcfg` format.

15nestos
------

Things that are more closely "NestOS":

* disable password logins by default over SSH
* enable SSH keys written by Ignition and Afterburn
* branding (MOTD)
* enable services by default 
* display warnings on the console if no ignition config was provided or no ssh
  key found.


18fwupd-refresh-timer
---------------------

Enable fwupd-refresh.timer on Fedora 39:
https://fedoraproject.org/wiki/Changes/EnableFwupdRefreshByDefault

20platform-chrony
-----------------

Add static chrony configuration for NTP servers provided on platforms
such as `azure`, `aws`, `gcp`. The chrony config for these NTP servers
should override other chrony configuration (e.g. DHCP-provided)
configuration.
