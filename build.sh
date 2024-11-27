#!/bin/bash
#
USERNAME=rosopensimrt
BUILD_STAGES=true
ARCH=$(uname -m)
BRANCH_RAW=$(git branch --show-current )

## sanitize branch name
sanitize_tag() {
    echo "$1" | sed -e 's/[^a-zA-Z0-9._-]/_/g' | tr '[:upper:]' '[:lower:]' | sed -e 's/^[-._]//g' -e 's/[-._]$//g'
}
BRANCH=$(sanitize_tag "$BRANCH_RAW")

if [[ -z "$BRANCH" ]]; then
	BRANCH=latest
fi

IS_ROOTLESS=false
# I think this is a linux only issue.
DOCKER_DEAMON_PROCESS_OWNER=$(ps aux | grep [d]ockerd | awk '{print $1}')

if [ "$DOCKER_DEAMON_PROCESS_OWNER" != "root" ]; then
        printf "\e[33m\n\tWARNING:\tWhen using docker rootless, the volumes don't mount properly, which means you wont be able to change data from the host while the container is running.\n\n"
        printf "\tTo save data, you need to change the volume belong to the subuser that is running inside the container.\n"
        printf "\tTo do this you need to start a \"root\" instance and use chown -R and set it to the name of the user that was used to build the container\n"

        printf "\tafter you are done with it you can just chown recursively to your own user outside the docker container.\n\n\e[0m"
        IS_ROOTLESS=true
fi


if [ "$(uname)" == "Darwin" ]; then
	# Do something under Mac OS X platform
		# I can only run in x86_64 systems, so I should also warn the person.
		docker build . -f Dockerfile -t ${USERNAME}/osrt-full-$ARCH:$BRANCH $@

	elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
		# Do something under GNU/Linux platform
		# I can only run in x86_64 systems, so I should also warn the person.
		
		options=$(getopt -o lc --longoptions username:,build_in_one_go -- "$@")
		[ $? -eq 0 ] || { 
		    echo "Incorrect options provided"
		    exit 1
		}
		eval set -- "$options"
		while true; do
		    case "$1" in
		    -l)
			## tag as latest
			BRANCH=latest
			;;
		    --username)
			shift; # The arg is next in position args
			USERNAME=${1:rosopensimrt}
			;;
		    --build_in_one_go)
			BUILD_STAGES=false
			;;
		    --)
			shift
			## after this there will be the options for docker build. the second one
			break
			;;
		    esac
		    shift
		done
		#printf "$USER_ID_THAT_WAS_USED_TO_BUILD_THIS_DOCKER" 
		#exit 0;

		COMMON_OPTIONS="--progress=tty \
				--network=host \
				$@
		"

			echo "USING COMPLETE BUILD"
			if [ "$BUILD_STAGES" = true ]; then
				echo "Building opensim docker by stage"
				DOCKER_BUILDKIT=1 docker build . -f Dockerfile --target=dependencies -t ${USERNAME}/osrt-1-$ARCH:$BRANCH $COMMON_OPTIONS
				DOCKER_BUILDKIT=1 docker build . -f Dockerfile --target=stage2 -t ${USERNAME}/osrt-2-$ARCH:$BRANCH $COMMON_OPTIONS
				DOCKER_BUILDKIT=1 docker build . -f Dockerfile --target=stage3 -t ${USERNAME}/osrt-3-$ARCH:$BRANCH $COMMON_OPTIONS
			fi
				DOCKER_BUILDKIT=1 docker build . -f Dockerfile -t ${USERNAME}/osrt-full-$ARCH:$BRANCH $COMMON_OPTIONS

	elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
		# Do something under 32 bits Windows NT platform
		docker build . -f Dockerfile -t ${USERNAME}/osrt-full-$ARCH:$BRANCH $@

	elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
		# Do something under 64 bits Windows NT platform
	docker build . -f Dockerfile -t ${USERNAME}/osrt-full-$ARCH:$BRANCH $@

fi
