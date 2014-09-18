steps-amazon-s3-upload
======================

Syncs the given local folder with an S3 bucket.

# Warning!

It will perform a one-direction sync, removing every file and folder from
the bucket which is not present in the local, input folder!


# Inputs

See the *step.yml* file for details.


# Note

Uses the s3cmd utility, installed through [homebrew](http://brew.sh/).


# TODO
* export the sync result (success/error) to an Environment Variable, so other Steps can access it
