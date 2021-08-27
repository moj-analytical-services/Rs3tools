#' Return a dataframe of accessable files, including full path and filesize information
#' Note:  The listing includes folders as well as files
#'
#' @param bucket_filter return only buckets that match this character vector of bucket names e.g. "alpha-everyone"
#' @param prefix filter files which begin with this prefix e.g. 'my_folder/'
#' @param path_only boolean - return the accessible paths only, as a character vector
#' @param max An integer indicating the maximum number of keys to return. The function will recursively access the bucket in case max > 1000. Use max = Inf to retrieve all objects.
#'
#' @export
#' @return data frame with path of all files available to you in S3.
#' @examples list_files_in_buckets(bucket_filter = "alpha-everyone", prefix = "GeographicData", path_only = FALSE, max = Inf)
#'
list_files_in_buckets <- function(bucket_filter=NULL, prefix=NULL, path_only=FALSE, max=NULL) {
    fs <- purrr::map(
      bucket_filter,
      list_files_in_bucket,
      prefix=prefix, max=max) %>%
      dplyr::bind_rows() %>%
      as.data.frame()

    if (path_only) {
      return(fs$path)
    } else {
      return(fs)
    }
}


list_files_in_bucket <- function(bucket, prefix=NULL, max=NULL) {
  result <- NULL
  continuation <- NULL
  s3_svc <- s3_svc()

  # Repeatedly retrieve records until there are no more left or the
  # max has been reached
  repeat {
    tryCatch(
      {
        objects <- s3_svc$list_objects_v2(
          bucket, Prefix = prefix, MaxKeys = min(max, 1000),
          ContinuationToken = continuation
          )
      },
      error = function(c) {
        message("Can't list files in bucket ", bucket)
        stop(c, appendLF = TRUE)
      }
    )

    files_t <- objects$Contents %>%
      # Remove the Owner as it's unused and contains two values
      # which duplicates the tibble
      purrr::map(function(c) { c$Owner = NULL; c }) %>%
      # Convert from lists into tibble rows
      purrr::map(tibble::as_tibble) %>%
      # and merge the rows
      dplyr::bind_rows() %>%
      # Add the extra s3tools fields
      dplyr::mutate(
        # Lose the trailing "/" for directories
        # (directories are shown in the filenames in s3tools)
        Key = stringr::str_replace(Key, "/$", ""),
        filename = stringr::str_extract(Key, "[^/]*$"),
        path = glue::glue("{bucket}/{Key}"),
        size_readable = gdata::humanReadable(Size),
        bucket = bucket
      ) %>%
      dplyr::select(
        filename, path, size_readable,
        key = Key,
        lastmodified = LastModified,
        etag = ETag,
        size = Size,
        storageclass = StorageClass,
        bucket
      )

    if (is.null(result)) {
      result <- files_t
    } else {
      result <- dplyr::bind_rows(result, files_t)
    }

    # Check if we've finished i.e. we've got the number of records we asked
    # for or there are no more to retrieve (no continuation token),
    # otherwise go again using the continuation token as a starting point
    # and reducing the max based on the number already retrieved.
    if (is.null(max) || (objects$KeyCount >= max) ||
        identical(objects$NextContinuationToken, character(0))) {
      return(result)
    } else {
        max = max - objects$KeyCount
        continuation = objects$NextContinuationToken
    }
  }
}

