library(magrittr)

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
      x$f(nycflights13::flights, glue::glue("inst/testdata/flights.{x$ext}"))
    }
  )
