#!/bin/bash
#
# NyaaTorrent-CLI-Manager is a simple BASH script to manage torrents on the
# website nyaa.eu.
#
# Author : Benoît.S « Benpro » <benpro@benprobox.fr>
# Website : benprobox.fr
# Licence : GPLv3

# Configuration, edit these variables.
nyaa_account_anonymous=0 # Set to 1 if you doesn't want to authenticate to NyaaTorrent.
nyaa_account_login="" # Set your login.
nyaa_account_passwd="" # Set you password.

# Optional configuration.
nyaa_website="http://www.nyaa.eu"
curl_cookie=$(mktemp)
curl_output=$(mktemp)
curl_useragent="NyaaTorrent-CLI-Manager - https://github.com/benpro/NyaaTorrent-CLI-Manager"
torrent_name=""
torrent_tracker="udp://tracker.openbittorrent.com:80/announce"
torrent_url=""
torrent_info_url=""
torrent_description="None."
torrent_remake=0 # Set to 1 if the torrent is a remake.
torrent_anonymous=0 # Set to 1 to upload pseudo-anonymously.
torrent_hidden=0 # Set to 1 to hide the torrent.
torrent_catid="1_37" # This the category of the torrent, it can be:
#1_32 Anime - Anime Music Video
#1_37 Anime - English-translated Anime
#1_38 Anime - Non-English-translated Anime
#1_11 Anime - Raw Anime
#2_12 Books - English-scanlated Books
#2_39 Books - Non-English-scanlated Books
#2_13 Books - Raw Books
#5_19 Live Action - English-translated Live Action
#5_22 Live Action - Live Action Promotional Video
#5_21 Live Action - Non-English-translated Live Action
#5_20 Live Action - Raw Live Action
#33_34 Lossless Audio - Lossless Albums
#33_35 Lossless Audio - Lossless Singles
#33_36 Lossless Audio - Lossless Soundtracks
#3_14 Lossy Audio - Lossy Albums
#3_16 Lossy Audio - Lossy Singles
#3_15 Lossy Audio - Lossy Soundtracks
#4_18 Pictures - Graphics
#4_17 Pictures - Photos
#6_23 Software - Applications
#6_24 Software - Games
torrent_rules=1 # Required elsewhere the torrent won't be uploaded!

# Do not touch the rest of this script if you don't known BASH/Shell scripting.
usage() {

	# Show possible options, syntax and help.
	echo -e "=^..^= NyaaTorrent-CLI-Manager =^..^=\n" \
		"It seems that you want to get the help usage or you have made an error.\n\n" \
		"Usage: $0 [options]\n" \
		"Options:\n\n" \
		"Adding a torrent:\n" \
		"-d Optional: Set the torrent description. Default is \"$torrent_description\".\n" \
		"-n Optional: Set the torrent name. Default read the name contained in the .torrent.\n" \
		"-t Optional: Set the field tracker. Default to $torrent_tracker.\n" \
		"-u Optional: Set the field \"Info URL\" of the torrent. Default is \"$torrent_info_url\".\n" \
		"-c Optional: Set the field \"Category ID\" of the torrent. Default to $torrent_catid.\n" \
		"-r Optional: Set the field \"Remake\" of the torrent. Can be 0 or 1. Default to $torrent_remake.\n" \
		"-o Optional: Set the field \"Anonymous\" of the torrent. Can be 0 or 1. Default to $torrent_anonymous.\n" \
		"-i Optional: Set the field \"Hidden\" of the torrent. Can be 0 or 1. Default to $torrent_hidden.\n\n" \
		"-a /path/to/the/file.torrent or http://website.com/path/to/file.torrent - Add the torrent.\n" \
		"Other:\n" \
		"-l List your torrents.\n" \
		"-g Get the latest torrents of your account.\n" \
		"-h Show this help.\n"
}

checkDepends() {

	# Verify that the system have the prerequisite tools
	# This script won't install them, just warn you if you don't have the
	# necessary tools.
	curl=$(which curl 2>/dev/null)
	if (($? != 0)); then
		echo "Warning: curl not found, you may exit the script right now by pressing ^C." \
			"Otherwise press Enter to continue."
		read
	fi
}

authenticate() {

	# Authenticate on Nyaa and get cookie.
	$curl -# \
		"$nyaa_website/?page=login" \
		-A "$curl_useragent" \
		-d loginusername="$nyaa_account_login" \
		-d loginpassword="$nyaa_account_passwd" \
		-c $curl_cookie \
		-o $curl_output
		grep -F -o "Login successful" $curl_output &>/dev/null
		if (($? != 0)); then
		echo "Can't login, check your login and password!"
		exit 1
	fi
}

checkIfFileIsURL() {

	# This permit to determine
	# /path/to/file.torrent vs http://website.com/file.torrent
	grep -F "http://" <<< $torrent_file &>/dev/null
	if (($? == 0)); then
		return 1
	fi
	return 0
}

addTorrent() {

	# Add a torrent.
	
	# If you want to be anonymous, the script will not proceed to
	# authentication on nyaa.
	if ((!$nyaa_account_anonymous)); then
		authenticate
	fi

	# Check if the torrent is local or remotely (http).
	if ((!checkIfFileIsURL)); then
		curl_set_torrent="-F torrent=@$torrent_file;type=application/x-bittorrent"
	else
		curl_set_torrent="-F torrenturl=$torrent_file"
	fi
	$curl -# \
		"$nyaa_website/?page=upload" \
		-A "$curl_useragent" \
		-F name="$torrent_name" \
		$curl_set_torrent \
		-F catid="$torrent_catid" \
		-F info="$torrent_info_url" \
		-F remake="$torrent_remake" \
		-F anonymous="$torrent_anonymous" \
		-F hidden="$torrent_hidden" \
		-F description="$torrent_description" \
		-F rules="$torrent_rules" \
		-F submit="Upload" \
		-b $curl_cookie \
		-o $curl_output
	# Getting links
	link_info=$(grep -E -o "http://www.nyaa.eu/\?page=torrentinfo&amp;tid=[0-9]+" $curl_output | sed "s/amp;//")
	link_download=$(sed "s/torrentinfo/download/" <<< $link_info)
	[ -z $link_download ] && return 1
	return 0
}

# listTorrents() {
# 
# 	# Lists your torrents.
# }
# 
# latestTorrent() {
# 
# 	# Get the link to the latest torrent in your account.
# }

egg() {

	echo -e \
	"\033[48;5;17m\n" \
	"                                                                                \n" \
	"                                                                                \n" \
	"                              \033[48;5;0m                              \033[48;5;17m\n" \
	"                \033[48;5;9m            \033[48;5;0m  \033[48;5;230m                              \033[48;5;0m  \033[48;5;17m\n" \
	"\033[48;5;9m                          \033[48;5;0m  \033[48;5;230m      \033[48;5;175m                      \033[48;5;230m      \033[48;5;0m  \033[48;5;17m\n" \
	"\033[48;5;9m                          \033[48;5;0m  \033[48;5;230m    \033[48;5;175m          \033[48;5;162m  \033[48;5;175m    \033[48;5;162m  \033[48;5;175m        \033[48;5;230m    \033[48;5;0m  \033[48;5;17m\n" \
	"\033[48;5;202m                          \033[48;5;0m  \033[48;5;230m  \033[48;5;175m    \033[48;5;162m  \033[48;5;175m            \033[48;5;0m    \033[48;5;175m  \033[48;5;162m  \033[48;5;175m    \033[48;5;230m  \033[48;5;0m  \033[48;5;17m  \033[48;5;0m    \033[48;5;17m\n" \
	"\033[48;5;202m                          \033[48;5;0m  \033[48;5;230m  \033[48;5;175m                \033[48;5;0m  \033[48;5;8m    \033[48;5;0m  \033[48;5;175m      \033[48;5;230m  \033[48;5;0m    \033[48;5;8m    \033[48;5;0m  \033[48;5;17m\n" \
	"\033[48;5;202m                \033[48;5;0m      \033[48;5;11m    \033[48;5;0m  \033[48;5;230m  \033[48;5;175m          \033[48;5;162m  \033[48;5;175m    \033[48;5;0m  \033[48;5;8m      \033[48;5;175m      \033[48;5;230m  \033[48;5;0m  \033[48;5;8m      \033[48;5;0m  \033[48;5;17m\n" \
	"\033[48;5;11m                \033[48;5;8m    \033[48;5;0m    \033[48;5;11m  \033[48;5;0m  \033[48;5;230m  \033[48;5;175m                \033[48;5;0m  \033[48;5;8m      \033[48;5;0m        \033[48;5;8m        \033[48;5;0m  \033[48;5;17m\n" \
	"\033[48;5;11m                \033[48;5;0m  \033[48;5;8m    \033[48;5;0m      \033[48;5;230m  \033[48;5;175m                \033[48;5;0m  \033[48;5;8m                      \033[48;5;0m  \033[48;5;17m\n" \
	"\033[48;5;11m                \033[48;5;0m    \033[48;5;8m    \033[48;5;0m    \033[48;5;230m  \033[48;5;175m            \033[48;5;162m  \033[48;5;0m  \033[48;5;8m                          \033[48;5;0m  \033[48;5;17m\n" \
	"\033[48;5;10m                  \033[48;5;0m    \033[48;5;8m    \033[48;5;0m  \033[48;5;230m  \033[48;5;175m  \033[48;5;162m  \033[48;5;175m          \033[48;5;0m  \033[48;5;8m      \033[48;5;15m  \033[48;5;0m  \033[48;5;8m        \033[48;5;15m  \033[48;5;0m  \033[48;5;8m    \033[48;5;0m  \033[48;5;17m\n" \
	"\033[48;5;10m                    \033[48;5;0m        \033[48;5;230m  \033[48;5;175m              \033[48;5;0m  \033[48;5;8m      \033[48;5;0m    \033[48;5;8m    \033[48;5;0m  \033[48;5;8m  \033[48;5;0m    \033[48;5;8m    \033[48;5;0m  \033[48;5;17m\n" \
	"\033[48;5;10m                \033[48;5;33m        \033[48;5;0m    \033[48;5;230m    \033[48;5;175m      \033[48;5;162m  \033[48;5;175m    \033[48;5;0m  \033[48;5;8m  \033[48;5;175m    \033[48;5;8m                \033[48;5;175m    \033[48;5;0m  \033[48;5;17m\n" \
	"\033[48;5;33m                          \033[48;5;0m  \033[48;5;230m      \033[48;5;175m            \033[48;5;0m  \033[48;5;8m      \033[48;5;0m            \033[48;5;8m    \033[48;5;0m  \033[48;5;17m\n" \
	"\033[48;5;15m  \033[48;5;33m              \033[48;5;19m        \033[48;5;0m      \033[48;5;230m                  \033[48;5;0m  \033[48;5;8m                  \033[48;5;0m  \033[48;5;17m\n" \
	"\033[48;5;19m                      \033[48;5;0m  \033[48;5;8m      \033[48;5;0m                                      \033[48;5;17m\n" \
	"\033[48;5;19m                      \033[48;5;0m  \033[48;5;8m    \033[48;5;0m    \033[48;5;17m  \033[48;5;0m  \033[48;5;8m  \033[48;5;0m  \033[48;5;17m          \033[48;5;0m  \033[48;5;8m  \033[48;5;0m  \033[48;5;17m  \033[48;5;0m  \033[48;5;8m    \033[48;5;0m  \033[48;5;17m\n" \
	"\033[48;5;19m      \033[48;5;15m  \033[48;5;19m        \033[48;5;17m      \033[48;5;0m        \033[48;5;17m    \033[48;5;0m    \033[48;5;17m              \033[48;5;0m    \033[48;5;17m    \033[48;5;0m    \033[48;5;17m\n" \
	"                                                                                \n" \
	"                                                                                \n" \
	"                         \033[1;37mNyanTorrent-CLI-Manager - by Benpro\033[48;5;17m"
	# Thanks to https://github.com/klange/nyancat/blob/master/src/nyancat.c :)
}

clean() {

	# Do some cleaning.
	[ -f $curl_cookie ] && rm $curl_cookie
	[ -f $curl_output ] && rm $curl_output
}

# Application entry point, script start here! \_o>
# Firstly check if there is parameters are set.
if (($# == 0)); then
    usage
    exit 1
fi

# Secondly checks the dependences.
checkDepends

# Then set a trap to do some cleaning when the script exit.
# trap 'clean;' SIGINT SIGTERM EXIT

# Getopts to handle options and parameters.
while getopts "d:n:t:u:c:r:o:i:a: e l g h" opt; do
    case $opt in
		d)
			torrent_description=$OPTARG
			;;
		n)
			torrent_name=$OPTARG
			;;
		t)
			torrent_tracker=$OPTARG
			;;
		u)
			torrent_info_url=$OPTARG
			;;
		c)
			torrent_catid=$OPTARG
			;;
		r)
			torrent_remake=$OPTARG
			;;
		o)
			torrent_anonymous=$OPTARG
			;;
		i)
			torrent_hidden=$OPTARG
			;;
		a)
			torrent_file=$OPTARG
			addTorrent
			if (($? == 0)); then
				echo "Ok, torrent added successfully!"
				echo "Link to torrent informations: \"$link_info\"."
				echo "Link to download torrent: \"$link_download\"."
			else
				echo "Uh oh, something went wrong when adding the torrent!"
			fi
			;;
		e)
			egg
			;;
		l)
			listTorrents
			;;
		g)
			latestTorrent
			;;
		h)
			usage
			;;
			
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done