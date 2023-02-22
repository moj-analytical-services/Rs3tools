# Checks if an expiry time has been reached, allowing for a window of five
# minutes by default
expired_auth <- function(expiry_t, window = 5 * 60) {
  ifelse(
    is.null(expiry_t),
    TRUE,
    as.POSIXct(Sys.time(), tz='UTC') + window > expiry_t
  )
}

# Check for region in environment variables, otherwise use 'eu-west-1'
# as the default
get_region <- function() {
  if (nchar(Sys.getenv("AWS_DEFAULT_REGION")) > 0) {
    return(Sys.getenv("AWS_DEFAULT_REGION"))
  } else if (nchar(Sys.getenv("AWS_REGION")) > 0) {
    return(Sys.getenv("AWS_REGION"))
  } else {
    return("eu-west-1")
  }
}

s3_gen <- function(){

  ## Create the state variables which will keep track of the system
  # S3 service
  Rs3tools.s3 <- NULL
  # Will credentials need reauthentication (i.e. not handled by paws)?
  Rs3tools.temporary_authentication <- FALSE
  # Expiration of current credentials, if needed
  Rs3tools.authentication_expiry <- NULL
  # Expiration of current credentials, if needed
  Rs3tools.region <- NULL

  ## Returns a function which both returns the required s3 object
  ## and super assigns it (and the other state variables) to the variables above
  function(region=NULL, refresh_credentials=FALSE, session_duration=3600) {
    # If the S3 service is yet to be set or the credentials are about to
    # expire, get new credentials
    if (refresh_credentials | is.null(Rs3tools.s3) |
        (Rs3tools.temporary_authentication
         & expired_auth(Rs3tools.authentication_expiry))) {

      # If there is already an s3 instance then we must be refreshing
      # so we tell the user, and also use the previous region, unless
      # it has been provided explicitly (i.e. region is not NULL)
      if (!is.null(Rs3tools.s3)) {
       message("Refreshing credentials with AWS")
       if (is.null(region)) region <- Rs3tools.region
      } else {
        if (is.null(region)) region <- get_region()
      }
      # set the region state variable to the region used
      Rs3tools.region <<- region

      aws_role_arn <- Sys.getenv('AWS_ROLE_ARN')
      aws_web_identity_token_file <- Sys.getenv('AWS_WEB_IDENTITY_TOKEN_FILE')

      # Check if the user has the AWS_ROLE_ARN environment variable set
      # and if set: force paws to use the AssumeRoleWithWebIdentity auth method
      # if not set: let paws choose an auth method based on its own defaults
      if (nchar(aws_role_arn) > 0 & nchar(aws_web_identity_token_file) > 0) {

        user <- stringr::str_split(aws_role_arn, '/')[[1]][2]
        role_session_name = glue::glue("{user}_{as.numeric(Sys.time())}")
        query = glue::glue(
          "https://sts.amazonaws.com/",
          "?Action=AssumeRoleWithWebIdentity",
          "&DurationSeconds={session_duration}",
          "&RoleSessionName={role_session_name}",
          "&RoleArn={aws_role_arn}",
          "&WebIdentityToken={readr::read_file(aws_web_identity_token_file)}",
          "&Version=2011-06-15"
        )
        response <- httr::POST(query)

        if (!is.null(httr::content(response)$Error$Message)) rlang::abort(c("Something went wrong getting temporary credentials",
                                                                            "*" = "The message from https://sts.amazonaws.com/ is:",
                                                                            "i" = httr::content(response)$Error$Message))

        credentials <- httr::content(response)$AssumeRoleWithWebIdentityResponse$AssumeRoleWithWebIdentityResult$Credentials
        Rs3tools.temporary_authentication <<- TRUE
        Rs3tools.authentication_expiry <<-
          as.POSIXct(credentials$Expiration, origin = "1970-01-01", tz="UTC")

        Rs3tools.s3 <<- paws::s3(
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
        Rs3tools.s3 <<- paws::s3(config=list(region=region))

      }
    }

    return(Rs3tools.s3)
  }

}

# This creates the s3_svc function which carries its own state environment
# as defined above
s3_svc <- s3_gen()

#' Refresh S3 credentials
#'
#' @export
#' @examples
#' Rs3tools::refresh_credentials()
refresh_credentials <- function() {
  s3_svc(refresh_credentials=TRUE)
  return(NULL)
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

dot_file_ext <- function(path) {
  paste0('.', tools::file_ext(path))
}
