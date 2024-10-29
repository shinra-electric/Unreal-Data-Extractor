#!/usr/bin/env zsh

# ANSI colour codes
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Colour

# This just gets the location of the folder where the script is run from. 
SCRIPT_DIR=${0:a:h}
cd "$SCRIPT_DIR"

# Introduction
introduction() {
	echo "\n${PURPLE}This script will extract and convert game data for ${GREEN}Unreal${PURPLE} or ${GREEN}Unreal Tournament${NC}.${NC}\n"
	echo "${PURPLE}Run the script in the same folder as the app.${NC}"
	
	echo "\n${PURPLE}If you already have ${GREEN}Unreal.iso${PURPLE} or ${GREEN}UT_GOTY_CD1.iso${PURPLE} make sure they are mounted.${NC}"
	echo "${PURPLE}If you do not have them, you will be given an option to download.${NC}\n"
}

detect_app() {
	if [ ! -d $1.app ]; then 
		echo "\n${RED}$1.app not found.${NC}"
		echo "${PURPLE}Run this script from the same directory as the app${NC}"
		exit 0
	fi
}

check_app_support() {
	if [ -d $1 ]; then 
		echo "\n${PURPLE}An Application Support folder already exists${NC}"
		echo "\n${RED}Continuing will overwrite any existing game data!${NC}"	
		echo "\n${PURPLE}Note: User preferences will not be affected.${NC}"
		
		PS3='Would you like to continue? '
		OPTIONS=(
			"Overwrite"
			"Quit")
		select opt in $OPTIONS[@]
		do
			case $opt in
				"Overwrite")
					break
					;;
				"Quit")
					echo "${RED}Quitting${NC}"
					exit 0
					;;
				*) 
					echo "\"$REPLY\" is not one of the options..."
					echo "Enter the number of the option and press enter to select"
					;;
			esac
		done
	fi
}

check_data() {
	if [ -d /Volumes/$1 ]; then
		echo "${GREEN}$1 volume detected...${NC}"
	elif [ -e $1.iso ]; then 
		echo "${GREEN}$1.iso detected...${NC}"
		mount_iso $1
	else
		echo "${PURPLE}$1.iso not detected...${NC}"
		download_menu $1
	fi
}

download_iso() {
	echo "${PURPLE}Fetching iso...${NC}"
	echo "${PURPLE}This may take some time depending on your internet connection.${NC}"
	curl -OL $URL
}

mount_iso() {
	echo "${PURPLE}Mounting $1.iso...${NC}"
	hdiutil attach $1.iso
}

unmount_iso() {
	echo "${PURPLE}Unmounting $1...${NC}"
	hdiutil unmount /Volumes/$1
}

copy_data() {
	if [ ! -d $APP_SUPP ]; then 
		mkdir $APP_SUPP
	fi
	
	rm -rf $APP_SUPP/Maps
	rm -rf $APP_SUPP/Music
	rm -rf $APP_SUPP/Sounds
	rm -rf $APP_SUPP/Textures
	
	cp -R /Volumes/$ISO_NAME/Maps $APP_SUPP/Maps
	cp -R /Volumes/$ISO_NAME/Music $APP_SUPP/Music
	cp -R /Volumes/$ISO_NAME/Sounds $APP_SUPP/Sounds
	cp -R /Volumes/$ISO_NAME/Textures $APP_SUPP/Textures
}

remove_ut_fonts() {
	rm $APP_SUPP/Textures/UWindowFonts.utx
	rm $APP_SUPP/Textures/LadderFonts.utx
}

decompress_textures() {
	for file in $APP_SUPP/Maps/*.uz; do 
		./UnrealTournament.app/Contents/MacOS/UCC decompress $file; 
	done

	mv $APP_SUPP/System/*.unr $APP_SUPP/Maps/
	rm $APP_SUPP/Maps/*.uz
}

main_menu() {
	PS3='Which game would you like to extract data for? '
	OPTIONS=(
		"Unreal"
		"Unreal Tournament"
		"Quit")
	select opt in $OPTIONS[@]
	do
		case $opt in
			"Unreal")
				BUNDLE_ID=Unreal
				ISO_NAME=Unreal
				URL=https://archive.org/download/gt-unreal-1998/Unreal.iso
				APP_SUPP=~/Library/Application\ Support/Unreal
				detect_app $BUNDLE_ID
				check_app_support $APP_SUPP
				check_data $ISO_NAME
				copy_data $ISO_NAME
				unmount_iso $ISO_NAME
				cleanup_menu $ISO_NAME
				exit 0
				;;
			"Unreal Tournament")
				BUNDLE_ID=UnrealTournament
				ISO_NAME=UT_GOTY_CD1
				URL=https://archive.org/download/ut-goty/UT_GOTY_CD1.iso
				APP_SUPP=~/Library/Application\ Support/Unreal\ Tournament
				detect_app $BUNDLE_ID
				check_app_support $APP_SUPP
				check_data $ISO_NAME
				copy_data $ISO_NAME
				remove_ut_fonts
				decompress_textures
				unmount_iso $ISO_NAME
				cleanup_menu $ISO_NAME
				exit 0
				;;
			"Quit")
				echo -e "${RED}Quitting${NC}"
				exit 0
				;;
			*) 
				echo "\"$REPLY\" is not one of the options..."
				echo "Enter the number of the option and press enter to select"
				;;
		esac
	done
}

download_menu() {
	echo "\n${PURPLE}Since Unreal and Unreal Tournament are not currently available for sale, Epic has recommended specific isos to use that are available for download on Archive.org${NC}\n"
	
	
	PS3='Would you like to download? '
	OPTIONS=(
		"Download"
		"Quit")
	select opt in $OPTIONS[@]
	do
		case $opt in
			"Download")
				download_iso
				mount_iso $1
				break
				;;
			"Quit")
				echo -e "${RED}Quitting${NC}"
				exit 0
				;;
			*) 
				echo "\"$REPLY\" is not one of the options..."
				echo "Enter the number of the option and press enter to select"
				;;
		esac
	done
}

cleanup_menu() {
	echo "\n${PURPLE}The game data has been extracted.${NC}\n"
	
	PS3='Would you like to delete the iso? '
	OPTIONS=(
		"Delete"
		"Keep")
	select opt in $OPTIONS[@]
	do
		case $opt in
			"Delete")
				echo "${PURPLE}Deleting iso...${NC}\n"
				rm $1.iso
				break
				;;
			"Keep")
				break
				;;
			*) 
				echo "\"$REPLY\" is not one of the options..."
				echo "Enter the number of the option and press enter to select"
				;;
		esac
	done
}

introduction
main_menu