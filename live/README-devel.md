These files will be copied to the target live ISO
via the NestOS Assembler buildextend-live call. It
picks up all files in the nestos-config/live/
directory and copies them to the base of the ISO. 

Files currently copied are:

- isolinux/boot.msg
- isolinux/isolinux.cfg

Files that get copied into efiboot.img in the ISO:

- EFI/grub.cfg 
