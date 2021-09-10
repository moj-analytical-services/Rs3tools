#' Return a dataframe of accessible files, including full path and filesize information
#' Note:  The listing includes folders as well as files. The etag and storageclass
#' columns are kept for compatibility with s3tools but are NA as they are not
#' listed by botor.
#'
#' @param bucket_filter return only buckets that match this character vector of bucket names e.g. "alpha-everyone"
#' @param prefix filter files which begin with this prefix e.g. 'my_folder/'
#' @param path_only boolean - return the accessible paths only, as a character vector
#' @param max UNUSED - kept for compatibility, all objects will always be returned
#'
#' @export
#' @return data frame with path of all files available to you in S3.
#' @examples list_files_in_buckets(bucket_filter = "alpha-everyone", prefix = "GeographicData", path_only = FALSE, max = Inf)
#'
list_files_in_buckets <- function(bucket_filter=NULL, prefix=NULL, path_only=FALSE, max=NULL) {
    fs <- purrr::map(
      bucket_filter,
      list_files_in_bucket,
      prefix=prefix) %>%
      dplyr::bind_rows() %>%
      as.data.frame()

    if (path_only) {
      return(fs$path)
    } else {
      return(fs)
    }
}

list_files_in_bucket <- function(bucket, prefix=NULL) {
  uri <- httr::parse_url(full_s3_path(bucket))
  uri$path <- prefix
  uri <- httr::build_url(uri)

  file_list <- botor::s3_ls(uri)
  if (is.null(file_list)) {
    return(NULL)
  }

  file_list %>%
    dplyr::mutate(
      # Lose the trailing "/" for directories
      # (directories are shown in the filenames in s3tools)
      key = stringr::str_replace(key, "/$", ""),
      filename = stringr::str_extract(key, "[^/]*$"),
      size_readable = gdata::humanReadable(size),
      # Not included in s3_ls
      etag = NA,
      storageclass = NA
    ) %>%
    dplyr::select(
      filename,
      path = uri,
      size_readable,
      key,
      lastmodified = last_modified,
      etag,
      size,
      storageclass,
      bucket = bucket_name
    )
}

