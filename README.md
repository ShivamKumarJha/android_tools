
# Android tools
Collection of my scripts.  
  
Usage:  
`chmod +x tools/*`  
`./tools/<script.sh>`
  

1. **common_blobs.sh**: A script to list common and device specific blob's between two ROM's.  
Usage:  
`./tools/common_blobs.sh <path to source rom> <path to target rom>`

2. **dummy_dt.sh**: A script which prepares a dummy device tree from ROM dump. Can handle dump stored both locally OR in online git repository (as long as all_files.txt exists in its root). See its GitHub [repo](https://github.com/ShivamKumarJha/Dummy_DT/).  
Usage:  
From online git repo's stored in `tools/lists/roms.txt`: `./tools/dummy_dt.sh`  
From local dumps: `./tools/dummy_dt.sh <full path to ROM dump>`  
*Optional*:  
To push Dummy_DT repository, `export GIT_TOKEN=<TOKEN>` before running script.  
For Telegram notification, `export TG_API=<KEY>` before running script.

3. **manifest_parser.sh**: A script to parse manifest xml(s) so it clones only relevant repo's with full depth.  
Usage:  
`./tools/manifest_parser.sh <path to xml(s)>`

4. **proprietary-files.sh**: A script to prepare proprietary blobs list from ROM.  
Usage:  
For online git repo: `./tools/proprietary-files.sh <raw file link of all_files.txt>`  
For local dump: `./tools/proprietary-files.sh <full path to ROM dump>`

5. **rom_compare.sh**: A script to compare source & target ROM. It lists `Added, common, missing & modified` blobs.  
Usage:  
`./tools/rom_compare.sh <full path to source ROM dump> <full path to target ROM dump>`

6. **rom_extract.sh**: A script to extract ROM zip. Supports A only, A/B & fastboot images.  
Usage:  
Place ROM(s) to `input/` folder & run script.  
`./tools/rom_extract.sh` OR `./tools/rom_extract.sh <user password> <push repo (y/n)>`  

7. **rootdir.sh**: A script to prepare rootdir from a ROM dump along with Makefile.  
Usage:  
`./tools/rootdir.sh <full path to ROM dump>`

8. **system_vendor_prop.sh**: A script to prepare properties Makefile from a ROM dump.  
Usage:  
For non treble ROM's: `./tools/system_vendor_prop.sh <full path to ROM dump>/system/build.prop`  
For treble ROM's: `./tools/system_vendor_prop.sh <full path to ROM dump>/system/build.prop <full path to ROM dump>/system/vendor/build.prop`  
Output: `system.prop` & `vendor_prop.mk` files.  

9. **vendor_prop.sh**: A script to prepare and filter properties Makefile from a ROM dump.  
Usage:  
For non treble ROM's: `./tools/vendor_prop.sh <full path to ROM dump>/system/build.prop`  
For treble ROM's: `./tools/vendor_prop.sh <full path to ROM dump>/system/build.prop <full path to ROM dump>/system/vendor/build.prop`  
Output: `vendor_prop.mk` file.  
