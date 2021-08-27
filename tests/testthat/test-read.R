BUCKET = "alpha-labs3tools"

svc <- paws::s3(config = list(region = "eu-west-1"))
for (ext in c("feather", "csv", "xlsx", "sav", "dta", "sas7bdat")) {
  filename <- glue::glue("flights.{ext}")
  fileloc <- system.file("testdata", filename, package = "labs3tools")
  svc$put_object(Body = fileloc, Bucket = BUCKET, Key = filename)
}

test_that("read_using works", {
  expect_equal(
    read_using(feather::read_feather, glue::glue('{BUCKET}/flights.feather')),
    nycflights13::flights
    )
  expect_equal(
    read_using(readr::read_csv, glue::glue('{BUCKET}/flights.csv'),
               locale = readr::locale(tz = "America/New_York"),
               show_col_types = FALSE),
    nycflights13::flights
  )

})
