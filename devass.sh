#!/bin/bash - 
#===============================================================================
#
#         USAGE: ./devass.sh --help
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Sylvain S. (ResponSyS), mail@systemicresponse.com
#  ORGANIZATION: 
#       CREATED: 11/26/2017 14:45
#      REVISION:  ---
#===============================================================================

set -o nounset -o errexit                   # Treat unset variables as an error

PROGRAM_NAME="${0##*/}"
VERSION=0.5

PROJ_NAME=

CONF_FILE="$HOME/.devassrc"
SRC_DIR=
PREMAKE=0
PREMAKE_CMD=
PREMAKE_TYPE="gmake2"
README=0
README_FILE="README.md"
GIT_INIT=0
MAKE=0

ERR_WRONG_ARG=2
ERR_NO_FILE=10

FMT_BOLD='\e[1m'
FMT_UNDERL='\e[4m'
FMT_OFF='\e[0m'

# command to test (string)
m_needCmd() {
	command -v "$1" > /dev/null 2>&1
}
# command to test (string)
fn_needCmd() {
	if ! command -v "$1" > /dev/null 2>&1 ; then
		fn_err "need '$1' (command not found)" $ERR_NO_FILE
	fi
}
# message (string)
m_say() {
	echo -e "$PROGRAM_NAME: $1"
}
# error message (string), return code (int)
fn_err() {
	m_say "${FMT_BOLD}ERROR${FMT_OFF}: $1" >&2
	exit $2
}

fn_help() {
	cat << EOF
$PROGRAM_NAME $VERSION
    Instantly set up the base structure for a new project.
    This *dev ass(istant)* basically gets files from a template directory, makes 
    a README and runs needed commands like \`premake\`, \`git\` or \`make\`.

USAGE
    ./$PROGRAM_NAME [OPTIONS]

OPTIONS
    -n NAME             specify the NAME of your project (mandatory)
    -c FILE             specify path to configuration file (default: \$HOME/.devassrc)
    -h, --help          show this help message

CONFIGURATION VARIABLES
    SRC_DIR=PATH        set path to template directory to PATH (mandatory)
    PREMAKE={0,1}       run \`premake\` (default: 0)
    PREMAKE_TYPE=TYPE   set the premake action to TYPE (default: gmake2)
    README={0,1}        make a README.md file (default: 0)
    GIT_INIT={0,1}      run \`git init\` (default: 0)
    MAKE={0,1}          run \`make\` (default: 0)

EXAMPLES
    $ ./$PROGRAM_NAME -c \$HOME/.my_devass_rc -n newProj

AUTHOR
    Written by Sylvain Saubier (<http://SystemicResponse.com>)

REPORTING BUGS
    Mail at: <feedback@systemicresponse.com>
EOF
}

fn_checkPremake() {
	m_needCmd "premake4" && PREMAKE_CMD="premake4" || m_say "'premake4' not found"
	m_needCmd "premake5" && PREMAKE_CMD="premake5" || m_say "'premake5' not found"
}

# Arguments parsing
while test $# -ge 1; do
	case "$1" in
		"-c")
			shift
			[ $# -ge 1 ] || fn_err "missing path of configuration file" $ERR_WRONG_ARG
			CONF_FILE="$1" ;;
		"-n")
			shift
			[ $# -ge 1 ] || fn_err "missing name" $ERR_WRONG_ARG
			PROJ_NAME="$1" ;;
		"--help"|"-h")
			fn_help
			exit ;;
	########"create")
	########	shift
	########	[ $# -ge 1 ] || fn_err "missing project type" $ERR_WRONG_ARG
	########	CREATE_PROJ="$1" ;;
		*)
			fn_err "$1: invalid argument" $ERR_WRONG_ARG ;;
	esac	# --- end of case ---
	# Delete $1
	shift
done

[[ "$PROJ_NAME" ]] || fn_err "no project name specified" $ERR_WRONG_ARG

# reading conf file
[ -f "$CONF_FILE" ] || fn_err "need configuration file '$CONF_FILE'" $ERR_NO_FILE
m_say "reading configuration file '$CONF_FILE'..."
. $CONF_FILE

# set trap
trap "[ -d ./'$PROJ_NAME' ] && rm -rf --verbose ./'$PROJ_NAME'" ERR

# copying template
m_say "installing template..."
[ -d "$SRC_DIR" ] || fn_err "can't find template directory '$SRC_DIR'" $ERR_NO_FILE
cp -r "$SRC_DIR" ./"$PROJ_NAME"
pushd ./"$PROJ_NAME" || fn_err "can't cd to ./'$PROJ_NAME'" $ERR_NO_FILE

# reset trap 
trap "[ -d ../'$PROJ_NAME' ] && pushd && rm -rf --verbose ./'$PROJ_NAME'" ERR

# premake
[ $PREMAKE -eq 1 ] && fn_checkPremake
if [[ $PREMAKE_CMD ]] ; then
	m_say "running '$PREMAKE_CMD' for '$PREMAKE_TYPE'..."
	$PREMAKE_CMD $PREMAKE_TYPE || fn_err "'premake' failed (is PREMAKE_TYPE set?)" $?
else
	fn_err "need 'premake4' or 'premake5' (command not found)" $ERR_NO_FILE
fi

# make README
[ $README -eq 1 ] && m_say "making $README_FILE..." &&  echo "# $PROJ_NAME" > $README_FILE

# run git
[ $GIT_INIT -eq 1 ] && fn_needCmd "git" && m_say "running 'git'..." && git init

# run make
[ $MAKE -eq 1 ] && fn_needCmd "make" && m_say "running 'make'..." && make
