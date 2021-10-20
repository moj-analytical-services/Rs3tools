# Rs3tools

Helper tools to access Amazon S3, compatible with 
[s3tools](https://github.com/moj-analytical-services/s3tools).

## WARNING - DO NOT USE
This library is experimental and unsupported. It is intended to aid the 
prisons data science team in the short term with the migration of multiple apps 
and airflow tasks to the new version of the Analytical Platform. 
Code using it will gradually be replaced with `botor`, `arrow`, etc.

### What does this do?
This library is mostly compatible with `s3tools`, which is being retired as we
migrate to the new version of the Analytical Platform, so you can replace 
`s3tools` with `labs3tools` in your code and you should be good to go. 

NB `s3tools::accessible_buckets` is not yet implemented.

This is based on the [paws library](https://paws-r.github.io/) which has the
advantage that it's R-native and doesn't depend on reticulated Python libraries.
However it reauthenticates with AWS for every function call which introduces
a small amount of latency.

### Installation
In an `renv` initiated project
```
renv::install("git@github.com:moj-analytical-services/Rs3tools.git")
```
otherwise
```
remotes::install_github("git@github.com:moj-analytical-services/Rs3tools.git")
```

