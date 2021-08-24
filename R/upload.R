# The following functions are taken from
# https://github.com/paws-r/paws/blob/main/examples/s3_multipart_upload.R
# under the following license.

# Copyright 2018 David Kretch
# Copyright 2018 Adam Banker
# Copyright 2015 Amazon.com, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


#' Upload a file to S3 using multipart upload
#'
#' @param client A Paws S3 client object, e.g. from `paws::s3()`.
#' @param file The path to the file to be uploaded.
#' @param bucket The name of the S3 bucket to be uploaded to, e.g. `my-bucket`.
#' @param key The name to assign to the file in the S3 bucket, e.g. `path/to/file`.
upload <- function(client, file, bucket, key) {
  multipart <- client$create_multipart_upload(
    Bucket = bucket,
    Key = key
  )
  resp <- NULL
  on.exit({
    if (is.null(resp) || inherits(resp, "try-error")) {
      client$abort_multipart_upload(
        Bucket = bucket,
        Key = key,
        UploadId = multipart$UploadId
      )
    }
  })
  resp <- try({
    parts <- upload_multipart_parts(client, file, bucket, key, multipart$UploadId)
    client$complete_multipart_upload(
      Bucket = bucket,
      Key = key,
      MultipartUpload = list(Parts = parts),
      UploadId = multipart$UploadId
    )
  })
  return(resp)
}

upload_multipart_parts <- function(client, file, bucket, key, upload_id) {
  file_size <- file.size(file)
  megabyte <- 2^20
  part_size <- 5 * megabyte
  num_parts <- ceiling(file_size / part_size)

  con <- base::file(file, open = "rb")
  on.exit({
    close(con)
  })
  pb <- utils::txtProgressBar(min = 0, max = num_parts)
  parts <- list()
  for (i in 1:num_parts) {
    part <- readBin(con, what = "raw", n = part_size)
    part_resp <- client$upload_part(
      Body = part,
      Bucket = bucket,
      Key = key,
      PartNumber = i,
      UploadId = upload_id
    )
    parts <- c(parts, list(list(ETag = part_resp$ETag, PartNumber = i)))
    utils::setTxtProgressBar(pb, i)
  }
  close(pb)
  return(parts)
}
