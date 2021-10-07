#' Read from S3 using a particular function
#'
#' @param FUN a function to parse the data into
#' @param ... arguments for said function
#' @param s3_path path to the s3 file bucket/folder/file.txt
#'
#' @return whatever the function returns
#' @export
#'
#' @examples labs3tools::read_using(FUN=readxl::read_excel, s3_path="alpha-test-team/mpg.xlsx")
read_using <- function(FUN, s3_path, ...) {
  tryCatch(
    {
      fext <- tools::file_ext(s3_path)
      tmp_location <- tempfile(fileext = fext)
      botor::s3_download_file(full_s3_path(s3_path), tmp_location)
      return(FUN(tmp_location))
    },
    error = function(c) {
      message("Could not read ", s3_path)
      stop(c)
    }
  )
}

#' Read a full file from S3, using the full path to the file including the
#' bucketname.
#'
#' This function will attempt to read the file directly, as a dataframe.
#' If this is not possible it will download the file to a temporary location
#' and load it.
#' At present the function supports direct reading of CSV, TSV, XLS, XLSX,
#' SAS7DBAT, SAV and DTA file types.
#' You can add options to the read function that are compatible with
#' readxl::read_excel() and read.csv(). See their help files for more info.
#'
#' @param path a string -  the full path to the file including the bucketname
#'
#' @return a dataframe (.csv, .tsv), tibble (Excel, SAS, SPSS, Stata), or file location
#' @export
#'
#' @examples df <- s3_read_path_to_df("alpha-moj-analytics-scratch/folder/file.csv")
#' @examples df <- s3_read_path_to_df("alpha-moj-analytics-scratch/folder/file.tsv")
#' @examples df <- s3_read_path_to_df("alpha-moj-analytics-scratch/folder/file.xls")
#' @examples df <- s3_read_path_to_df("alpha-moj-analytics-scratch/folder/file.xls", sheet = 1)
#' @examples filelocation <- s3_read_path_to_df("alpha-moj-analytics-scratch/folder/file.png")
s3_path_to_full_df <- function(s3_path, ...) {
  handle_default <- function(tmp_location) {
    message("labs3tools cannot parse this file automatically")
    message("If you want to specify your own reading function see labs3tools::read_using()")
    message("or use the file path provided by this function.")
    message(stringr::str_glue("Your file is available at: {tmp_location}"))
    tmp_location
  }

  fext <- tolower(tools::file_ext(s3_path))
  if (fext %in% c("csv", "tsv")) {
    f <- read.csv
  } else if (fext %in% c("xls", "xlsx")) {
    f <- readxl::read_excel
  } else if (fext == "sas7bdat") {
    f <- haven::read_sas
  } else if (fext == "sav") {
    f <- haven::read_spss
  } else if (fext == "dta") {
    f <- haven::read_stata
  } else {
    f <- handle_default
  }

  tryCatch(
    read_using(f, s3_path, ...),
    error = function(c) {
      stop(c)
    }
  )
}


#' Preview the first 5 rows of a CSV file from S3, using the full path to the file including the bucketname
#'
#' @param path a string -  the full path to the file including the bucketname
#'
#' @return a tibble (dataframe)
#' @export
#'
#'
#' @examples df <- s3_read_path_to_df("alpha-moj-analytics-scratch/a/b/c/robins_temp.csv")
#'
s3_path_to_preview_df <- function(s3_path, ...) {
  p <- parse_path(s3_path)
  fext <- tolower(tools::file_ext(p$key))

  if (!(fext %in% c("csv", "tsv"))) {
    message(stringr::str_glue("Preview not supported for {fext} files"))
    NULL
  } else {
    tryCatch(
      {
        client <- botor::botor()$client("s3")
        obj <- client$get_object(Bucket = p$bucket, Key = p$key,
                                 Range = "bytes=0-12000")
        obj$Body$read()$decode() %>%
          textConnection() %>%
          read.csv() %>%
          head(n = 5)
      },
      error = function(c) {
        message("Could not read ", s3_path)
        stop(c)
      }
    )
  }
}


#' Download a file from s3 to somewhere in your home directory
#'
#' @param s3_path character - the full path to the file in s3 e.g. alpha-everyone/iris.csv
#' @param local_path - character - the location you want to store the file locally e..g
#' @param overwrite - boolean - if file exists locally, overwrite?
#'
#' @return NULL
#' @export
#'
#' @examples s3tools:::download_file_from_s3("alpha-everyone/iris.csv", "iris.csv", overwrite =TRUE)
download_file_from_s3 <- function(s3_path, local_path, overwrite=FALSE) {
  if (!(file.exists(local_path)) || overwrite) {
    tryCatch(
      botor::s3_download_file(full_s3_path(s3_path), local_path, force = overwrite),
      error = function(c) {
        message("Could not read ", s3_path)
        stop(c)
      }
    )
  } else {
    stop("The file already exists locally and you didn't specify overwrite=TRUE")
  }
}
