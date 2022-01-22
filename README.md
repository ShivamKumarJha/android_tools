
# Android tools
Collection of scripts to help with Android ROM stuff.  
  
**Setup**:  
`chmod +x setup.sh`  
`sudo bash setup.sh`
  
1. **blobs_downloader.sh**: A script to download selected blobs from [AndroidBlobs](https://github.com/AndroidBlobs) etc repo. [Example](https://del.dog/olohilylon.txt).  
Usage: `./tools/blobs_downloader.sh <raw dump repo URL> <path to proprietary-files.txt>`

2. **common_blobs.sh**: A script to list common and device specific blob's between two ROM's.  
Usage: `./tools/common_blobs.sh <path to source rom dump> <path to target rom dump>`

3. **common_props.sh**: A script to list common and device specific prop's between two ROM's.  
Usage: `./tools/common_props.sh <path to source rom dump> <path to target rom dump>`

4. **deltaota.sh**: A script to extract delta OTA.  
Usage: `./tools/deltaota.sh <path to full OTA> <path to incremental OTA(s)>`

5. **dt_repos.sh**: A script to create empty device, kernel & vendor tree of a device in GitHub with model as repo descripton.
Usage:  
`export GIT_TOKEN=<KEY>`  
`./tools/dt_repos.sh <path to rom>`

6. **dummy_dt.sh**: A script which prepares a dummy device & vendor tree from a ROM dump.  
Usage: `./tools/dummy_dt.sh <path to ROM dump>`

7. **dump_push.sh**: A script to push local ROM dump to GitHub.  
Usage:  
`export GIT_TOKEN=<KEY>`  
`./tools/dump_push.sh <path to dump>`

8. **proprietary-files.sh**: A script to prepare proprietary blobs list from a ROM.  
Usage:  
For online git repo: `./tools/proprietary-files.sh <raw file link of all_files.txt>`  
For local dump: `./tools/proprietary-files.sh <path to ROM dump OR path to all_files.txt>`

9. **rebase_kernel.sh**: A script to rebase OEM compressed kernel source to its best CAF base.  
Usage: `./tools/rebase_kernel.sh <kernel zip link/file> <repo name>`

10. **rom_compare.sh**: A script to compare source & target ROM. It lists `Added, common, missing & modified` blobs.  
Usage: `./tools/rom_compare.sh <path to source ROM dump> <path to target ROM dump>`

11. **rom_extract.sh**: A script to extract OTA files.  
Usage: `./tools/rom_extract.sh <path to OTA file(s)>`

12. **rootdir.sh**: A script to prepare ramdisk from a ROM dump along with Makefile.  
Usage: `./tools/rootdir.sh <path to ROM dump>`

13. **system_vendor_prop.sh**: A script to prepare properties Makefile from a ROM dump. (Does not support lahaina, use vendor_prop.sh instead)  
Usage: `./tools/system_vendor_prop.sh <path to ROM dump>`  
Output: `system.prop` & `vendor_prop.mk` files.  

14. **vendor_prop.sh**: A script to prepare and filter properties Makefile from a ROM dump.  
Usage: `./tools/vendor_prop.sh <path to ROM dump>`  
Output: `vendor_prop.mk` file.  

15. **vendor_tree.sh**: A script to prepare vendor tree from a ROM dump after generating proprietary-files.txt and push it to GitHub.  
To extract from a specific proprietary-files.txt, place it before in `working/proprietary-files.txt`.  
Usage:  
`export GIT_TOKEN=<KEY>`  
`./tools/vendor_tree.sh <path to ROM dump>`  
