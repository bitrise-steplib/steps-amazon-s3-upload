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


if [ ! -n "${access_key_id}" ]; then
  echo ' [!] Input access_key_id is missing'
  print_failed_message 'Input access_key_id is missing'
  exit 1
fi

if [ ! -n "${secret_access_key}" ]; then
  print_failed_message 'Input secret_access_key is missing'
  write_section_to_formatted_output
  exit 1
fi

if [ ! -n "${upload_local_path}" ]; then
  print_failed_message 'Input upload_local_path is missing'
  exit 1
fi

# this expansion is required for paths with ~
#  more information: http://stackoverflow.com/questions/3963716/how-to-manually-expand-a-special-variable-ex-tilde-in-bash
eval expanded_upload_local_path="${upload_local_path}"

if [ ! -n "${upload_bucket}" ]; then
  print_failed_message 'Input upload_bucket is missing'
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

printf %"s\n" '[default]' "access_key = ${access_key_id}" "secret_key = ${secret_access_key}" > "${s3cmd_config_file_path}"

s3_url="s3://${upload_bucket}"
print_and_do_command_cleanup_and_exit_on_error s3cmd -c "${s3cmd_config_file_path}" sync "${expanded_upload_local_path}" "${s3_url}" --delete-removed

aclcmd='--acl-private'
if [ "${acl_control}" == 'public-read' ]; then
  echo " (i) ACL 'public-read' specified!"
  aclcmd='--acl-public'
fi
print_and_do_command_cleanup_and_exit_on_error s3cmd -c "${s3cmd_config_file_path}" setacl "${s3_url}" ${aclcmd} --recursive

print_and_do_command_cleanup_and_exit_on_error rm "${s3cmd_config_file_path}"


write_section_to_formatted_output "## Success"
echo_string_to_formatted_output "* **Access Control** set to: **${acl_control}**"
echo_string_to_formatted_output "* **Base URL**: [http://${upload_bucket}.s3.amazonaws.com/](http://${upload_bucket}.s3.amazonaws.com/)"
