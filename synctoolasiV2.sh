#!/bin/bash
clear
FILEDB="/home/asi/projects/synctool/file.db"
SYNCDB="/home/asi/projects/synctool/sync.db"
MENU="\n[NUM] Manage single Backup\n[a] Add new Path\n[b] Backup all Paths\n[exit] Exit"
IP="18.156.66.217"

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
clear
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
		if [ $VER_OPT -le $TOT_VER 2> /dev/null ] ; then
			FileMenu
		elif [ $VER_OPT != "m" 2> /dev/null ] && [ $VER_OPT != "M" 2>/dev/null] ; then
			echo "Invalid"
		fi
        done

        unset VER_OPT
	unset TITLE1
}

function FileMenu {
	while [[ $FILE_OPT != "m" ]] && [[ $FILE_OPT != "M" ]] ; do

			TITLE2=`echo "-> ${VER_ARR[$VER_OPT-1]}"`
			clear
			Title
			sudo -u sync ssh $IP "ls -ltr /tmp/backup/${VER_ARR[$VER_OPT-1]}" ; echo
				echo -e "\n[r] Restore files\n[d] Delete specific files\n[m] Return to Version Menu "
				read -p "Choose an Option: " FILE_OPT ; echo
				if [[ $FILE_OPT == "d" ]] || [[ $FILE_OPT == "D" ]] ; then
					FileDelete
				elif [ $FILE_OPT == "r" ] || [ $FILE_OPT == "R" ] ; then
					FileRestore
				elif [ $FILE_OPT != "m" ] && [ $FILE_OPT != "M" ] ; then
					echo "invalid"
				fi
				clear
			unset TITLE2 
		done
		unset FILE_OPT
	}
	function FileDelete {
		read -p "Which files do you want to delete? (Seperated by Space): " DELETED ; echo
		DEL_ARR=($DELETED)
		DELCHK=`sudo -u sync ssh $IP "ls -ltr /tmp/backup/${VER_ARR[$VER_OPT-1]}" | awk '{print $9}'`
		DELCHK_ARR=($DELCHK)
		read -p "Are you sure you want to delete `echo ${DEL_ARR[@]}` ? (Y/N): " DEL_CONFIRM ; echo
		if [ $DEL_CONFIRM = "y" ] || [ $DEL_CONFIRM = "Y" ] || [ $DEL_CONFIRM = "yes" ] || [ $DEL_CONFIRM = "YES" ] ; then
			for file in ${DEL_ARR[*]} ; do
			#Checks if $file exists in DELCHK_ARR
				if [[ " ${DELCHK_ARR[@]} " =~ " ${file} " ]]; then
	    	# whatever you want to do when array contains value
				#echo "works"
					sudo -u sync ssh $IP "rm /tmp/backup/${VER_ARR[$VER_OPT-1]}/$file" && echo -e "$file deleted"
				else
					echo -e "$file not found"
				fi

			done
			echo ; read -p "Deletion Complete , Press any key to Return..."
		fi
	}

	function AddBackup {
		echo
	}

	function BackupAll {
		echo
		for dir in `cat $SYNCDB | awk '{print $2}'` ; do
                echo -e "Backing up $dir\n"
                sudo rsync --fake-super -avzh -e "ssh -i /home/sync/.ssh/id_rsa" $dir// sync@$IP:/tmp/backup/ ; echo
                done
                read -p "press any key to continue"
	}

	function FileRestore {
		read -p "Which files do you want to Restore? (Seperated by Space): " RESTORED ; echo
                REST_ARR=($RESTORED)
                RESTCHK=`sudo -u sync ssh $IP "ls -ltr /tmp/backup/${VER_ARR[$VER_OPT-1]}" | awk '{print $9}'`
                RESTCHK_ARR=($RESTCHK)
		REST_PATH=`cat $SYNCDB | grep -w $VER_OPT | awk '{print $2}'`
                for file in ${REST_ARR[*]} ; do
                #Checks if $file exists in RESTCHK_ARR
                        if [[ " ${RESTCHK_ARR[@]} " =~ " ${file} " ]]; then
				sudo rsync --fake-super -avzh -e "ssh -i /home/sync/.ssh/id_rsa" \
				sync@$IP:/tmp/backup/${VER_ARR[$VER_OPT-1]}/$file $REST_PATH/$file-REST \
				&& echo -e "$file restored"
				#echo $file will be restored to $REST_PATH/
                        else
                                echo -e "$file not found"
                        fi

                done
                echo ; read -p "Restoration Complete , Press any key to Return..."


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
