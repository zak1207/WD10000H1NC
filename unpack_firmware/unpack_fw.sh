#!/bin/sh
# unpack_fw.sh	- written by blip@mockmoon-cybernetics.ch
# Changelog:
# 16.10.2013: Removed download since it doesn't work any longer
# 21.09.2009: Added autodetect of newest firmware version - Blip
# 04.09.2009: Corrected the bug mentioned by frater. Thank you, frater.

if [ $# -ne 1 ]; then
	echo usage: $0 firmware-file
	exit 1
fi
# only change if you know what you are doing. upgrade1.sh relies on this.
UPGRADE_DIR="/var/upgrade"

fw_dir="/var/upgrade_download"
fw_img="test_fw.img"
tmp_img1="$fw_dir/img.tmp.1"
tmp_img2="$fw_dir/img.tmp.2"

# Make the download directory
if [ ! -d $fw_dir ]; then
	mkdir $fw_dir
	if [ "$?" -ne 0 ]; then
		exit 1
	fi
fi
cp $1 $fw_dir/$fw_img
cd $fw_dir
# "decode" the firmware image
dd skip=0 count=1 bs=5120 if=$fw_dir/$fw_img of=$tmp_img1 2>/dev/null
dd skip=15 count=1 bs=5120 if=$fw_dir/$fw_img of=$tmp_img2 2>/dev/null
cp $fw_dir/$fw_img $fw_dir/$fw_img.orig
dd seek=0 count=1 bs=5120 if=$tmp_img2 of=$fw_dir/$fw_img 2>/dev/null
dd skip=1 seek=1 bs=5120 if=$fw_dir/$fw_img.orig of=$fw_dir/$fw_img 2>/dev/null
cp $fw_dir/$fw_img $fw_dir/$fw_img.orig
dd seek=15 count=1 bs=5120 if=$tmp_img1 of=$fw_dir/$fw_img 2>/dev/null
dd skip=16 seek=16 bs=5120 if=$fw_dir/$fw_img.orig of=$fw_dir/$fw_img 2>/dev/null
# clean up the "decoding"
rm $tmp_img1
rm $tmp_img2
rm $fw_dir/$fw_img.orig
# unpack the image
tar zxf $fw_img -C $fw_dir
# check if md5sum matches
md5sum -c upgrd-pkg-1nc.wdg.md5 > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
	echo "md5sum of upgrd-pkg-1nc.wdg does not match"
	exit 3
fi
# execute the file - it unpacks itself to /var/upgrade
$fw_dir/upgrd-pkg-1nc.wdg
# check md5sums
cd $UPGRADE_DIR
md5sum -c md5sum.lst > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
	echo "some checksum error in md5sum.lst"
	exit 5
fi
# then run upgrade script
echo "Now run \"nohup $UPGRADE_DIR/upgrade1.sh &\""
