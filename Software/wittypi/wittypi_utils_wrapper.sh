#!/bin/bash
# file: wittypi_utils_wrapper.sh
#
# This script is a wrapper, that can be used to invoke functions
# in the utilities.sh script in the wittypi install folder.
#
# Examples:
#
# wittypi_utils_wrapper.sh get_rtc_time
#
# wittypi_utils_wrapper.sh set_startup_time 26 10 00 00      # date hour min sec
#
#

# get current directory and schedule file path
wittypi_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# utilities
. "$wittypi_dir/utilities.sh"
<<<<<<< HEAD
. "$wittypi_dir/gpio-utils.sh"
=======
. "$wittypi_dir/gpio-util.sh"
>>>>>>> minimal_source

# Get the function name and remove it from the argument list
function_name=$1
shift 1  # remove the first argument from $@

# Check if the function exists
if ! type "$function_name" >/dev/null 2>&1; then
  echo "Error: function '$function_name' not found" 1>&2
  exit 1
fi

# Call the desired function with arguments
# and the output
output=$("$function_name" "$@")

# Print the output
echo "$output"