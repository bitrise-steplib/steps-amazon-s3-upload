#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

function echo_string_to_formatted_output {
  echo "$1"
}

function write_section_to_formatted_output {
  echo ''
  echo "$1"
  echo ''
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

aclcmd='private'
if [ "${acl_control}" == 'public-read' ]; then
  echo " (i) ACL 'public-read' specified!"
  aclcmd='public-read'
fi

trimmed_aws_region="$(echo -e "${aws_region}" | tr -d '[[:space:]]')"
if [ -n ${trimmed_aws_region} ]; then
  echo " (i) AWS region (${trimmed_aws_region}) specified!"
  export AWS_DEFAULT_REGION="${trimmed_aws_region}"
fi    

s3_url="s3://${upload_bucket}"
export AWS_ACCESS_KEY_ID="${access_key_id}"
export AWS_SECRET_ACCESS_KEY="${secret_access_key}"

# do a sync -> delete no longer existing objects
echo "$" aws s3 sync "${expanded_upload_local_path}" "${s3_url}" --delete --acl ${aclcmd}
aws s3 sync "${expanded_upload_local_path}" "${s3_url}" --delete --acl ${aclcmd}

if [[ "${set_acl_only_on_changed_objets}" != "true" ]] ; then
  echo "=> Setting ACL on every object, this can take some time..."
  # `sync` only sets the --acl for the modified files, so we'll
  #  have to query the objects manually, and set the required acl one by one
  IFS=$'\n'
  for a_s3_obj_key in $(aws s3api list-objects --bucket "${upload_bucket}" --query Contents[].[Key] --output text)
  do
    echo "$" aws s3api put-object-acl --acl ${aclcmd} --bucket "${upload_bucket}" --key "${a_s3_obj_key}"
    aws s3api put-object-acl --acl ${aclcmd} --bucket "${upload_bucket}" --key "${a_s3_obj_key}"
  done
  unset IFS
else
  echo "=> (!) ACL is only changed on objects which were changed by the sync"
fi

write_section_to_formatted_output "## Success"
echo_string_to_formatted_output "* **Access Control** set to: **${acl_control}**"
if [ -n ${AWS_DEFAULT_REGION} ]; then
  echo_string_to_formatted_output "* **AWS Region**: **${trimmed_aws_region}**"
fi
echo_string_to_formatted_output "* **Base URL**: [http://${upload_bucket}.s3.amazonaws.com/](http://${upload_bucket}.s3.amazonaws.com/)"
