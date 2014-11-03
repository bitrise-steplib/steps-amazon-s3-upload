steps-amazon-s3-upload
======================

Syncs the given local folder with an S3 bucket.

This Step requires an Amazon S3 registration. To register an Amazon S3 account, [click here](http://aws.amazon.com/s3/)

This Step is part of the [Open StepLib](http://www.steplib.com/), you can find its StepLib page [here](http://www.steplib.com/step/amazon-s3-uploader)


# Warning!

It will perform a one-direction sync, removing every file and folder from
the bucket which is not present in the local, input folder!


# Inputs

See the *step.yml* file for details.


# Note

Uses the s3cmd utility, installed through [homebrew](http://brew.sh/).


# TODO
* export the sync result (success/error) to an Environment Variable, so other Steps can access it
