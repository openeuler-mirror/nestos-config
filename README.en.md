# NestOS-Config

NestOS is a cloud-based operating system incubated in the openEuler community, integrating technologies such as rpm-ostree support and ignition  configuration.


This repository is the basic configuration file required to build NestOS. 

## About this code warehouse

- The manifest folder contains a number of .yaml configuration files, and  packages are categorized into these configuration files according to  their function/use case.
- The files in the overlay.d folder can overwrite the initial files provided  by the package according to their directory structure.
- manifest.ymal contains the name of the stream used for the update, as well as the releasever.

If you still have any questions about the use of specific parameters in  other configuration files, you can submit an issue to this repository,  or join sig-CloudNative or sig-K8sDistro to communicate with developers. 

## Warehouse update process

1. Bump releasever in manifest.yaml
2. Update the repos in manifest.yaml if needed
3. Run nosa fetch --update-lockfile
4. PR the result
