#!/bin/sh

# wrapper around a research support container to simplify configuration during
# launch.  this hides things like the image name and mapping a host volume into
# the container, so it is a simple one liner to use.

print_usage()
{
    echo "${0} [-h] [-i <image>] [-l <launcher>] [-t] <host_path>"
    echo
    echo "Launches a research support container and provides an interactive terminal"
    echo "to work with.  The <host_path> provided is mapped into the container beneath"
    echo "${CONTAINER_DATA_ROOT} so the container can see a subset of the host's file"
    echo "systems.  Launched containers are considered stateless and are removed from"
    echo "the host when they exit."
    echo
    echo "No effort is made to map UIDs/GIDs in the container back to the host as it is"
    echo "assumed the container is built with that in mind."
    echo
    echo "The command line options shown above are described below:"
    echo
    echo "    -h                Display this help message and exit."
    echo "    -i <image>        Launch the container from <image> instead of the default."
    echo "                      If omitted, defaults to \"${SUPPORT_IMAGE}\"."
    echo "    -l <launcher>     Use <launcher> to launch the container run-time instead of"
    echo "                      the default.  If omitted, defaults to \"${CONTAINER_LAUNCHER}\"."
    echo "    -t                Enable testing mode.  The support container will not be"
    echo "                      launched but the command to do so will be printed to standard"
    echo "                      output."
    echo
}

# default to Docker as alternative run-times aren't as ubiquitous.  run
# interactively in a terminal and clean up the container image after we
# shutdown.
CONTAINER_LAUNCHER="docker run -it --rm"

# use the latest image to launch the support container with.
SUPPORT_IMAGE="research-support:latest"

# by default, launch the container.
TESTING_FLAG="no"

# path to the mapped host directory inside of its container.
CONTAINER_DATA_ROOT="/home/user/Documents"

while getopts "hi:l:t" OPTION;
do
    case ${OPTION} in
       h)
           print_usage
           exit 0
           ;;
       i)
           SUPPORT_IMAGE=${OPTARG}
           ;;
       l)
           CONTAINER_LAUNCHER=${OPTARG}
           ;;
       t)
           TESTING_FLAG="yes"
           ;;
       *)
           print_usage
           exit 1
           ;;
    esac
done
shift `expr ${OPTIND} - 1`

# ensure we received the correct number of arguments.
if [ $# -ne 1 ]; then
    echo "Expected 1 argument but received $#!" >&2
    exit 1
fi

# map arguments to variable names.
MAPPED_HOST_PATH=$1

# verify the supplied paths exist so we can report a better error message
# than the container runtime failing to launch.
if [ ! -d "${MAPPED_HOST_PATH}" ]; then
    echo "The path (${MAPPED_HOST_PATH}) does not exist!" >&2

    exit 1
fi

# assemble our configuration and build the launch command.
#
# this maps the host's data into the container and launches the container via
# the supplied launcher.
LAUNCH_COMMAND="${CONTAINER_LAUNCHER} \
                -v '${MAPPED_HOST_PATH}:${CONTAINER_DATA_ROOT}' \
                ${SUPPORT_IMAGE}"

# echo or execute depending on the caller's request.
if [ ${TESTING_FLAG} = "yes" ]; then
    echo ${LAUNCH_COMMAND}
else
    eval ${LAUNCH_COMMAND}
fi
