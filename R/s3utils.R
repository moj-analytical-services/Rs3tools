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
