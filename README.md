steps-amazon-s3-upload
======================

Syncs the given local folder with an S3 bucket.

# Warning!

It will perform a one-direction sync, removing every file and folder from
the bucket which is not present in the local, input folder!


# Inputs

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- S3_UPLOAD_BUCKET
- S3_UPLOAD_LOCAL_PATH : if you want to sync only the content of the folder, but don't want to create the folder then you should append a slash at the end of the path. Example: ./folder/
- S3_ACL_CONTROL : can be 'public-read' or 'private'. 'private' is the default.


# Note

Uses the s3cmd utility, installed through brew.


# TODO

//- proper error handling: return non-zero exit code if fails
//    - if it can't find it's local, source path (it doesn't exist) then it's also a fail!
- export the sync result (success/error) to an Environment Variable, so other Steps can access it
- test with invalid inputs
