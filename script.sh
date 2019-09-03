# manage-env program variables

## Path to directory where you want to save metadata for dev environments
envDir=""
## Path to file where global envirnment state is stored
envFile=""
## Path to shiftstack-ci repo
ci_dir=""

# manage-env functions
clean () {
	echo "Cleaning your env..."
	rm -f $HOME/.config/openstack/clouds.yaml
	vars="$(env | grep -e "^OS_.*" | sed "s/=.*//g")"

	for var in $vars; do
		unset $var
	done
	
	if [ "$1" != "-l" ];then
		printf "clean" > $envFile
	fi

	export STATUS=clean
	echo "Clean!"
}

generic_provision () {
	env=$1
	if [ -z $1 ]; then
		echo "Error: no env passed"
		break
	fi

	if [ -d "$envDir/$1/clouds" ]; then
		cp -R "$envDir/$1/clouds/clouds.yaml" "$HOME/.config/openstack/"
		cloud=$(cat $envDir/$1/clouds/cloud.txt)
		export OS_CLOUD=$cloud
	fi
	if [ -d "$envDir/$1/clusterConfig" ]; then
		cp -R "$envDir/$1/clusterConfig/cluster_config.sh" "$ci_dir/cluster_config.sh"
	fi
	export STATUS=$1
	
	case $2 in
		-l|--local);;
		*) printf $1 > $envFile;;
	esac
}

help () {
	echo ""
	echo "Manage Env is a tool for provisioning your environment to work with different contexts."
	echo "Usage: manage-env <[operation]>"
	echo ""
	echo "Operations:"
	echo "help			Print this message."
	echo "status		Check what env your system is provisioned for."
	echo "provision		If your env is clean, you can provision it to work with a new context."
	echo "clean			This will clean your environemet so that it is ready to be re-provisioned."
	echo "save-env		Save your current env for later use."
	echo "delete-env	Delete a saved env."
	echo ""
}
 
status () {
	status="$(cat $envFile)"
	echo "Global: $status"
	echo "Local:  ${STATUS}"
}

global-export () {
	key="$(echo $1 | cut -d "=" -f 1 )"
	exists="$(cat $HOME/.bashrc | grep "$key")"
	if [ -n "$exists" ]; then
		LINE="$(cat $HOME/.bashrc | grep -n "$key" | cut -d ":" -f 1)"
		sed -i "${LINE}d" $HOME/.bashrc
	fi
	echo "export $1" >> $HOME/.bashrc
		source $HOME/.bashrc
}

provision() {
	devEnvs="$(ls $envDir)"
	status="$(cat $envFile)"
	if [ "$status" == "clean" ]; then
		echo "Which DEV environment do you want to provision for: "
		choices="$devEnvs cancel"
		select choice in $choices;
		do
			case $choice in
				cancel)
					echo "Exiting."
					break
					;;
				*)
					generic_provision $choice
					break
					;;
			esac
		done
	else
		echo "Env already provisioned for $status. Please clean before provisioning again."
	fi
}

update () {
	# Configure terminal env to be consistent with the chosen state
	globalStatus="$(cat $envFile)"
	if  [ -z "$globalStatus" ]; then
		clean
	elif [ "$globalStatus" != "${STATUS}" ]; then
		echo "Updating env to match global status"
		clean -l
		generic_provision $globalStatus -l
		status
	fi
}

save-env () {
	devEnvs="$(ls $envDir)"
	echo "What environment do you want to save your state under:"
	choices="$devEnvs new"
	TARGET=""
	select choice in $choices;
	do
		# duplicate case impossible
		if [ "$choice" == "new" ]; then
			echo -n "enter a name for your env: "
			read name
			mkdir $envDir/$name
			TARGET=$envDir/$name
			mkdir $TARGET/clouds
			mkdir $TARGET/clusterConfig
		else
			TARGET=$envDir/$choice
		fi

		if [ -d "$TARGET/clusterConfig" ]; then
			cp "$ci_dir/cluster_config.sh" $TARGET/clusterConfig/cluster_config.sh
		fi
		if [ -d "$TARGET/clouds" ]; then
			cp $HOME/.config/openstack/clouds.yaml $TARGET/clouds/clouds.yaml
			echo $OS_CLOUD > $TARGET/clouds/cloud.txt
		fi
	break
	done
}

delete-env () {
	devEnvs="$(ls $envDir)"
	echo "What environment save do you want to delete?"
	choices="$devEnvs cancel"

	select choice in $choices;
	do
		case $choice in
			cancel)
				break;;
			*)
				rm -rf $envDir/$choice
				printf "%s deleted!\n" $choice
				break;;
		esac
	done
}

update
# More Variables