#!/bin/bash

# Q2 Kicker helper v1.0
#
# Written by SquareHimself
#	 WTFPL :: http://en.wikipedia.org/wiki/WTFPL
#
# Thank you to jdolan for his patches to aprq2.
# Please visit his site at http://jdolan.dyndns.org
#
# Also, thank you to Jehar for providing both the
# kicker, hosting, tastyspleen.tv, etc...
#
# TODO: - Allow for choosing cleancode over aprq2's DLL
#

### This script must be run in a terminal.
[ -t 0 ] || exit 1

### Let's make some functions for a cleaner procedure later.
function FetchSources {
mkdir /tmp/aprq2
cd /tmp/aprq2
svn co svn://jdolan.dyndns.org/aprq2/trunk
if [ -e '/tmp/aprq2/trunk/Makefile' ]; then
	echo "==> Sources acquired."
else
	echo "==> Sources were not downloaded. Aborting."
	exit 1
fi
}

### These menus... <3
function MusicOption {
MUSICP="MPD XMMS No"
select choice in $MUSICP; do
	if [ "$choice" = "MPD" ]; then
		sed -i 's/BUILD_MPD=NO/BUILD_MPD=YES/g' /tmp/aprq2/trunk/Makefile
		echo "==> Selecting MPD."
		return
	elif [ "$choice" = "XMMS" ]; then
		sed -i 's/BUILD_XMMS=NO/BUILD_XMMS=YES/g' /tmp/aprq2/trunk/Makefile
		echo "==> Selecting XMMS."
		return
	else
		echo "==> Not enabling MPD or XMMS support."
		return
	fi
done
}

function OpenALOption {
CHOICES="Yes No"
select choice in $CHOICES; do
	if [ "$choice" = "Yes" ]; then
		echo "==> Enabling OpenAL support."
		return
	else
		sed -i 's/BUILD_OPENAL=YES/BUILD_OPENAL=NO/g' /tmp/aprq2/Makefile
		echo "==> Not enabling OpenAL."
		return
	fi
done
}

function MakeBin {
cd /tmp/aprq2/trunk
make

### This shit gets messy, but it works.
if [ -e "/tmp/aprq2/trunk/releasei386/aq2" ]; then
	echo "==> Build was successful."
	echo "==> Installing binary as /usr/bin/quake2"
	mkdir -p /home/$USER/.quake2/baseq2
	mv /tmp/aprq2/trunk/releasei386/aq2 /home/$USER/.quake2

	if [ '$UID' == '0' ]; then
		echo "#\!/bin/sh\nexec /home/\$USER/.quake2/aq2 +set basedir /home/\$USER/.quake2 \$*" > /usr/bin/quake2
		chmod +x /usr/bin/quake2
	else
		echo "==> Need root for this..."

		if [ -x `which sudo` ]; then
			echo "==> Found sudo. Invokes twice to create, then make executable."
			echo "exec /home/\$USER/.quake2/aq2 +set basedir /home/\$USER/.quake2 \$*" | sudo tee -a /usr/bin/quake2 && sudo chmod +x /usr/bin/quake2
			sudo -k
		else
			"==> Using su."
			su -c 'echo "exec /home/\$USER/.quake2/aq2 +set basedir /home/\$USER/.quake2 \$*" > /usr/bin/quake2 && chmod +x /usr/bin/quake2'
		fi

	fi

	if [ -e "/usr/bin/quake2" ]; then
		echo "==> Binary installed."
		mv /tmp/aprq2/trunk/releasei386/gamei386.so /home/$USER/.quake2/baseq2
	else 
		echo "==> Had trouble installing the binary. :("
		exit 1
	fi

else
	echo "###################################"
	echo "There was a problem with the build!"
	echo "###################################"
	exit 1
fi
}

function PatchHTTP {
cd /tmp/aprq2/trunk
wget "http://github.com/squarehimself/q2kicker/raw/master/files.patch"
wget "http://github.com/squarehimself/q2kicker/raw/master/cl_http.patch"
patch -p1 < files.patch
patch -p1 < cl_http.patch
cd /tmp/aprq2/trunk/qcommon
wget "http://github.com/squarehimself/q2kicker/raw/master/files.h"
}

function ExtraFiles {
YESORNO="Yes No"
select choice in $YESORNO; do
	if [ "$choice" = "Yes" ]; then
		echo "==> Downloading kicker package"
		cd /tmp/aprq2
		wget "http://tastyspleen.tv/q2k/q2kicker_current.zip"
		echo
		echo "==> Extracting and stuff..."
		unzip q2kicker_current.zip
		mv /tmp/aprq2/q2kicker/baseq2/* /home/$USER/.quake2/baseq2
		mv /tmp/aprq2/q2kicker/NEW\ PLAYERS\ READ\ THIS.txt /home/$USER/.quake2
		rm /home/$USER/.quake2/baseq2/gamex86.dll
		return
	else
		cd /home/$USER/.quake2
		wget "http://tastyspleen.tv/q2k/q2kicker/NEW%20PLAYERS%20READ%20THIS.txt"
		return
	fi
done
}

function PNGPatch {
echo "==> Do we need to patch for libpng14?"
YNUn="Yes No Unsure"
select choice in $YNUn; do
	if [ "$choice" = "Unsure" ]; then
		echo "Not applying the patch, but you should learn how to check package versions."
		echo "If the build fails, this could be why."
		return
	elif [ "$choice" = "Yes" ]; then
		echo "==> Patching for libpng14"
		cd /tmp/aprq2/trunk
		wget "http://github.com/squarehimself/q2kicker/raw/master/pngpatch.patch"
		patch -p0 < pngpatch.patch
		return
	else
		echo "==> Not patching for libpng14."
		return
	fi
done
}

function JPEGPatch {
echo "==> Do we need to patch for libjpeg8?"
YesNoU="Yes No Unsure"
select choice in $YesNoU; do
	if [ "$choice" = "Unsure" ]; then
		echo "Not applying the patch, but you should learn how to check package versions."
		echo "If the build fails, this could be why."
		return
	elif [ "$choice" = "Yes" ]; then
		echo "==> Patching for libjpeg8"
		cd /tmp/aprq2/trunk
		wget "http://github.com/squarehimself/q2kicker/raw/master/jpegpatch.patch"
		patch -p0 < jpegpatch.patch
		return
	else
		echo "==> Not patching for libjpeg8."
		return
	fi
done
}


if [ -e `which svn` ]; then
	echo "==> Fetching sources from svn..."
	FetchSources
	echo

	echo "==> Would you like to enable MPD or XMMS support?"
	MusicOption
	echo

	echo """==> What about OpenAL sound?
		(Usually better, needs OpenAL installed and enabled in your .cfg)"""
	OpenALOption
	echo

	echo "==> Applying HTTP downloading patch..."
	PatchHTTP
	echo

	PNGPatch
	echo

	JPEGPatch
	echo

	echo "==> Starting the build..."
	MakeBin
	echo

	echo """==> Would you like to use the game files included with the kicker?
		(Say yes here unless you've purchased quake2.)"""
	ExtraFiles
	echo

	echo "==> Cleaning up..."
	rm -rf /tmp/aprq2
	echo """
If everything was successful, your extra pak files go in ~/.quake2/baseq2
	and you can run 'quake2' from your run prompt or console.
	The binary is installed to /usr/bin/quake2, as a reminder.
	There is a readme in ~/.quake2 explaining the baseq2
	directory and all of the optional stuff you can do in
	there. I strongly suggest reading this file immediately
	and becoming very familiar with the contents, because
	this file outlines everything you need to know to get
	quake2 set up and going.

If you have any problems, feel free to contact Square or Jehar on IRC.
	server: irc.globalgamers.net
	channel: #tastycast"""
else
	echo "This script requires svn. Please install subversion and try again."
fi
