% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/upload.R
\name{upload}
\alias{upload}
\title{Upload a file to S3 using multipart upload}
\usage{
upload(client, file, bucket, key)
}
\arguments{
\item{client}{A Paws S3 client object, e.g. from \code{s3_svc()}.}

\item{file}{The path to the file to be uploaded.}

\item{bucket}{The name of the S3 bucket to be uploaded to, e.g. \code{my-bucket}.}

\item{key}{The name to assign to the file in the S3 bucket, e.g. \code{path/to/file}.}
}
\description{
Upload a file to S3 using multipart upload
}
