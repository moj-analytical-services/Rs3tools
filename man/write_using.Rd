% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/write.R
\name{write_using}
\alias{write_using}
\title{Write an object to S3 using a function}
\usage{
write_using(x, f, s3_path, overwrite = FALSE, multipart = TRUE, ...)
}
\arguments{
\item{x}{A local object, such as a dataframe}

\item{f}{A function of the form f(object, path, ...) where object is the type of x and path is a filename}

\item{s3_path}{A character string containing the full path to where the file should be stored in S3, including any directory names and the bucket name.}

\item{overwrite}{A logical indicating whether to overwrite the file if it already exists.}

\item{multipart}{A logical indicating whether to use multipart uploads. See \url{http://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html}. If the file specified by \code{local_file_path} is less than 100 MB, this is ignored.}
}
\value{
Returns nothing
}
\description{
Write an object to S3 using a function
}
\examples{
write_using(my_dataframe, readr::write_csv, "alpha-everyone/delete/my_csv.csv")
write_using(my_dataframe, feather::write_feather, "alpha-everyone/delete/my_feather.feather")
}
