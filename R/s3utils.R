REGION = "eu-west-1"

s3_svc <- function(region = REGION) {
  paws::s3(config = list(region = REGION))
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
      s3_svc()$head_object(Bucket=p$bucket, Key=p$key)
      exists <- TRUE
    },
    silent=TRUE
  )
  return(exists)
}
