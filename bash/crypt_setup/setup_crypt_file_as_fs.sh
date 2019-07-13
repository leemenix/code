#!/bin/bash

# Initial FS Creation
# I typically encrypt files, not whole partitions, so I combine dm-crypt with the losetup loopback device maintenance tool. In the bare language of the Unix shell, here are the steps to create and mount an encrypted filesystem.

# Create an empty file sized to suit your needs. 
prepare_file() {
	
	local FILE_NAME=$1
	local MOUNT_POINT=$2
        local FILE_SIZE=$3

	dd of=~/${FILE_NAME} bs=${FILE_SIZE}G count=0 seek=1
	# Lock down normal access to the file
	chmod 600 ~/${FILE_NAME}
	# Associate a loopback device with the file
	losetup /dev/loop0 ~/${FILE_NAME}
	# Encrypt storage in the device. cryptsetup will use the Linux
	# device mapper to create, in this case, /dev/mapper/${FILE_NAME}.
	# The -y option specifies that you'll be prompted to type the
	# passphrase twice (once for verification).
	##cryptsetup -y create ${FILE_NAME} /dev/loop0
	# Or, if you want to use LUKS, you should use the following two
	# commands (optionally with additional) parameters. The first
	# command initializes the volume, and sets an initial key. The
	# second command opens the partition, and creates a mapping
	# (in this case /dev/mapper/${FILE_NAME}).
	cryptsetup -y luksFormat /dev/loop0
	cryptsetup luksOpen /dev/loop0 ${FILE_NAME}
	# Check its status (optional)
	cryptsetup status ${FILE_NAME}
	# Now, we will write zeros to the new encrypted device. This
	# will force the allocation of data blocks. And since the zeros
	# are encrypted, this will look like random data to the outside
	# world, making it nearly impossible to track down encrypted
	# data blocks if someone gains access to the file that holds
	# the encrypted filesystem.
	dd if=/dev/zero of=/dev/mapper/${FILE_NAME}
	# Create a filesystem and verify its status
	mke2fs -j -O dir_index /dev/mapper/${FILE_NAME}
	tune2fs -l /dev/mapper/${FILE_NAME}
	# Mount the new filesystem in a convenient location
	mkdir -p ${MOUNT_POINT}/${FILE_NAME}
	mount /dev/mapper/${FILE_NAME} ${MOUNT_POINT}/${FILE_NAME} 
}

unmount_crypto_fs() {
	local FILE_NAME=$1
	local MOUNT_POINT=$2
	# Unmount the filesystem
	umount ${MOUNT_POINT}
	## Remove device mapping
	#cryptsetup remove ${FILE_NAME}
	## Or, for a LUKS volume
	cryptsetup luksClose ${FILE_NAME}
	## Disassociate file from loopback device
	losetup -d /dev/loop0
}


#
#Remount Encrypted Filesystem
#
#Once you've created an encrypted filesystem, remounting it is a relatively short process:
#
mount_crypto_fs(){
	local FILE_PATH=$1
	local FILE_NAME=$2
	local MOUNT_POINT=$3
	## Associate a loopback device with the file
	losetup /dev/loop0 ${FILE_PATH}/${FILE_NAME}
	## Encrypt mapped device; you'll be prompted for the password
	#cryptsetup create ${FILE_NAME} /dev/loop0
	## Or, for a LUKS volume
	cryptsetup luksOpen /dev/loop0 ${FILE_NAME}
	## Mount the filesystem
	mount /dev/mapper/${FILE_NAME} ${MOUNT_POINT}
}

#####MAIN
mount_firefox_fs() {
	mount_crypto_fs /root firefox_fs /home/leemenix/firefox
	chown leemenix.users -R /home/leemenix/firefox
}

umount_firefox_fs() {
	unmount_crypto_fs firefox_fs /home/leemenix/firefox
}
#
#Note that cryptsetup will not provide a useful error message if you mistype the passphrase. All you'll get is a somewhat unhelpful message from mount:
#
#    mount: you must specify the filesystem type 
#
#    If that happens, then recycle cryptsetup and try mounting the filesystem again:
#
#    cryptsetup remove secretfs
#    cryptsetup create secretfs /dev/loop0
#    mount /dev/mapper/secretfs /mnt/cryptofs/secretfs
#
#    This does not apply to LUKS volumes, where cryptsetup will provide a useful error message during the luksOpen step.
#
#    Adding additional keys to a LUKS volume
#
#    As mentioned earlier, the LUKS format allows for the use of multiple keys. This means that you can add more than one key that can be used to open the encrypted device. Adding a key can simply be done with:
#
#    cryptsetup luksAddKey <device>
#
#    For instance, if you use the /dev/loop0 loopback device, you could execute:
#
#    cryptsetup luksAddKey /dev/loop0
#
#    cryptsetup will ask you to enter one of the existing passphrases twice. After that you will be asked to enter the additional key twice. When this step is also succesfully completed, you can use the existing key(s), and the new key to open the volume.
#
#    Setting up encrypted volumes during system boot
#
#    Sometimes you may want to set up encrypted volumes during the system boot, for instance, to set up an encrypted home partition for a laptop. This can be done easily on CentOS 5 through /etc/crypttab. /etc/crypttab describes encrypted volumes and partitions for which a mapping should be set up during the system boot. Entries are separated by a newline, and contain the following fields:
#
#    mappingname        devicename        password_file_path        options
#
#    Though, normally you don't need all four fields:
#
#        Most of the possible options for the options field are ignored for LUKS volumes, because LUKS volumes have all the necessary information about the cipher, key size, and hash in the volume header. Second,
#
#	    Normally, you don't want to store a password file in plain text on the root partition. It's certainly possible to store it somewhere else, but at this boot stage in rc.sysinit only the root partition is normally mounted read-only. If the password field is not present, or has the value none, the system will prompt for the password during the system boot. 
#
#	    So, if you are using a LUKS volume and would like to prompt the system for a password, only the first two fields are required. Let's look at a short example:
#
#	    cryptedHome        /dev/sdc5
#
#	    This creates a mapping named cryptedHome for an encrypted volume that was previously created on /dev/sdc5 with crypsetup luksFormat /dev/sdc5. If you have also created a filesystem on the encrypted volume, you can also add an /etc/fstab entry to mount the filesystem during the system boot:
#
#	    /dev/mapper/cryptedHome       /home        ext3    defaults        1 2
#
#	    There are two options that are not ignored for LUKS partitions:
#
#	        swap: the volume will be formatted as a swap partition after a mapping is set up.
#
#		    tmp: the volume will be formatted as an ext2 filesystem, with permissions set up correctly to be used as a filesystem for temporary files. 
#
#		    Both options require that there are entries for using the mapping in /etc/fstab, and both options are destructive. An entry for an encrypted swap partition could look like this:
#
#		    cryptedSwap        /dev/sda2        none        swap
#
#		    Or if you do not want to type a password for the swap partition during every boot:
#
#		    cryptedSwap        /dev/sda2        /dev/urandom        swap
#
#		    Note that this will not work if /dev/sda2 already is a LUKS partition, because LUKS partitions require a non-random key. 
