REGION = "eu-west-1"

#' Obtain a paws S3 client using MoJ AP defaults.
#'
#' This function should be called each time you would use a paws::s3 client. It
#' sets the default region and handles authentication for the Analytical
#' Platform.
#'
#' @return paws::s3 client
#' @export
#'
#' @examples
#' Rs3tools::s3_svc()$put_object(Body = "filetoupload", Bucket = "examplebucket", Key = "objectkey")
s3_svc <- function(region = REGION, ...) {
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

    paws_obj_out <- paws::s3(
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
    paws_obj_out <- paws::s3(config=list(region=REGION))

  }

  return(paws_obj_out)
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
