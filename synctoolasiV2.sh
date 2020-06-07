#!/bin/bash
clear
FILEDB="/home/asi/projects/synctool/file.db"
SYNCDB="/home/asi/projects/synctool/sync.db"
MENU="\n[NUM] Manage single Backup\n[a] Add new Path\n[b] Backup all Paths\n[exit] Exit"
IP="3.124.181.124"

function Title {
        TITLE="SyncTool $TITLE1 $TITLE2"
        NUM=`echo $TITLE | wc -m`
	NUM=`expr $NUM - 1`
        arr=()
	for ((i=1; i<=$NUM; i++)); do 
		arr+=( "$i" )
	done
	echo -e "$TITLE"
	/usr/bin/printf '-%.0s' "${arr[@]}" ; echo -e "\n"
}


function MainMenu {
#echo -e "\nSyncTool\n--------\n" 
Title
cat $SYNCDB
echo -e "$MENU\n"
read -p "Choose an option to Continue: " OPTION ; echo
}

function VersionMenu {
	FOLDER=`sed $OPTION'q;d' $SYNCDB | awk '{print $2}' | awk -F "/" '{print $NF}'`
	TITLE1=`echo "-> $FOLDER"`
        VER_MENU=`sudo -u sync ssh $IP "ls -ltr /tmp/backup | grep -w $FOLDER" | awk -F " " '{print $9}'`
        VER_ARR=($VER_MENU)
        TOT_VER=${#VER_ARR[@]}

        while [[ $VER_OPT != "m" ]] && [[ $VER_OPT != "M" ]] ; do
                COUNTER=1
		Title
                for VER in $VER_MENU ; do
                        echo -e "$COUNTER|\t$VER"
                       	COUNTER=$((COUNTER+1))
                done

                echo -e "\n[NUM] View version files\n[m] Return to Main Menu\n"
                read -p "Choose an Option: " VER_OPT ; echo
		FileMenu
        done

        unset VER_OPT
	unset TITLE1
}

function FileMenu {
	if [ $VER_OPT -le $TOT_VER 2> /dev/null ] ; then
		TITLE2=`echo "-> ${VER_ARR[$VER_OPT-1]}"`
		clear
		Title
		sudo -u sync ssh $IP "ls -ltr /tmp/backup/${VER_ARR[$VER_OPT-1]}" ; echo
		read -p "[KEY] Return to version Menu "
		clear
	elif [ $VER_OPT != "m" ] && [ $VER_OPT != "M" ] ; then
		echo "Invalid"
        fi
	unset TITLE2 

}
function AddBackup {
	echo
}

function BackupAll {
	echo
}


while [[ $OPTION != "e" ]] && [[ $OPTION != "E" ]] ; do
        MainMenu
        if [[ $OPTION =~ ^[0-9]+$ ]] ; then
                clear
		VersionMenu
        elif [ $OPTION = "b" ] || [ $OPTION = "B" ] ; then
                clear
		echo "backup all"
		BackupAll
        elif [ $OPTION = "a" ] || [ $OPTION = "A" ] ; then
                clear
		echo "add backup"
		AddBackup
        elif [[ $OPTION = "e" ]] || [[ $OPTION = "E" ]] ; then
                clear
		echo "exiting..."
        else
                echo "Invalid"
        fi
done
