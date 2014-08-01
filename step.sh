#!/bin/bash

formatted_output_file_path="$BITRISE_STEP_FORMATTED_OUTPUT_FILE_PATH"

function echo_string_to_formatted_output {
  echo "$1" >> $formatted_output_file_path
}

function write_section_to_formatted_output {
  echo '' >> $formatted_output_file_path
  echo "$1" >> $formatted_output_file_path
  echo '' >> $formatted_output_file_path
}

write_section_to_formatted_output "# S3 Upload"


if [ ! -n "$AWS_ACCESS_KEY_ID" ]; then
  echo ' [!] Input AWS_ACCESS_KEY_ID is missing'
  exit 1
fi

if [ ! -n "$AWS_SECRET_ACCESS_KEY" ]; then
  echo ' [!] Input AWS_SECRET_ACCESS_KEY is missing'
  exit 1
fi

if [ ! -n "$S3_UPLOAD_LOCAL_PATH" ]; then
  echo ' [!] Input S3_UPLOAD_LOCAL_PATH is missing'
  exit 1
fi

if [ ! -n "$S3_UPLOAD_BUCKET" ]; then
  echo ' [!] Input S3_UPLOAD_BUCKET is missing'
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


print_and_do_command_cleanup_and_exit_on_error brew install s3cmd
print_and_do_command_cleanup_and_exit_on_error s3cmd --version
printf %"s\n" '[default]' "access_key = $AWS_ACCESS_KEY_ID" "secret_key = $AWS_SECRET_ACCESS_KEY" > $HOME/.s3cfg

s3_url="s3://$S3_UPLOAD_BUCKET"
print_and_do_command_cleanup_and_exit_on_error s3cmd sync "$S3_UPLOAD_LOCAL_PATH" "$s3_url" --delete-removed

aclcmd='--acl-private'
if [ "$S3_ACL_CONTROL" == 'public-read' ]; then
  echo " (i) ACL 'public-read' specified!"
  aclcmd='--acl-public'
fi
print_and_do_command_cleanup_and_exit_on_error s3cmd setacl "$s3_url" $aclcmd --recursive

print_and_do_command_cleanup_and_exit_on_error rm $HOME/.s3cfg


write_section_to_formatted_output "## Success"
echo_string_to_formatted_output "* **Access Control** set to: **${S3_ACL_CONTROL}**"
echo_string_to_formatted_output "* **Base URL**: [http://${S3_UPLOAD_BUCKET}.s3.amazonaws.com/](http://${S3_UPLOAD_BUCKET}.s3.amazonaws.com/)"
