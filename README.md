
# Azure VHD utilities.

This project provides a Go package to read Virtual Hard Disk (VHD) file, a CLI interface to upload local VHD to Azure storage and to inspect a local VHD.

An implementation of VHD [VHD specification](https://technet.microsoft.com/en-us/virtualization/bb676673.aspx) can be found in the [vhdcore](/vhdcore) package. 


[![Go Report Card](https://goreportcard.com/badge/github.com/Microsoft/azure-vhd-utils)](https://goreportcard.com/report/github.com/Microsoft/azure-vhd-utils)

# Installation
> Note: You must have Go installed on your machine, at version 1.11 or greater. [https://golang.org/dl/](https://golang.org/dl/) 

    go get github.com/Microsoft/azure-vhd-utils

# Features

1. Fast uploads - This tool offers faster uploads by using multiple routines and balancing the load across them.
2. Efficient uploads - This tool will only upload used (non-zero) portions of the disk.
3. Parallelism - This tool can upload segements of the VHD concurrently (user configurable).

# Usage

### Upload local VHD to Azure storage as page blob

```bash
USAGE:
   azure-vhd-utils upload [command options] [arguments...]

OPTIONS:
   --localvhdpath       Path to source VHD in the local machine.
   --stgaccountname     Azure storage account name.
   --stgaccountkey      Azure storage account key.
   --stgaccountkeyfile  Path to file containing Azure storage account key.
   --containername      Name of the container holding destination page blob. (Default: vhds)
   --blobname           Name of the destination page blob.
   --parallelism        Number of concurrent goroutines to be used for upload
```

The upload command uploads local VHD to Azure storage as page blob. Once uploaded, you can use Microsoft Azure portal to register an image based on this page blob and use it to create Azure Virtual Machines.

#### Note
When creating a VHD for Microsoft Azure, the size of the VHD must be a whole number in megabytes, otherwise you will see an error similar to the following when you attempt to create image from the uploaded VHD in Azure:

"The VHD http://<mystorageaccount>.blob.core.windows.net/vhds/<vhd-pageblob-name>.vhd has an unsupported virtual size of <number> bytes. The size must be a whole number (in MBs)."

You should ensure the VHD size is even MB before uploading

##### For virtual box:
-------------------
VBoxManage modifyhd <absolute path to file> --resize &lt;size in MB&gt;

##### For Hyper V:
----------------
Resize-VHD -Path <absolute path to file> -SizeBytes 

     http://azure.microsoft.com/blog/2014/05/22/running-freebsd-in-azure/

##### For Qemu:
-------------
qemu-img resize &lt;path-to-raw-file&gt; size

     http://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-create-upload-vhd-generic/
 
#### How upload work

Azure requires VHD to be in Fixed Disk format. The command converts Dynamic and Differencing Disk to Fixed Disk during upload process, the conversion will not consume any additional space in local machine.

In case of Fixed Disk, the command detects blocks containing zeros and those will not be uploaded. In case of expandable disks (dynamic and differencing) only the blocks those are marked as non-empty in
the Block Allocation Table (BAT) will be uploaded.

The blocks containing data will be uploaded as chunks of 2 MB pages. Consecutive blocks will be merged to create 2 MB pages if the block size of disk is less than 2 MB. If the block size is greater than 2 MB, 
tool will split them as 2 MB pages.  

With page blob, we can upload multiple pages in parallel to decrease upload time. The command accepts the number of concurrent goroutines to use for upload through parallelism parameter. If the parallelism parameter is not proivded then it default to 8 * number_of_cpus.

### Inspect local VHD

A subset of command are exposed under inspect command for inspecting various segments of VHD in the local machine.

#### Show VHD footer

```bash
USAGE:
   azure-vhd-utils inspect footer [command options] [arguments...]

OPTIONS:
   --path   Path to VHD.
```

#### Show VHD header of an expandable disk

```bash
USAGE:
   azure-vhd-utils inspect header [command options] [arguments...]

OPTIONS:
   --path   Path to VHD.
```

Only expandable disks (dynamic and differencing) VHDs has header.

#### Show Block Allocation Table (BAT) of an expandable disk

```bash
USAGE:
   azure-vhd-utils inspect bat [command options] [arguments...]

OPTIONS:
   --path           Path to VHD.
   --start-range    Start range.
   --end-range      End range.
   --skip-empty     Do not show BAT entries pointing to empty blocks.
```

Only expandable disks (dynamic and differencing) VHDs has BAT.

#### Show block general information

```bash
USAGE:
   azure-vhd-utils inspect block info [command options] [arguments...]

OPTIONS:
   --path   Path to VHD.
```

This command shows the total number blocks, block size and size of block sector

### Show sector bitmap of an expandable disk's block

```bash
USAGE:
   azure-vhd-utils inspect block bitmap [command options] [arguments...]

OPTIONS:
   --path           Path to VHD.
   --block-index    Index of the block.
   
```

# License

This project is published under [MIT License](LICENSE).
