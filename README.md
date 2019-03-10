
<!-- README.md is generated from README.Rmd. Please edit that file -->

# volve-reservoir-model-evolution

``` r
library(dplyr)
library(ggplot2)

# read the Eclipse PRT output report
proj_root <- rprojroot::find_rstudio_root_file()
# had to zip the PRT file because it's 225 MB and too big for Github
volve_2016_zip <- file.path(proj_root, "inst/rawdata", "VOLVE_2016.zip")
temp <- tempdir()

volve_2016_txt <- readLines(unzip(volve_2016_zip, exdir = temp))
```

``` r
# get a list of rows from " STEP" 

# find the rows where we find the word " STEP"
step_rows <- grep("^ STEP", volve_2016_txt)

# add rows ahead to where the keyword was found
step_info_range <- lapply(seq_along(step_rows), function(x) 
    c(step_rows[x], step_rows[x]+1:2))               # add two extra row indices

step_info_range[[1]]   # sample for report page 1 only
#> [1] 1548178 1548179 1548180
```

These extra row indices are lines of text where the report keep more
information of the evolution of the simulation. Here is a couple of
screenhots.

Step at day
`1`:

<img src="img/step_0001.png" title="Step at 1 day" alt="Step at 1 day" width="600px" style="display: block; margin: auto;" />

Step at day
`3,197`:

<img src="img/step_3197.png" title="Step at 3197 days" alt="Step at 3197 days" width="600px" style="display: block; margin: auto;" />

Now, knowing the row indices for the text we need from the `PRT` file,
we can proceed to extracting those lines of text and putting them in a
list, one page, or one step, per list element. We do this to later
iterate through all the steps and extract the data we want.

``` r
# get the text from all pages and put them in a list
steps_info_txt_pages <- lapply(seq_along(step_info_range), function(x) 
    volve_2016_txt[step_info_range[[x]]])
```

This is an example of the first page for step \#1.

``` r
steps_info_txt_pages[1]
#> [[1]]
#> [1] " STEP    1 TIME=      1.00  DAYS (    +1.0  DAYS INIT  5 ITS) (1-JAN-2008)       "
#> [2] "  PAV=   329.6  BARSA  WCT= 0.00 GOR= 0.00000   SM3/SM3 WGR= 0.00000   SM3/SM3   "
#> [3] ""
```

## Extracting step data from the text file

### Extract the days from the STEP block

Although we could extract all the data we require from the text file in
one go, it is better to see one or two examples of seeing **regular
expressions** or **regex** at work. Regular expressions are practically
available to all programming languages: C++, Java, JavaScript, Python,
Perl, etc.

In this first example, we will extract the number of days at the current
simulation step. If this is the first step
page:

``` 
 STEP    1 TIME=      1.00  DAYS (    +1.0  DAYS INIT  5 ITS) (1-JAN-2008)       
  PAV=   329.6  BARSA  WCT= 0.00 GOR= 0.00000   SM3/SM3 WGR= 0.00000   SM3/SM3
```

to extract the days we have to provide a regex pattern that detects a
real number like `1.00`, which is `".*?(\\d+.\\d.)+.*"`.

**Explanation**

  - `.*?` will match any characters. lazy matching.
  - `(\\d+.\\d.)` capturing group.
  - `\\d+` matches any number of digits
  - `\\d.` matches a digit and then any character

<!-- end list -->

``` r
# iterate through the list of STEP pages
days_dfs <- lapply(seq_along(steps_info_txt_pages), function(x) {
    page <- steps_info_txt_pages[[x]]   # put all pages text in a list
    days_row_txt <- page[1]                                # get 1st row of page
    days_value <- sub(".*?(\\d+.\\d.)+.*", "\\1", days_row_txt,
                      perl = TRUE) # extract the days
    
    # dataframe; days as double; no factors.
    data.frame(days = as.double(days_value), stringsAsFactors = FALSE) 
})

days_df <- do.call("rbind", days_dfs)
```

### Extract the days

A sample of the first ten and last ten rows for the dataframe just
extracted:

``` r
rbind(head(days_df, 10), tail(days_df, 10))   # show the first 10 and last 10 rows
#>         days
#> 1       1.00
#> 2       1.63
#> 3       2.32
#> 4       3.50
#> 5       5.45
#> 6       8.22
#> 7      11.00
#> 8      14.61
#> 9      17.80
#> 10     21.00
#> 1601 1601.00
#> 1602 1602.00
#> 1603 1603.00
#> 1604 1604.00
#> 1605 1605.00
#> 1606 1606.00
#> 1607 1607.00
#> 1608 1608.00
#> 1609 1609.00
#> 1610 1610.00
```

### Extract the simulator running date

This regular expresion pattern extracts the date from the current text
line.

**Explanation**  
\* `.*?(\\d{1,2}-[A-Z]{3}-\\d{4}).` entire regex pattern  
\* `(\\d{1,2}-[A-Z]{3}-\\d{4})` parenthesis indicate a group to extract
the date  
\* `.*?` match any character  
\* `\\d{1,2}` match one or two digits (day)  
\* `-[A-Z]{3}` match a dash followed by three letters (month)  
\* `-\\d{4}` match four digits (year)

``` r
# iterate through the list of pages: dates
date_dfs <- lapply(seq_along(steps_info_txt_pages), function(x) {
    page <- steps_info_txt_pages[[x]]  # put all pages text in a list
    date_row_txt <- grep(" STEP", page)  # get row index at word STEP
    date_value <- sub(".*?(\\d{1,2}-[A-Z]{3}-\\d{4}).", "\\1", page[date_row_txt])
    
    # dataframe; no factors
    data.frame(date = date_value, stringsAsFactors = FALSE) 
})

date_df <- do.call("rbind", date_dfs)

# size of the dataframe: rows by columns
dim(date_df)
#> [1] 1610    1

rbind(head(date_df, 10), tail(date_df, 10))   # show the first 10 and last 10 rows
#>                   date
#> 1    1-JAN-2008       
#> 2    1-JAN-2008       
#> 3    2-JAN-2008       
#> 4    3-JAN-2008       
#> 5    5-JAN-2008       
#> 6    8-JAN-2008       
#> 7    11-JAN-2008      
#> 8    14-JAN-2008      
#> 9    17-JAN-2008      
#> 10   21-JAN-2008      
#> 1601 17-SEP-2016      
#> 1602 20-SEP-2016      
#> 1603 20-SEP-2016      
#> 1604 20-SEP-2016      
#> 1605 20-SEP-2016      
#> 1606 21-SEP-2016      
#> 1607 23-SEP-2016      
#> 1608 25-SEP-2016      
#> 1609 28-SEP-2016      
#> 1610 1-OCT-2016
```

## Extract all the values from the **STEP** block

After show this pair of examples, we continue with the extraction of the
rest of the values. If you take a look at the PRT file you will
recognize these are variables to be extracted:

  - `STEP` simulation step number
  - `TIME` number of days elpased at the simulation step
  - `date` current date at the simulation run
  - `PAV` average pressure
  - `WCT` watercut
  - `GOR` gas oil ratio
  - `WGR` water gas ratio

The mission here is to extract all the variables that are made available
by the simulator in the **STEP** block. As shown above, they are seven
variables.

The following is an R script that extract all the variables from all the
occurrences of the STEP block in the PRT file. The steps are not
normally sequential, they may skip a day, or be generated after “few
hours” in the simulation, and they do not necessarily match the date in
the `field totals` dataframe.

``` r
# script that extracts production variables from the simulator output
library(lubridate)

# get the row indices where we find the keyword " STEP"
step_rows <- grep("^ STEP", volve_2016_txt)

# get rows ahead range. by block of text or per page
# in the case of the STEP block we are only interested in the next two rows
step_info_range <- lapply(seq_along(step_rows), function(x) 
    c(step_rows[x], step_rows[x]+1:2))

# get the text from all STEP pages and store each in a list element
steps_info_txt_pages <- lapply(seq_along(step_info_range), function(x) 
    volve_2016_txt[step_info_range[[x]]])

# iterate through the list of pages for the STEP blocks in the report
step_info_dfs <- lapply(seq_along(steps_info_txt_pages), function(x) {
    page <- steps_info_txt_pages[[x]]             # load a STEP block/page
    
    # this is line 1
    row_txt <- grep(" STEP", page)  # line 1 starts with STEP
    # pattern extraction for 1st line of text: STEP, TIME, date
    line_1_pattern <- ".*?(\\d+)+.*?(\\d+.\\d+)+.*?(\\d+)+.*?(\\d{1,2}-[A-Z]{3}-\\d{4})+.*"
    step_value <- sub(line_1_pattern, "\\1", page[row_txt], perl = TRUE) # extract step
    days_value <- sub(line_1_pattern, "\\2", page[row_txt], perl = TRUE) # extract days
    date_value <- sub(line_1_pattern, "\\4", page[row_txt], perl = TRUE) # extract date
    date_value <- sub("JLY", "JUL", date_value)              # change JLY by JUL
    
    
    # this is line 2
    row_txt <- grep(" PAV", page) # line 2 starts with PAV=
    # pattern extraction for 2nd line of text: PAV, WCT, GOR, WGR
    line_2_pattern <- ".*?(\\d+.\\d+)+.*?(\\d+.\\d+)+.*?(\\d+.\\d+)+.*?(\\d+.\\d+).*"
    pav_value <- sub(line_2_pattern, "\\1", page[row_txt], perl = TRUE) # Get avg pres
    wct_value <- sub(line_2_pattern, "\\2", page[row_txt], perl = TRUE) # get WCT
    gor_value <- sub(line_2_pattern, "\\3", page[row_txt], perl = TRUE) # get GOR
    wgr_value <- sub(line_2_pattern, "\\4", page[row_txt], perl = TRUE) # get WGR
    
    # dataframe; 
    data.frame(step = as.integer(step_value), 
               date = dmy(date_value),
               # date = date_value, 
               time_days = as.double(days_value), 
               pav_bar   = as.double(pav_value),
               wct_pct   = as.double(wct_value),
               gor_m3m3  = as.double(gor_value), 
               wgr_m3m3  = as.double(wgr_value),
               stringsAsFactors = FALSE) 
})

step_info <- do.call("rbind", step_info_dfs) # put together all dataframes in list

# show a summary of the dataframe
glimpse(step_info)
#> Observations: 1,610
#> Variables: 7
#> $ step      <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1...
#> $ date      <date> 2008-01-01, 2008-01-01, 2008-01-02, 2008-01-03, 200...
#> $ time_days <dbl> 1.00, 1.63, 2.32, 3.50, 5.45, 8.22, 11.00, 14.61, 17...
#> $ pav_bar   <dbl> 329.6, 329.6, 329.6, 329.6, 329.6, 329.6, 329.6, 329...
#> $ wct_pct   <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0...
#> $ gor_m3m3  <dbl> 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00...
#> $ wgr_m3m3  <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0...
```

``` r
# show as a tibble
(step_info <- as_tibble(step_info))
#> # A tibble: 1,610 x 7
#>     step date       time_days pav_bar wct_pct gor_m3m3 wgr_m3m3
#>    <int> <date>         <dbl>   <dbl>   <dbl>    <dbl>    <dbl>
#>  1     1 2008-01-01      1       330.       0        0        0
#>  2     2 2008-01-01      1.63    330.       0        0        0
#>  3     3 2008-01-02      2.32    330.       0        0        0
#>  4     4 2008-01-03      3.5     330.       0        0        0
#>  5     5 2008-01-05      5.45    330.       0        0        0
#>  6     6 2008-01-08      8.22    330.       0        0        0
#>  7     7 2008-01-11     11       330.       0        0        0
#>  8     8 2008-01-14     14.6     330.       0        0        0
#>  9     9 2008-01-17     17.8     330.       0        0        0
#> 10    10 2008-01-21     21       330.       0        0        0
#> # ... with 1,600 more rows
```

The name of the variables in the dataframe:

``` r
names(step_info)
#> [1] "step"      "date"      "time_days" "pav_bar"   "wct_pct"   "gor_m3m3" 
#> [7] "wgr_m3m3"
```

You can see that the step do not carry any data regarding cumulative
production.

### Sample of the step dataframe

Let’s test the first day and last day of the simulation:

``` r
tail(step_info$date,1) - head(step_info$date,1)
#> Time difference of 3196 days
```

### Save to data files

``` r
data_folder <- file.path(proj_root, "data")

save(step_info, file = file.path(data_folder, "data_from_step.Rdata"))
write.csv(step_info, file = file.path(data_folder, 
                                         "data_from_step.CSV"), 
          row.names = FALSE)
```

### Plot pressure vs time

Now, we take a look at the pressure over the life of the field, from the
simulator perspective.

``` r
ggplot(step_info, aes(x =date, y = pav_bar)) +
    geom_line(color = "red") +
    labs(title = "Pressure over time", subtitle = "Simulator output",
         y = "Average Pressure (PAV), bar")
```

<img src="README_files/figure-gfm/unnamed-chunk-14-1.png" style="display: block; margin: auto;" />

### Plot watercut vs time

``` r
# plot from PRT simulator output (STEP block)
ggplot(step_info, aes(x =date, y = wct_pct)) +
    geom_line(color = "blue") +
    labs(title = "Field watercut over time", subtitle = "Simulator output",
         y = "Watercut, percent")
```

<img src="README_files/figure-gfm/unnamed-chunk-15-1.png" style="display: block; margin: auto;" />

## Merge cumulative oil with simulator steps

Next step is combining the data from the steps dataframe with the
production cumulatives. This is not an straight operation since both
dataframe have different date references.

1.  First, we will extract the production cumulatives from the PRT file.
    This is something we already did in the previous article. We will
    load that script.

### Field cumulatives

``` r
r_folder <- file.path(proj_root, "R")
r_script <- file.path(r_folder, "extract_data_from_prt.R")
source(r_script)

field_totals <- extract_field_totals(prt_file_content = volve_2016_txt)
field_totals
#> # A tibble: 340 x 8
#>    date        days     ocip     ooip oil_otw wat_otw  gas_otw   pav
#>    <date>     <int>    <dbl>    <dbl>   <dbl>   <dbl>    <dbl> <dbl>
#>  1 2007-12-31     0 21967455 21967455       0       0        0  330.
#>  2 2008-01-11    11 21967456 21967455       0       0        0  330.
#>  3 2008-01-21    21 21967455 21967455       0       0        0  330.
#>  4 2008-01-31    31 21967454 21967455       0       0        0  330.
#>  5 2008-02-10    41 21967454 21967455       0       0        0  330.
#>  6 2008-02-20    51 21948189 21967455   19265       0  3055593  325.
#>  7 2008-02-26    57 21936614 21967455   30840       0  4884638  323.
#>  8 2008-03-01    61 21925419 21967455   42035       0  6650055  320.
#>  9 2008-03-11    71 21897024 21967455   70430       0 11113293  314.
#> 10 2008-03-21    81 21867231 21967455  100223       1 15777548  308.
#> # ... with 330 more rows
```

### Save to data files

``` r
data_folder <- file.path(proj_root, "data")

save(field_totals, file = file.path(data_folder, "field_totals_balance.Rdata"))
write.csv(field_totals, file = file.path(data_folder, 
                                         "field_totals_balance.CSV"), 
          row.names = FALSE)
```

``` r
# plot from PRT simulator output (BALANCE AT block)
ggplot(field_totals, aes(x =date, y = wat_otw)) +
    geom_line(color = "blue") +
    labs(title = "Field Water Outflow Through Wells", 
         subtitle = "Simulator output, BALANCE block",
         y = "Water volume, sm3")
```

<img src="README_files/figure-gfm/unnamed-chunk-18-1.png" style="display: block; margin: auto;" />

Now, we know that the STEP dataframe has more rows than the BALANCE-AT
dataframe. What we want is to correlate the step with the oil
cumulatives.

``` r
dim(step_info)
#> [1] 1610    7
```

``` r
dim(field_totals)
#> [1] 340   8
```

We merge both tables, steps and field cumulatives.

``` r
# join both tables by the common variable "date"
step_totals <- 
left_join(step_info, field_totals, by = "date") %>% 
    na.omit() %>% 
    select(date, time_days, days, everything()) %>% 
    as_tibble() %>% 
    print
#> # A tibble: 524 x 14
#>    date       time_days  days  step pav_bar wct_pct gor_m3m3 wgr_m3m3
#>    <date>         <dbl> <int> <int>   <dbl>   <dbl>    <dbl>    <dbl>
#>  1 2008-01-11      11      11     7    330.       0       0         0
#>  2 2008-01-21      21      21    10    330.       0       0         0
#>  3 2008-01-31      31      31    13    330.       0       0         0
#>  4 2008-02-10      41      41    15    330.       0       0         0
#>  5 2008-02-20      51      51    17    325.       0     158.        0
#>  6 2008-02-26      57      57    18    323.       0     158.        0
#>  7 2008-03-01      61      61    19    320.       0     158.        0
#>  8 2008-03-11      71      71    21    314.       0     157.        0
#>  9 2008-03-21      81      81    23    308.       0     156.        0
#> 10 2008-03-21      81.5    81    24    308        0     156.        0
#> # ... with 514 more rows, and 6 more variables: ocip <dbl>, ooip <dbl>,
#> #   oil_otw <dbl>, wat_otw <dbl>, gas_otw <dbl>, pav <dbl>
```

### Plot outflow through wells from simulator

``` r
ggplot(step_totals, aes(x = date, y = oil_otw)) +
    geom_line(color = "dark green", size = 1.1) +
    # geom_line(aes(x= date, y = ocip))
    # geom_col(aes(x= date, y = ocip)) + 
    ggtitle("Cumulative Oil, sm3", subtitle = "Simulator")
```

<img src="README_files/figure-gfm/unnamed-chunk-22-1.png" style="display: block; margin: auto;" />

``` r
ggplot(step_totals, aes(x = date, y = gas_otw)) +
    geom_line(color = "orange", size = 1.1) +
    labs(title = "Cumulative Gas", subtitle = "Simulator",
         y = "Cumulative Gas, sm3")
```

<img src="README_files/figure-gfm/unnamed-chunk-23-1.png" style="display: block; margin: auto;" />

``` r
ggplot(step_totals, aes(x = date, y = wat_otw)) +
    geom_line(color = "blue", size = 1.1) +
    labs(title = "Cumulative Water", subtitle = "Simulator",
         y = "Cumulative Water, sm3")
```

<img src="README_files/figure-gfm/unnamed-chunk-24-1.png" style="display: block; margin: auto;" />

### Calculate cumulatives for oil, gas and water

``` r
# step field totals
sim_cumulatives <- 
step_totals %>% 
    select(date, oil_otw, gas_otw, wat_otw) %>% 
    mutate(oil_this_period = oil_otw - lag(oil_otw, default = 0)) %>%
    mutate(gas_this_period = gas_otw - lag(gas_otw, default = 0)) %>%
    mutate(wat_this_period = wat_otw - lag(wat_otw, default = 0)) %>% 
    mutate(year = year(date), month = month(date)) %>%
    group_by(year, month) %>%
    summarize(vol_oil = sum(oil_this_period), 
              vol_gas = sum(gas_this_period), 
              vol_wat = sum(wat_this_period)) %>%
    ungroup() %>%
    mutate(date = ymd(paste(year, month, "01", sep = "-"))) %>%
    # mutate(source = "simulator") %>%
    mutate(cum_oil = cumsum(vol_oil), 
           cum_gas = cumsum(vol_gas), 
           cum_wat = cumsum(vol_wat)) %>%
    select(date, year, month, everything()) %>%
    print()
#> # A tibble: 106 x 9
#>    date        year month vol_oil  vol_gas vol_wat cum_oil  cum_gas cum_wat
#>    <date>     <dbl> <dbl>   <dbl>    <dbl>   <dbl>   <dbl>    <dbl>   <dbl>
#>  1 2008-01-01  2008     1       0        0       0       0   0.           0
#>  2 2008-02-01  2008     2   30840  4884638       0   30840   4.88e6       0
#>  3 2008-03-01  2008     3   90029 14117066       1  120869   1.90e7       1
#>  4 2008-04-01  2008     4   73833 11469357   22292  194702   3.05e7   22293
#>  5 2008-05-01  2008     5  124196 19115952  212550  318898   4.96e7  234843
#>  6 2008-06-01  2008     6  137247 20967327  192961  456145   7.06e7  427804
#>  7 2008-07-01  2008     7  155664 24005385  212739  611809   9.46e7  640543
#>  8 2008-08-01  2008     8  170057 26420155  227653  781866   1.21e8  868196
#>  9 2008-09-01  2008     9  163015 25205884  137169  944881   1.46e8 1005365
#> 10 2008-10-01  2008    10  221230 33570835  317736 1166111   1.80e8 1323101
#> # ... with 96 more rows
```

``` r
# create a dataframe with complete dates from 2008 until Oct-2016
# this will fill any holes in the dates of any of the two dataframes
dates_complete <- as_tibble(data.frame(date= seq.Date(as.Date("2008-01-01"), 
                                          as.Date("2016-10-01"), by = "month"),
                 cum_oil = 0, cum_gas = 0, cum_wat = 0))
dates_complete
#> # A tibble: 106 x 4
#>    date       cum_oil cum_gas cum_wat
#>    <date>       <dbl>   <dbl>   <dbl>
#>  1 2008-01-01       0       0       0
#>  2 2008-02-01       0       0       0
#>  3 2008-03-01       0       0       0
#>  4 2008-04-01       0       0       0
#>  5 2008-05-01       0       0       0
#>  6 2008-06-01       0       0       0
#>  7 2008-07-01       0       0       0
#>  8 2008-08-01       0       0       0
#>  9 2008-09-01       0       0       0
#> 10 2008-10-01       0       0       0
#> # ... with 96 more rows
```

There are 106 months start to end of production.

``` r
# simulator production
# merge incomplete dataframe and fill with complete dates
# there will be blank rows or NAs where previously was not data
sim_cumulatives_dt <-
left_join(dates_complete, sim_cumulatives, by = "date") %>% 
    # remove NAs from the cumulatives .y
    tidyr::replace_na(list(cum_oil.y = 0, vol_oil = 0,
                           cum_gas.y = 0, vol_gas = 0,
                           cum_wat.y = 0, vol_wat = 0)) %>%        # replace NAs with zeros
    # add up cumulatives .x and .y
    mutate(cum_oil = cum_oil.x + cum_oil.y, 
           cum_gas = cum_gas.x + cum_gas.y,
           cum_wat = cum_wat.x + cum_wat.y) %>%       # sum cumulatives
    select(date, cum_oil, cum_gas, cum_wat, vol_oil, vol_gas, vol_wat) %>%
    # replace 0s with previous cumulative. these were rows that didn't exist
    mutate(cum_oil = ifelse(cum_oil == 0, lag(cum_oil, default = 0), cum_oil)) %>%
    mutate(cum_gas = ifelse(cum_gas == 0, lag(cum_gas, default = 0), cum_gas)) %>%
    mutate(cum_wat = ifelse(cum_wat == 0, lag(cum_wat, default = 0), cum_wat)) %>%
    mutate(vol_oil = ifelse(vol_oil == 0, lag(vol_oil, default = 0), vol_oil)) %>%
    mutate(vol_gas = ifelse(vol_gas == 0, lag(vol_gas, default = 0), vol_gas)) %>%
    mutate(vol_oil = ifelse(vol_wat == 0, lag(vol_wat, default = 0), vol_wat)) %>%
    as_tibble() %>% 
    print
#> # A tibble: 106 x 7
#>    date       cum_oil   cum_gas cum_wat vol_oil  vol_gas vol_wat
#>    <date>       <dbl>     <dbl>   <dbl>   <dbl>    <dbl>   <dbl>
#>  1 2008-01-01       0         0       0       0        0       0
#>  2 2008-02-01   30840   4884638       0       0  4884638       0
#>  3 2008-03-01  120869  19001704       1       1 14117066       1
#>  4 2008-04-01  194702  30471061   22293   22292 11469357   22292
#>  5 2008-05-01  318898  49587013  234843  212550 19115952  212550
#>  6 2008-06-01  456145  70554340  427804  192961 20967327  192961
#>  7 2008-07-01  611809  94559725  640543  212739 24005385  212739
#>  8 2008-08-01  781866 120979880  868196  227653 26420155  227653
#>  9 2008-09-01  944881 146185764 1005365  137169 25205884  137169
#> 10 2008-10-01 1166111 179756599 1323101  317736 33570835  317736
#> # ... with 96 more rows
```

The negative volume of water and oil are corrections.

## Comparative with historical production

``` r
# load historical production from Excel file
library(xlsx)   # library to read Excel files in R

# read the Excel file
proj_root <- rprojroot::find_rstudio_root_file()   # get the project root folder
xl_file <- file.path(proj_root, "inst/rawdata", "Volve production data.xlsx")
# read only the monthly production
prod_hist <- as_tibble(read.xlsx(xl_file, sheetName = "Monthly Production Data"))
prod_hist
#> # A tibble: 529 x 10
#>    Wellbore.name NPDCode  Year Month On.Stream Oil   Gas   Water GI   
#>    <fct>           <dbl> <dbl> <dbl> <fct>     <fct> <fct> <fct> <fct>
#>  1 15/9-F-4         5693  2007     9 NULL      NULL  NULL  NULL  NULL 
#>  2 15/9-F-5         5769  2007     9 NULL      NULL  NULL  NULL  NULL 
#>  3 15/9-F-4         5693  2007    10 NULL      NULL  NULL  NULL  NULL 
#>  4 15/9-F-5         5769  2007    10 NULL      NULL  NULL  NULL  NULL 
#>  5 15/9-F-4         5693  2007    11 NULL      NULL  NULL  NULL  NULL 
#>  6 15/9-F-5         5769  2007    11 NULL      NULL  NULL  NULL  NULL 
#>  7 15/9-F-4         5693  2007    12 NULL      NULL  NULL  NULL  NULL 
#>  8 15/9-F-5         5769  2007    12 NULL      NULL  NULL  NULL  NULL 
#>  9 15/9-F-4         5693  2008     1 0         NULL  NULL  NULL  NULL 
#> 10 15/9-F-5         5769  2008     1 0         NULL  NULL  NULL  NULL 
#> # ... with 519 more rows, and 1 more variable: WI <fct>
```

### Cumulatives from production history

``` r
hist_cumulatives <- 
prod_hist %>% 
    mutate(Oil = as.double(as.character(Oil))) %>%
    mutate(Gas = as.double(as.character(Gas))) %>%
    mutate(Water = as.double(as.character(Water))) %>% 
    mutate(Year = as.integer(as.character(Year))) %>%
    mutate(Month = as.integer(as.character(Month))) %>%
    rename(year = Year, month = Month, oil = Oil, gas = Gas, wat = Water) %>% 
    na.omit() %>% 
    group_by(year, month) %>%
    summarise(vol_oil = sum(oil), vol_gas = sum(gas), vol_wat = sum(wat)) %>%
    mutate(date = ymd(paste(year, month, "01", sep = "-"))) %>%
    arrange(date) %>%
    ungroup() %>%
    select(date, vol_oil, vol_gas, vol_wat) %>% 
    mutate(cum_oil = cumsum(vol_oil), cum_gas = cumsum(vol_gas), 
           cum_wat = cumsum(vol_wat)) %>% 
    print()
#> # A tibble: 104 x 7
#>    date       vol_oil   vol_gas vol_wat  cum_oil    cum_gas cum_wat
#>    <date>       <dbl>     <dbl>   <dbl>    <dbl>      <dbl>   <dbl>
#>  1 2008-02-01  49091.  7068009.   413.    49091.   7068009.    413.
#>  2 2008-03-01  83361. 12191171.    27.4  132452.  19259180.    440.
#>  3 2008-04-01  74532. 11506441.   482.   206985.  30765621.    922.
#>  4 2008-05-01 125479. 19091872. 16280.   332463.  49857492.  17202.
#>  5 2008-06-01 143787. 21512334.   474.   476250.  71369826.  17677.
#>  6 2008-07-01 166280. 24655303.   416.   642530.  96025129.  18093.
#>  7 2008-08-01 165444. 23923541.   577.   807974. 119948670.  18669.
#>  8 2008-09-01 192263. 27526459.   464.  1000237. 147475129.  19134.
#>  9 2008-10-01 237174. 33757700.   725.  1237411. 181232829.  19859.
#> 10 2008-11-01 250325. 35743142.  2580.  1487736. 216975972.  22439.
#> # ... with 94 more rows
```

``` r
# create a dataframe with complete dates from 2008 until Oct-2016
df <- as_tibble(data.frame(date= seq.Date(as.Date("2008-01-01"), 
                                          as.Date("2016-10-01"), by = "month"),
                 cum_oil = 0, cum_gas = 0, cum_wat = 0))
df
#> # A tibble: 106 x 4
#>    date       cum_oil cum_gas cum_wat
#>    <date>       <dbl>   <dbl>   <dbl>
#>  1 2008-01-01       0       0       0
#>  2 2008-02-01       0       0       0
#>  3 2008-03-01       0       0       0
#>  4 2008-04-01       0       0       0
#>  5 2008-05-01       0       0       0
#>  6 2008-06-01       0       0       0
#>  7 2008-07-01       0       0       0
#>  8 2008-08-01       0       0       0
#>  9 2008-09-01       0       0       0
#> 10 2008-10-01       0       0       0
#> # ... with 96 more rows
```

``` r
# historical production
# merge incomplete dataframe and complete with dates
hist_cumulatives_dt <- 
left_join(df, hist_cumulatives, by = "date") %>% 
    # replace NAs with zeros
    tidyr::replace_na(list(cum_oil.y = 0, cum_gas.y = 0, cum_wat.y = 0)) %>%
    tidyr::replace_na(list(vol_oil = 0, vol_gas = 0, vol_wat = 0)) %>%
    # add up the extra column .y
    mutate(cum_oil = cum_oil.x + cum_oil.y) %>%
    mutate(cum_gas = cum_gas.x + cum_gas.y) %>%
    mutate(cum_wat = cum_wat.x + cum_wat.y) %>%
    # filter(date != as.Date("2016-10-01")) %>% 
    # this fixes the zeros generated by adding complete dates
    mutate(cum_oil = ifelse(cum_oil == 0, lag(cum_oil, default=0), cum_oil)) %>%
    mutate(cum_gas = ifelse(cum_gas == 0, lag(cum_gas, default=0), cum_gas)) %>%
    mutate(cum_wat = ifelse(cum_wat == 0, lag(cum_wat, default=0), cum_wat)) %>% 
    select(date, cum_oil, cum_gas, cum_wat, vol_oil, vol_gas, vol_wat) %>%
    as_tibble() %>% 
    print
#> # A tibble: 106 x 7
#>    date        cum_oil    cum_gas cum_wat vol_oil   vol_gas vol_wat
#>    <date>        <dbl>      <dbl>   <dbl>   <dbl>     <dbl>   <dbl>
#>  1 2008-01-01       0          0       0       0         0      0  
#>  2 2008-02-01   49091.   7068009.    413.  49091.  7068009.   413. 
#>  3 2008-03-01  132452.  19259180.    440.  83361. 12191171.    27.4
#>  4 2008-04-01  206985.  30765621.    922.  74532. 11506441.   482. 
#>  5 2008-05-01  332463.  49857492.  17202. 125479. 19091872. 16280. 
#>  6 2008-06-01  476250.  71369826.  17677. 143787. 21512334.   474. 
#>  7 2008-07-01  642530.  96025129.  18093. 166280. 24655303.   416. 
#>  8 2008-08-01  807974. 119948670.  18669. 165444. 23923541.   577. 
#>  9 2008-09-01 1000237. 147475129.  19134. 192263. 27526459.   464. 
#> 10 2008-10-01 1237411. 181232829.  19859. 237174. 33757700.   725. 
#> # ... with 96 more rows
```

``` r
# # historical production
# hist_cum_oil <- 
# hist_cum_oil %>% 
#     mutate(source = "historical") %>% 
#     select(date, cum_oil, source) %>% 
#     mutate(cum_oil = ifelse(cum_oil == 0, lag(cum_oil, default=0), cum_oil)) %>% 
#     as_tibble() %>% 
#     print()
```

### Plot historical cumulatives of oil, gas and water

``` r
# cumulative oil from historical production
ggplot(hist_cumulatives_dt, aes(x = date, y = cum_oil)) +
    geom_line() +
    geom_col(color = "dark green", fill = "dark green", alpha = 0.35) +
    ggtitle("Cumulative Oil, sm3", subtitle = "Historical Production")
```

<img src="README_files/figure-gfm/unnamed-chunk-33-1.png" style="display: block; margin: auto;" />

``` r
# cumulative gas from historical production
ggplot(hist_cumulatives_dt, aes(x = date, y = cum_gas)) +
    geom_line() +
    geom_col(color = "orange", fill = "orange", alpha = 0.35) +
    ggtitle("Cumulative Gas, sm3", subtitle = "Historical Production")
```

<img src="README_files/figure-gfm/unnamed-chunk-34-1.png" style="display: block; margin: auto;" />

``` r
# cumulative water from historical production
ggplot(hist_cumulatives_dt, aes(x = date, y = cum_wat)) +
    geom_line() +
    geom_col(color = "blue", fill = "blue", alpha = 0.35) +
    ggtitle("Cumulative Water, sm3", subtitle = "Historical Production")
```

<img src="README_files/figure-gfm/unnamed-chunk-35-1.png" style="display: block; margin: auto;" />

### Rename the variables according to source

``` r
# rename the simulation cumulatives
sim_cumulatives_src <- 
sim_cumulatives_dt %>% 
    select(date, cum_oil, cum_gas, cum_wat) %>% 
    rename(cum_oil_sim = cum_oil, cum_gas_sim = cum_gas, cum_wat_sim = cum_wat) %>% 
    print()
#> # A tibble: 106 x 4
#>    date       cum_oil_sim cum_gas_sim cum_wat_sim
#>    <date>           <dbl>       <dbl>       <dbl>
#>  1 2008-01-01           0           0           0
#>  2 2008-02-01       30840     4884638           0
#>  3 2008-03-01      120869    19001704           1
#>  4 2008-04-01      194702    30471061       22293
#>  5 2008-05-01      318898    49587013      234843
#>  6 2008-06-01      456145    70554340      427804
#>  7 2008-07-01      611809    94559725      640543
#>  8 2008-08-01      781866   120979880      868196
#>  9 2008-09-01      944881   146185764     1005365
#> 10 2008-10-01     1166111   179756599     1323101
#> # ... with 96 more rows
```

``` r
# rename historical cumulatives according to source
hist_cumulatives_src <- 
hist_cumulatives_dt %>% 
    select(date, cum_oil, cum_gas, cum_wat) %>% 
    rename(cum_oil_hist = cum_oil, cum_gas_hist = cum_gas, cum_wat_hist = cum_wat) %>% 
    print()
#> # A tibble: 106 x 4
#>    date       cum_oil_hist cum_gas_hist cum_wat_hist
#>    <date>            <dbl>        <dbl>        <dbl>
#>  1 2008-01-01           0            0            0 
#>  2 2008-02-01       49091.     7068009.         413.
#>  3 2008-03-01      132452.    19259180.         440.
#>  4 2008-04-01      206985.    30765621.         922.
#>  5 2008-05-01      332463.    49857492.       17202.
#>  6 2008-06-01      476250.    71369826.       17677.
#>  7 2008-07-01      642530.    96025129.       18093.
#>  8 2008-08-01      807974.   119948670.       18669.
#>  9 2008-09-01     1000237.   147475129.       19134.
#> 10 2008-10-01     1237411.   181232829.       19859.
#> # ... with 96 more rows
```

``` r
# # break the variable cum_oil by its source: historical or simulator
# hist_cum_oil_break <- 
# hist_cum_oil %>% 
#     mutate(cum_oil_hist = cum_oil) %>% 
#     # select(date, cum_oil_hist) %>% 
#     print()
```

``` r
# # rename variables for simulator cumulatives
# sim_cum_oil_break <- 
# sim_cum_oil %>% 
#     mutate(cum_oil_sim = cum_oil, cum_gas_sim = cum_gas, cum_wat_sim = cum_wat) %>% 
#     select(date, cum_oil_sim, cum_gas_sim, cum_wat_sim) %>%
#     print()
```

``` r
# combine simulator and historical dataframes. common variable is "date"
cumulatives_all <- full_join(hist_cumulatives_src, sim_cumulatives_src, by = "date")
cumulatives_all
#> # A tibble: 106 x 7
#>    date       cum_oil_hist cum_gas_hist cum_wat_hist cum_oil_sim
#>    <date>            <dbl>        <dbl>        <dbl>       <dbl>
#>  1 2008-01-01           0            0            0            0
#>  2 2008-02-01       49091.     7068009.         413.       30840
#>  3 2008-03-01      132452.    19259180.         440.      120869
#>  4 2008-04-01      206985.    30765621.         922.      194702
#>  5 2008-05-01      332463.    49857492.       17202.      318898
#>  6 2008-06-01      476250.    71369826.       17677.      456145
#>  7 2008-07-01      642530.    96025129.       18093.      611809
#>  8 2008-08-01      807974.   119948670.       18669.      781866
#>  9 2008-09-01     1000237.   147475129.       19134.      944881
#> 10 2008-10-01     1237411.   181232829.       19859.     1166111
#> # ... with 96 more rows, and 2 more variables: cum_gas_sim <dbl>,
#> #   cum_wat_sim <dbl>
```

## How close cumulative productions are

``` r
# Volve reservoir model dataset
# plot historical vs simulator cum_oil
cols <- c("simulator"="red", "historical"="blue") # legend: colors and names
ggplot(cumulatives_all) +
    # shade the area between the curves
    geom_ribbon(aes(x = date, ymin= cum_oil_sim, ymax= cum_oil_hist), 
                fill = "dark green", alpha = 0.35) + 
    geom_line(aes(x = date, y = cum_oil_sim, color = "simulator")) +
    geom_line(aes(x = date, y = cum_oil_hist, color = "historical")) +
    labs(title = "Volve reservoir model. Comparison Cumulative Oil", 
         subtitle = "Historical vs Simulator", 
         y = "cumulative oil, sm3") +
    scale_color_manual(name = "Curve", values = cols)  # manual legend
```

<img src="README_files/figure-gfm/unnamed-chunk-41-1.png" style="display: block; margin: auto;" />

``` r
# Volve reservoir model dataset
# plot historical vs simulator cum_gas
cols <- c("simulator"="red", "historical"="blue") # legend: colors and names
ggplot(cumulatives_all) +
    # shade the area between the curves
    geom_ribbon(aes(x = date, ymin= cum_gas_sim, ymax= cum_gas_hist), 
                fill = "orange", alpha = 0.35) + 
    geom_line(aes(x = date, y = cum_gas_sim, color = "simulator"), size = 1) +
    geom_line(aes(x = date, y = cum_gas_hist, color = "historical"), size = 1) +
    labs(title = "Volve reservoir model. Comparison Cumulative Gas", 
         subtitle = "Historical vs Simulator", 
         y = "cumulative gas, sm3") +
    scale_color_manual(name = "Curve", values = cols)  # manual legend
```

<img src="README_files/figure-gfm/unnamed-chunk-42-1.png" style="display: block; margin: auto;" />

``` r
# Volve reservoir model dataset
# plot historical vs simulator cumulative water variable
cols <- c("simulator"="red", "historical"="blue") # legend: colors and names
ggplot(cumulatives_all) +
    # shade the area between the curves
    geom_ribbon(aes(x = date, ymin= cum_wat_sim, ymax= cum_wat_hist), 
                fill = "cyan", alpha = 0.35) + 
    geom_line(aes(x = date, y = cum_wat_sim, color = "simulator"), size = 1) +
    geom_line(aes(x = date, y = cum_wat_hist, color = "historical"), size = 1) +
    labs(title = "Volve reservoir model. Comparison Cumulative Water", 
         subtitle = "Historical vs Simulator", 
         y = "cumulative water, sm3") +
    scale_color_manual(name = "Curve", values = cols)  # manual legend
```

<img src="README_files/figure-gfm/unnamed-chunk-43-1.png" style="display: block; margin: auto;" />
