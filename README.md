steps-amazon-s3-upload
======================

Syncs the given local folder with an S3 bucket.


# Warning!

It will remove every other folder from the bucket!


# Inputs

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- S3_UPLOAD_BUCKET
- S3_UPLOAD_LOCAL_PATH : if you want to sync only the content of the folder, but don't want to create the folder then you should append a slas at the end of the path. Example: ./folder/


# Note

Uses the s3cmd utility, installed through brew.