# labs3tools

Helper tools to access Amazon S3, compatible with [s3tools](https://github.com/moj-analytical-services/s3tools).

## What does this do?
This library is mostly compatible with `s3tools`, which is being retired as we
migrate to the new version of the Analytical Platform, so you can replace 
`s3tools` with `labs3tools` in your code and you should be good to go. 

[paws](https://paws-r.github.io/) is used to access AWS, which is native R so
there's no need to configure Python via `reticulate`.

