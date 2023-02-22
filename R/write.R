#' Write a file to S3
#'
#' @param local_file_path A character string containing the filename (or full file path) of the file you want to upload to S3.
#' @param s3_path A character string containing the full path to where the file should be stored in S3, including any directory names and the bucket name.
#' @param overwrite A logical indicating whether to overwrite the file if it already exists.
#' @param multipart A logical indicating whether to use multipart uploads. See \url{http://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html}. If the file specified by \code{local_file_path} is less than 100 MB, this is ignored.
#' @return Returns nothing
#' @export
#'
#' @examples write_file_to_s3("myfiles/mydata.csv", "alpha-everyone/delete/my_csv.csv")
write_file_to_s3 <- function(local_file_path, s3_path, overwrite=FALSE, multipart=TRUE) {
  p <- parse_path(s3_path)

  if (overwrite || !(s3_file_exists(s3_path))) {
    tryCatch(
      {
        if (multipart) {
          upload(s3_svc(), local_file_path, p$bucket, p$key)
        } else {
          s3_svc()$put_object(
            Body = local_file_path,
            Bucket = p$bucket,
            Key = p$key
          )
        }
      },
      error = function(c) {
        message(glue::glue("Could not upload {local_file_path} to {s3_path}"),
                appendLF = TRUE)
        stop(c, appendLF = TRUE)
      }
    )
  } else {
    stop("File already exists and you haven't set overwrite = TRUE, stopping")
  }

  return()
}

#' Write an object to S3 using a function
#'
#' @param x A local object, such as a dataframe
#' @param f A function of the form f(object, path, ...) where object is the type of x and path is a filename
#' @param s3_path A character string containing the full path to where the file should be stored in S3, including any directory names and the bucket name.
#' @param overwrite A logical indicating whether to overwrite the file if it already exists.
#' @param multipart A logical indicating whether to use multipart uploads. See \url{http://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html}. If the file specified by \code{local_file_path} is less than 100 MB, this is ignored.
#' @return Returns nothing
#' @export
#'
#' @examples write_using(my_dataframe, readr::write_csv, "alpha-everyone/delete/my_csv.csv")
#' @examples write_using(my_dataframe, feather::write_feather, "alpha-everyone/delete/my_feather.feather")
write_using <- function(x, f, s3_path, overwrite=FALSE, multipart=TRUE, ...) {
  fext <- dot_file_ext(s3_path)
  tmp_location <- tempfile(fileext = fext)
  f(x, tmp_location, ...)
  write_file_to_s3(tmp_location, s3_path, overwrite = overwrite,
                   multipart = multipart)
  unlink(tmp_location)
}


#' Write an in-memory data frame to a csv file stored in S3
#'
#' @param df A data frame you want to upload to S3.
#' @param s3_path A character string containing the full path to where the file should be stored in S3, including any directory names and the bucket name.
#' @param overwrite A logical indicating whether to overwrite the file if it already exists.
#' @param multipart A logical indicating whether to use multipart uploads. See \url{http://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html}. If \code{df} is less than 100 MB when written to csv, this is ignored.
#' @return Returns nothing
#' @export
#'
#' @examples write_df_to_csv_in_s3(df, "alpha-everyone/delete/my_csv.csv")
write_df_to_csv_in_s3 <- function(df, s3_path, overwrite=FALSE, multipart=TRUE, ...) {
  write_using(df, write.csv, s3_path, overwrite=overwrite, multipart=multipart, ...)
}


#' Write an in-memory data frame to a csv file stored in S3
#'
#' @description This function is similar to \code{\link{write_df_to_csv_in_s3}} but uses \code{\link[utils]{write.table}} to write the data frame to a csv as opposed to \code{\link[utils]{write.csv}}. This allows the following additional arguments to be passed to \code{\link[utils]{write.table}}: \code{append}, \code{col.names}, \code{sep}, \code{dec}, \code{qmethod}.
#'
#' @param df A data frame you want to upload to S3.
#' @param s3_path A character string containing the full path to where the file should be stored in S3, including any directory names and the bucket name.
#' @param overwrite A logical indicating whether to overwrite the file if it already exists.
#' @param multipart A logical indicating whether to use multipart uploads. See \url{http://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html}. If \code{df} is less than 100 MB when written to csv, this is ignored.
#' @param sep A string used to separate values within each row of \code{df}.
#' @param ... Additional arguments passed to \code{write.table}.
#' @return Returns nothing
#' @export
#'
#' @examples write_df_to_table_in_s3(df, "alpha-everyone/delete/my_csv.csv")
write_df_to_table_in_s3 <- function(df, s3_path, overwrite=FALSE, multipart=TRUE, sep=",", ...) {
  write_using(df, write.table, s3_path, overwrite=overwrite, multipart=multipart, ...)
}



