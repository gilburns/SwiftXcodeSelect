#!/bin/zsh

# Save IFS
OLDIFS=$IFS

VERSION="1.0"
VERSIONDATE="2023-01-01"

LOG_FOLDER="/private/var/log"
LOG_NAME="Xcode-Select.log"
JAMF_BINARY="/usr/local/bin/jamf"
DIALOG_APP="/usr/local/bin/dialog"
DIALOG_ICON="https://developer.apple.com/assets/elements/icons/xcode-12/xcode-12-256x256.png"
DIALOG_INITIAL_TITLE="Select Active Xcode Tools"
DIALOG_TIMEOUT=60

# Use Self Service's icon for the overlayicon
OVERLAY_ICON=$( /usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path )

echo_logger() {
    LOG_FOLDER="${LOG_FOLDER:=/private/var/log}"
    LOG_NAME="${LOG_NAME:=log.log}"

    mkdir -p "${LOG_FOLDER}"

    echo -e "$(date) - $1" | tee -a ${LOG_FOLDER}/${LOG_NAME}
}

echo_logger "-------------------------------"
echo_logger "Starting new run…"
echo_logger "-------------------------------"

# Get current Xcode tools path, strip the path if inside the app
#
XC_CURRENT_PATH=$(/usr/bin/xcode-select -p)
if [[ "${XC_CURRENT_PATH}" == *"/Contents/Developer"* ]]; then
	XC_CURRENT_PATH=${XC_CURRENT_PATH%"/Contents/Developer"}
fi
echo_logger "Current Path: ${XC_CURRENT_PATH}"
echo_logger " "

# Check for Xcode multi-installs
#
XC_APP_ARRAY=()

IFS=$'\n'

# Find installed Xcode.app(s) and sort list
XC_APP_ARRAY=($(system_profiler SPDeveloperToolsDataType | grep Location | cut -d':' -f2 | sed 's/^[ \t]*//'))

XC_APP_ARRAY=($(sort <<<"${XC_APP_ARRAY[*]}"))

unset IFS

# Check for Xcode command line tools and add to the array if present
#

# Xcode Command Line Tools
XC_CLT_DIR="/Library/Developer/CommandLineTools"

# If it exists add to the array
if [ -d "${XC_CLT_DIR}" ]; then
	XC_APP_ARRAY+=("${XC_CLT_DIR}")
fi

# Check if the array holds the currently set path
#
if [[ ! " ${XC_APP_ARRAY[*]} " =~ " ${XC_CURRENT_PATH} " ]]; then
    XC_APP_ARRAY+=("${XC_CURRENT_PATH}")
fi

# Comma separate the array of Xcode paths for the popup menu
printf -v XC_APP_ARRAY_JOINED '%s,' "${XC_APP_ARRAY[@]}"

DIALOG_CMD=(
    "--title \"${DIALOG_INITIAL_TITLE}\""
    "--titlefont \"weight=bold,size=20\""
    "--icon \"${DIALOG_ICON}\""
	"--overlayicon \"${OVERLAY_ICON}\""
    "--position center"
    "--message \"**View or change the path to the active developer directory.**\n\nThis directory controls which tools are used for the Xcode command line tools (for example, xcodebuild) as well as the BSD development commands (such as cc and make).
\""
    "--messagefont \"weight=regular,size=16\""
    "--small"
    "--ontop"
    "--moveable"
	"--button1text \"Set Path…\""
	"--button2"
	"--selecttitle \"Xcode Default Tools:\""
	"--selectvalues \"${XC_APP_ARRAY_JOINED%,}\""
	"--selectdefault ${XC_CURRENT_PATH}"
	"--timer ${DIALOG_TIMEOUT}"
	"--hidetimerbar"
)

if [ ! -f "${DIALOG_APP}" ]; then
    echo_logger "swiftDialog not installed"
    dialog_latest=$( curl -sL https://api.github.com/repos/bartreardon/swiftDialog/releases/latest )
    dialog_url=$(get_json_value "${dialog_latest}" 'assets[0].browser_download_url')
    curl -L --output "dialog.pkg" --create-dirs --output-dir "/var/tmp" "${dialog_url}"
    installer -pkg "/var/tmp/dialog.pkg" -target /
fi

# Prompt the user to make a selection
echo_logger "Prompting for selection…"
MY_RESPONSE=$(eval "${DIALOG_APP}" "${DIALOG_CMD[*]}")
RESPONSE_CODE=$?

# Check to see which response was returned
if [ ${RESPONSE_CODE} -eq 0 ]; then
	# Get path value of the response
	MY_RESPONSE=$(echo "${MY_RESPONSE}" | grep "SelectedOption" | awk -F ": " '{print $NF}')
	MY_RESPONSE="$(echo "$MY_RESPONSE" | tr -d '"')"
	echo_logger "Selection made: ${MY_RESPONSE}"
	echo_logger " "
	# Check to see if the path changed or not
	if [[ "${MY_RESPONSE}" != "${XC_CURRENT_PATH}" ]];then
		/usr/bin/xcode-select --switch ${MY_RESPONSE} 2>/dev/null
		PATH_ACTION=$?
		if [ ${PATH_ACTION} -eq 0 ]; then
			echo_logger "Successfully changed default Xcode path"
			RESULT_TITLE="Change Successful!"
			RESULT_MESSAGE="The Xcode tool changed to:\n\n ${MY_RESPONSE}"
		else
			echo_logger "Something went wrong changing Xcode path"			
			RESULT_TITLE="Change Failed!"
			RESULT_MESSAGE="Xcode tools unchanged. Try again or contact IT.\n\n ${XC_CURRENT_PATH}"
		fi
	else
		echo_logger "Selection same as current"
		echo_logger "No changes"
		RESULT_TITLE="No Change"
		RESULT_MESSAGE="Xcode tools unchanged."
	fi	
elif [ ${RESPONSE_CODE} -eq 2 ]; then
	echo_logger "User canceled the dialog"
	echo_logger "No changes"
	RESULT_TITLE="No Change"
	RESULT_MESSAGE="Selection dialog canceled."
elif [ ${RESPONSE_CODE} -eq 4 ]; then
	echo_logger "Dialog timed out after ${DIALOG_TIMEOUT} seconds"
	echo_logger "No response from user"
	RESULT_TITLE="No Change"
	RESULT_MESSAGE="Selection dialog timed out."
fi

# Display final results to user
DIALOG_CMD=(
    "--title \"${RESULT_TITLE}\""
    "--titlefont \"weight=bold,size=20\""
    "--icon \"${DIALOG_ICON}\""
	"--overlayicon \"${OVERLAY_ICON}\""
    "--position center"
    "--message \"${RESULT_MESSAGE}\""
    "--messagefont \"weight=regular,size=16\""
    "--mini"
    "--ontop"
    "--moveable"
	"--button1"
)

eval "${DIALOG_APP}" "${DIALOG_CMD[*]}" &

# Restore IFS
IFS=$OLDIFS

exit 0