REGION = "eu-west-1"

# Checks if an expiry time has been reached, allowing for a window of five
# minutes by default
expired_auth <- function(expiry_t, window = 5 * 60) {
  ifelse(
    is.null(expiry_t),
    TRUE,
    as.POSIXct(Sys.time(), tz='UTC') + window > expiry_t
  )
}

s3_svc <- function(region = REGION, ...) {
  # If the S3 service is yet to be set or the credentials are about to
  # expire, get new credentials
  if (is.null(Rs3tools.env$s3) |
      (Rs3tools.env$temporary_authentication
       & expired_auth(Rs3tools.env$authentication_expiry))) {
    aws_role_arn <- Sys.getenv('AWS_ROLE_ARN')

    # Check if the user has the AWS_ROLE_ARN environment variable set
    # and if set: force paws to use the AssumeRoleWithWebIdentity auth method
    # if not set: let paws choose an auth method based on its own defaults
    if (nchar(aws_role_arn) > 0) {

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
      Rs3tools.env$temporary_authentication <- TRUE
      Rs3tools.env$authentication_expiry <-
        as.POSIXct(credentials$Expiration, origin = "1970-01-01", tz="UTC")

      Rs3tools.env$s3 <- paws::s3(
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
    } else {

      # This doesn't specify the configuration except the region
      # so paws will use its own default methods to choose the auth
      Rs3tools.env$s3 <- paws::s3(config=list(region=REGION))

    }
  }

  return(Rs3tools.env$s3)
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
