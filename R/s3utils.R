full_s3_path <- function(s3_path) {
  if (stringr::str_detect(s3_path, "^s3://")) {
    return(s3_path)
  } else {
    return(glue::glue("s3://{s3_path}"))
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
  botor::s3_exists(full_s3_path(s3_path))
}
