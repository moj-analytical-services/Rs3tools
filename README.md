# Rs3tools

Helper tools to access Amazon S3 on the Analytical Platform, mostly compatible with 
[s3tools](https://github.com/moj-analytical-services/s3tools). 

This is based on 
the [paws library](https://paws-r.github.io/) which has the
advantage that it's R-native and doesn't depend on reticulated Python libraries.

## Warning
Please note that this is not officially supported by the AP team and is 
intended to be community supported.

## Installation
```
renv::install("moj-analytical-services/Rs3tools")
```
otherwise
```
remotes::install_github("moj-analytical-services/Rs3tools")
```

## What does this do?
This library is mostly compatible with `s3tools`, which is being retired as we
migrate to the new version of the Analytical Platform, so you can replace 
`s3tools` with `Rs3tools` in your code and you should be good to go. For
documentation 
[see the s3tools homepage](https://github.com/moj-analytical-services/s3tools), which for convenience is replicated below.

Additionally there is a function `write_using`, e.g.
```R
Rs3tools::write_using(
  my_dataframe, 
  feather::write_feather, 
  "alpha-my-bucket/my_feather.feather",
  overwrite=TRUE,
  multipart=TRUE
)
```

### Writing Excel files

You can also use `write_using` to write .xlsx files, e.g.
```R
Rs3tools::write_using(
  my_dataframe, 
  openxlsx::write.xlsx, 
  "alpha-my-bucket/my_excel.xlsx",
  sheetName = "mysheetName",
  overwrite=TRUE
)
```
However, note that you can't append multiple sheets in the same excel file/workbook.
For that, you can create a workbook in your local session space, add multiple sheets
and data to them, and save the workbook in local session space. Only then write the 
workbook to s3 using `write_file_to_s3`, e.g.
```R
library(openxlsx)
wb <- createWorkbook()
addWorksheet(wb, sheet = "mysheet1") 
addWorksheet(wb, sheet = "mysheet2")
writeData(wb, "mysheet1", df1, startRow = 1, startCol = 1)
writeData(wb, "mysheet2", df2, startRow = 1, startCol = 1)
saveWorkbook(wb, file = "my_excelwb.xlsx", overwrite = TRUE)

#write file to s3 using `write_file_to_s3`function
Rs3tools::write_file_to_s3("my_excelwb.xlsx", "alpha-my-bucket/my_excelwb.xlsx", overwrite=TRUE)
```

### Athentication

AWS authentication credentials will refresh automatically but if there is a problem
then you can refresh them with
```R
Rs3tools::refresh_credentials()
```

### s3tools incompatibility

`s3tools::accessible_buckets` is not implemented.

## s3tools guidance

What files do I have access to?
-------------------------------

``` r
## List all the files in the alpha-everyone bucket
s3tools::list_files_in_buckets('alpha-everyone')

## You can list files in more than one bucket:
s3tools::list_files_in_buckets(c('alpha-everyone', 'alpha-dash'))

## You can filter by prefix, to return only files in a folder
s3tools::list_files_in_buckets('alpha-everyone', prefix='s3tools_tests')

## The 'prefix' argument is used to filter results to any path that begins with the prefix. 
s3tools::list_files_in_buckets('alpha-everyone', prefix='s3tools_tests', path_only = TRUE)

## For more complex filters, you can always filter down the dataframe using standard R code:
library(dplyr)

## All files containing the string 'iris'
s3tools::list_files_in_buckets('alpha-everyone') %>% 
  dplyr::filter(grepl("iris",path)) # Use a regular expression

## All excel files containing 'iris;
s3tools::list_files_in_buckets('alpha-everyone') %>% 
  dplyr::filter(grepl("iris*.xls",path)) 
```

Reading files
-------------

Once you know the full path that you'd like to access, you can read the file as follows.

### `csv` files

For `csv` files, this will use the default `read.csv` csv reader:

``` r
df <-s3tools::s3_path_to_full_df("alpha-everyone/s3tools_tests/folder1/iris_folder1_1.csv")
print(head(df))
```

For large csv files, if you want to preview the first few rows without downloading the whole file, you can do this:

``` r
df <- s3tools::s3_path_to_preview_df("alpha-moj-analytics-scratch/my_folder/10mb_random.csv")
print(df)
```

### Other file types

For xls, xlsx, sav (spss), dta (stata), and sas7bdat (sas) file types, s3tools will attempt to read these files if the relevant reader package is installed:

``` r
df <-s3tools::s3_path_to_full_df("alpha-everyone/s3tools_tests/iris_base.xlsx")  # Uses readxl if installed, otherwise errors

df <-s3tools::s3_path_to_full_df("alpha-everyone/s3tools_tests/iris_base.sav")  # Uses haven if installed, otherwise errors
df <-s3tools::s3_path_to_full_df("alpha-everyone/s3tools_tests/iris_base.dta")  # Uses haven if installed, otherwise errors
df <-s3tools::s3_path_to_full_df("alpha-everyone/s3tools_tests/iris_base.sas7bdat")  # Uses haven if installed, otherwise errors
```

If you have a different file type, or you're having a problem with the automatic readers, you can specify a file read function:

``` r
s3tools::read_using(FUN=readr::read_csv, path = "alpha-everyone/s3tools_tests/iris_base.csv")
```


Downloading files
-----------------

``` r
df <- s3tools::download_file_from_s3("alpha-everyone/s3tools_tests/iris_base.csv", "my_downloaded_file.csv")

# By default, if the file already exists you will receive an error.  To override:
df <- s3tools::download_file_from_s3("alpha-everyone/s3tools_tests/iris_base.csv", "my_downloaded_file.csv", overwrite =TRUE)
```

Writing data to s3
------------------

### Writing files to s3

``` r
s3tools::write_file_to_s3("my_downloaded_file.csv", "alpha-everyone/delete/my_downloaded_file.csv")

# By default, if the file already exists you will receive an error.  To override:
s3tools::write_file_to_s3("my_downloaded_file.csv", "alpha-everyone/delete/my_downloaded_file.csv", overwrite =TRUE)
```

### Writing a dataframe to s3 in `csv` format

``` r
s3tools::write_df_to_csv_in_s3(iris, "alpha-everyone/delete/iris.csv")

# By default, if the file already exists you will receive an error.  To override:
s3tools::write_df_to_csv_in_s3(iris, "alpha-everyone/delete/iris.csv", overwrite =TRUE)
```
