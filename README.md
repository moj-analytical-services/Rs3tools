# Rs3tools

Helper tools to access Amazon S3 on the Analytical Platform, compatible with 
[s3tools](https://github.com/moj-analytical-services/s3tools). 

This is based on 
the [paws library](https://paws-r.github.io/) which has the
advantage that it's R-native and doesn't depend on reticulated Python libraries.

## Warning
Please note that this is not officially supported by the AP team and is 
intended to be community supported.

## What does this do?
This library is mostly compatible with `s3tools`, which is being retired as we
migrate to the new version of the Analytical Platform, so you can replace 
`s3tools` with `Rs3tools` in your code and you should be good to go. For
documentation 
[see the s3tools homepage](https://github.com/moj-analytical-services/s3tools).

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

AWS authentication credentials will refresh automatically but if there is a problem
then you can refresh them with
```R
Rs3tools::refresh_credentials()
```
NB `s3tools::accessible_buckets` is not implemented.

### Installation
```
renv::install("moj-analytical-services/Rs3tools")
```
otherwise
```
remotes::install_github("moj-analytical-services/Rs3tools")
```

