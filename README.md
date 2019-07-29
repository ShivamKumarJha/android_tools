
# Android tools
Collection of my scripts.  
  
Usage:  
`chmod +x tools/*`  
`./tools/<script.sh>`
  
1. **common_blobs.sh**: A script to list common and device specific blob's between two ROM's.  
Usage:  
`./tools/common_blobs.sh <path to source rom> <path to target rom>`

2. **common_props.sh**: A script to list common and device specific prop's between two ROM's.  
Usage:  
`./tools/common_props.sh <path to source rom> <path to target rom>`

3. **dummy_dt.sh**: A script which prepares a dummy device tree from ROM dump. Can handle dump stored both locally OR in online git repository (as long as all_files.txt exists in its root). See its GitHub [repo](https://github.com/ShivamKumarJha/Dummy_DT/).  
Usage:  
Usage: `./tools/dummy_dt.sh <path to ROM dump OR raw link of dump repo>`  
*Optional*:  
To push Dummy_DT repository, `export GIT_TOKEN=<TOKEN>` before running script.  
For Telegram notification, `export TG_API=<KEY>` before running script.

4. **manifest_parser.sh**: A script to parse manifest xml(s) so it clones only relevant repo's with full depth.  
Usage:  
`./tools/manifest_parser.sh <path to xml(s)>`

5. **proprietary-files.sh**: A script to prepare proprietary blobs list from ROM.  
Usage:  
For online git repo: `./tools/proprietary-files.sh <raw file link of all_files.txt>`  
For local dump: `./tools/proprietary-files.sh <full path to ROM dump>`

6. **rom_compare.sh**: A script to compare source & target ROM. It lists `Added, common, missing & modified` blobs.  
Usage:  
`./tools/rom_compare.sh <full path to source ROM dump> <full path to target ROM dump>`

7. **rom_extract.sh**: A script to extract OTA files.  
Usage:  
`./tools/rom_extract.sh <path to OTA file(s)>`

8. **rootdir.sh**: A script to prepare rootdir from a ROM dump along with Makefile.  
Usage:  
`./tools/rootdir.sh <full path to ROM dump>`

9. **system_vendor_prop.sh**: A script to prepare properties Makefile from a ROM dump.  
Usage:  
For non treble ROM's: `./tools/system_vendor_prop.sh <full path to ROM dump>/system/build.prop`  
For treble ROM's: `./tools/system_vendor_prop.sh <full path to ROM dump>/system/build.prop <full path to ROM dump>/system/vendor/build.prop`  
Output: `system.prop` & `vendor_prop.mk` files.  

10. **vendor_prop.sh**: A script to prepare and filter properties Makefile from a ROM dump.  
Usage:  
For non treble ROM's: `./tools/vendor_prop.sh <full path to ROM dump>/system/build.prop`  
For treble ROM's: `./tools/vendor_prop.sh <full path to ROM dump>/system/build.prop <full path to ROM dump>/system/vendor/build.prop`  
Output: `vendor_prop.mk` file.  
