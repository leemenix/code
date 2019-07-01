#!/bin/bash

echo "choose which way you want to install youtube-dl"
echo "choose [cC] for curl or [pP] pip"

read INSTALL_TYPE

if [[ $INSTALL_TYPE = [cC] ]]; then
	echo curl
	sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
	sudo chmod a+rx /usr/local/bin/youtube-dl
elif [[ $INSTALL_TYPE = [pP] ]]; then
        echo pip
	sudo pip install --upgrade youtube_dl
fi

echo "Please choose [cC] for curlt or [pP] for pip"
