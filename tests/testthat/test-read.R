library(magrittr)

BUCKET = "alpha-everyone"
svc <- s3_svc()

flights <- nycflights13::flights %>%
  dplyr::mutate(time_hour = lubridate::with_tz(time_hour, tzone="UTC"))

list(
  list(f = feather::write_feather, ext = "feather"),
  list(f = readr::write_csv, ext = "csv"),
  list(f = haven::write_sav, ext = "sav"),
  list(f = haven::write_dta, ext = "dta"),
  list(f = haven::write_sas, ext = "sas7bdat"),
  list(f = openxlsx::write.xlsx, ext = "xlsx")
) %>%
  purrr::walk(
    function(x) {
      write_using(
        flights,
        x$f,
        glue::glue('{BUCKET}/Rs3tools/flights.{x$ext}'),
        overwrite = TRUE
      )
    }
  )

test_that("write_read_using works", {
  expect_equal(
    read_using(
      feather::read_feather,
      glue::glue('{BUCKET}/Rs3tools/flights.feather')
    ),
    flights
  )

  expect_equal(
    read_using(readr::read_csv, glue::glue('{BUCKET}/Rs3tools/flights.csv'),
               # locale = readr::locale(tz = "America/New_York"),
               show_col_types = FALSE),
    flights
  )

  expect_equal(
    read_using(
      readxl::read_excel,
      glue::glue('{BUCKET}/Rs3tools/flights.xlsx')
    ),
    flights
  )
})

test_that("we can list the files written", {
  expect_equal(
    list_files_in_bucket(BUCKET, prefix = "Rs3tools/flights") %>%
      dplyr::pull(filename) %>%
      sort(),
    c("flights.csv", "flights.dta", "flights.feather", "flights.sas7bdat", "flights.sav", "flights.xlsx"))
})
