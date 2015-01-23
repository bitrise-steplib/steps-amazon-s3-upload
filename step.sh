#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

formatted_output_file_path="${BITRISE_STEP_FORMATTED_OUTPUT_FILE_PATH}"

function echo_string_to_formatted_output {
  echo "$1" >> ${formatted_output_file_path}
}

function write_section_to_formatted_output {
  echo '' >> ${formatted_output_file_path}
  echo "$1" >> ${formatted_output_file_path}
  echo '' >> ${formatted_output_file_path}
}

function print_failed_message {
  fail_msg="$1"
  echo " [!] ${fail_msg}"
  write_section_to_formatted_output "## Failed"
  write_section_to_formatted_output "${fail_msg}"
}

write_section_to_formatted_output "# S3 Upload"


if [ ! -n "${AWS_ACCESS_KEY_ID}" ]; then
  echo ' [!] Input AWS_ACCESS_KEY_ID is missing'
  print_failed_message 'Input AWS_ACCESS_KEY_ID is missing'
  exit 1
fi

if [ ! -n "${AWS_SECRET_ACCESS_KEY}" ]; then
  print_failed_message 'Input AWS_SECRET_ACCESS_KEY is missing'
  write_section_to_formatted_output
  exit 1
fi

if [ ! -n "${S3_UPLOAD_LOCAL_PATH}" ]; then
  print_failed_message 'Input S3_UPLOAD_LOCAL_PATH is missing'
  exit 1
fi

# this expansion is required for paths with ~
#  more information: http://stackoverflow.com/questions/3963716/how-to-manually-expand-a-special-variable-ex-tilde-in-bash
eval expanded_upload_local_path="${S3_UPLOAD_LOCAL_PATH}"

if [ ! -n "${S3_UPLOAD_BUCKET}" ]; then
  print_failed_message 'Input S3_UPLOAD_BUCKET is missing'
  exit 1
fi

if [ ! -e "${expanded_upload_local_path}" ]; then
  print_failed_message "The specified local path doesn't exist at: ${expanded_upload_local_path}"
  exit 1
fi


function print_and_do_command {
  echo "$ $@"
  $@
}

function do_failed_cleanup {
  write_section_to_formatted_output "## Failed"
  write_section_to_formatted_output "Check the Logs for details."
}

function print_and_do_command_cleanup_and_exit_on_error {
  print_and_do_command $@
  if [ $? -ne 0 ]; then
    do_failed_cleanup
    echo " [!] Failed!"
    exit 1
  fi
}

s3cmd_config_file_path="s3cfg.config"

# s3cmd OS X fix
bash "${THIS_SCRIPT_DIR}/__s3cmd_osx_fix.sh"
if [ $? -ne 0 ] ; then
  echo "[!] Failed to apply required s3cmd fix"
  exit 1
fi

echo "Checking s3cmd version"
print_and_do_command s3cmd --version
if [ $? -ne 0 ] ; then
  echo "No s3cmd version found, installing..."
  print_and_do_command_cleanup_and_exit_on_error brew install s3cmd
  print_and_do_command_cleanup_and_exit_on_error s3cmd --version
else
  echo " (i) s3cmd found, no need to install it"
fi

printf %"s\n" '[default]' "access_key = ${AWS_ACCESS_KEY_ID}" "secret_key = ${AWS_SECRET_ACCESS_KEY}" > "${s3cmd_config_file_path}"

s3_url="s3://${S3_UPLOAD_BUCKET}"
print_and_do_command_cleanup_and_exit_on_error s3cmd -c "${s3cmd_config_file_path}" sync "${expanded_upload_local_path}" "${s3_url}" --delete-removed

aclcmd='--acl-private'
if [ "${S3_ACL_CONTROL}" == 'public-read' ]; then
  echo " (i) ACL 'public-read' specified!"
  aclcmd='--acl-public'
fi
print_and_do_command_cleanup_and_exit_on_error s3cmd -c "${s3cmd_config_file_path}" setacl "${s3_url}" ${aclcmd} --recursive

print_and_do_command_cleanup_and_exit_on_error rm "${s3cmd_config_file_path}"


write_section_to_formatted_output "## Success"
echo_string_to_formatted_output "* **Access Control** set to: **${S3_ACL_CONTROL}**"
echo_string_to_formatted_output "* **Base URL**: [http://${S3_UPLOAD_BUCKET}.s3.amazonaws.com/](http://${S3_UPLOAD_BUCKET}.s3.amazonaws.com/)"
