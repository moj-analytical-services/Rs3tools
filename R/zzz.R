Rs3tools.env <- new.env()
.onLoad <- function(libname, pkgname) {
  # S3 service
  Rs3tools.env$s3 <- NULL
  # Will credentials need reauthentication (i.e. not handled by paws)?
  Rs3tools.env$temporary_authentication <- FALSE
  # Expiration of current credentials, if needed
  Rs3tools.env$authentication_expiry <- NULL
}
