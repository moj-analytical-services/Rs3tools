REGION = "eu-west-1"

s3_svc <- function(region = REGION, ...) {
  aws_role_arn <- Sys.getenv('AWS_ROLE_ARN')
  user <- stringr::str_split(aws_role_arn, '/')[[1]][2]
  role_session_name = glue::glue("{user}_{as.numeric(Sys.time())}")
  query = glue::glue(
    "https://sts.amazonaws.com/",
    "?Action=AssumeRoleWithWebIdentity",
    "&RoleSessionName={role_session_name}",
    "&RoleArn={aws_role_arn}",
    "&WebIdentityToken={readr::read_file(Sys.getenv('AWS_WEB_IDENTITY_TOKEN_FILE'))}",
    "&Version=2011-06-15"
  )
  response <- httr::POST(query)
  credentials <- httr::content(response)$AssumeRoleWithWebIdentityResponse$AssumeRoleWithWebIdentityResult$Credentials

  paws::s3(
    config = list(
      credentials = list(
        creds = list(
          access_key_id = credentials$AccessKeyId,
          secret_access_key = credentials$SecretAccessKey,
          session_token = credentials$SessionToken
        )
      ),
      region = region
    )
  )
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
