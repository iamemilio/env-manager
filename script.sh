
# This is a simple Infra manager
# Add these scripts to your .bashrc, and customize them based on your environment

export STATUS="${STATUS}"

# Variables
devEnvs="[ shiftstack | upshift | none ]"
envFile="$HOME/tmp/devEnv.txt"

# The directory where you keep shiftstack-ci
shiftstack_ci_dir=$HOME/Dev/shiftstack-ci/

# Create a directory that has a sub directory for each environment you want to manage
# Each of these sub directories should have a clouds.yaml and a cluster-config.yaml
#
# Example:
# 	      clouds __          
#		\      \	
#	      upshift   shiftstack

cloud_dir=$HOME/Dev/clouds

# Tool to clean state of local or global env
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

# Module for provisioning env to use shiftstack
shiftstack_provision () {
	cp -R $cloud_dir/shiftstack/clouds.yaml $HOME/.config/openstack/
	export OS_CLOUD=openstack
	cp -R $cloud_dir/shiftstack/cluster_config.sh $shiftstack_ci_dir
	export STATUS=shiftstack
	printf "shiftstack" > $envFile
}

# Module for provisioning env to use upshift
upshift_provision () {
	cp -R $cloud_dir/upshift/clouds.yaml $HOME/.config/openstack/
	export OS_CLOUD=openstack
	cp -R $cloud_dir/upshift/cluster_config.sh $shiftstack_ci_dir
	export STATUS=upshift
	printf "upshift" > $envFile
}

# Tool to check status of local and global env state
status () {
	case $1 in
		-h)
			echo ""
			echo "Environment Status"
			echo ""
			echo "status [options]"
			echo "-h 		show this message"
			echo "-g		show global environment status"
			echo "-a 		show status of all environments"
			;;
		-g)
			status="$(cat $envFile)"
			echo "The status of the global env is: $status"
			;;
		-a)
			status="$(cat $envFile)"
			echo "The status of the global env is: $status"
			echo "The status of your env is: ${STATUS}"
			;;
		*)
			echo "The status of your env is: ${STATUS}"
			;;
	esac
}

# Tool to provision local and global env
provision () {
	status="$(cat $envFile)"
        if [ "$status" == "clean" ]; then
		read -p "Which Dev Environment do you want to provision for: $devEnvs: " provision
		case $provision in
			shiftstack|s)
				shiftstack_provision
				echo "Please note that this will affect all local dev environments!"
				;;
			upshift|u)
                		upshift_provision
                		echo "Please note that this will affect all local dev environments!"
                		;;
			none|n)
				echo "Exiting without provisioning..."
				;;
			*)
				echo "Unrecognized input, $provision. Your options are $devEnvs."
				;;
		esac
	else
	        echo "Env already provisioned for $status. Please clean before provisioning again."
        fi
}

# Tool to bring local env up to date with global state
update () {
	source $HOME/.bashrc
}

# Will create the state file if it doesn't exist
touch $envFile

# Configure terminal env to be consistent with the chosen state
globalStatus="$(cat $envFile)"
if  [ -z "$globalStatus" ]; then
	clean
elif [ "$globalStatus" != "${STATUS}" ]; then
	echo "Updating env to match global status"
	clean -l
	if [ "$globalStatus" == "shiftstack" ]; then
		shiftstack_provision
	elif [ "$globalStatus" == "upshift" ]; then
                upshift_provision
	fi
	
	status -a
fi

