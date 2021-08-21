REGION = "eu-west-1"

if (Sys.getenv("AWS_REGION") == "")
{
  if (Sys.getenv("AWS_DEFAULT_REGION") != "") {
    Sys.setenv("AWS_REGION" = Sys.getenv("AWS_DEFAULT_REGION"))
  } else {
    Sys.setenv("AWS_REGION" = REGION)
  }
}

parse_path <- function(s3_path) {
  s3_path <- stringr::str_replace(s3_path, "s3://", "")
  split_path <- stringr::str_split(s3_path, "/")[[1]]
  bucket <- split_path[1]
  key <- stringr::str_c(split_path[-1], collapse="/")

  list(bucket=bucket, key=key)
}

s3_file_exists <- function(s3_path) {
  p <- parse_path(s3_path)
  exists <- FALSE
  try(
    {
      paws::s3()$head_object(Bucket=p$bucket, Key=p$key)
      exists <- TRUE
    },
    silent=TRUE
  )
  return(exists)
}
