# extract field totals

library(dplyr)
library(lubridate)

extract_field_totals <- function(prt_file_content) {
    volve_2016_txt <- prt_file_content
    
    # find the rows where we find the word "BALANCE  AT"
    balance_rows <- grep("^.*BALANCE  AT", volve_2016_txt)
    
    # add rows ahead to where the word BALANCE AT was found
    field_totals_range <- lapply(seq_along(balance_rows), function(x) 
        c(balance_rows[x], balance_rows[x]+1:21))
    
    # try different strategy
    # iterating through the report pages in FIELD TOTALS
    # get:
    #    days, oil currently in place, oil originally in place, 
    #    oil outflow through wells
    
    # get the text from all pages and put them in a list
    field_totals_report_txt <- lapply(seq_along(field_totals_range), function(x) 
        volve_2016_txt[field_totals_range[[x]]])
    
    # iterate through the list of pages
    field_totals_dfs <- lapply(seq_along(field_totals_report_txt), function(x) {
        page <- field_totals_report_txt[[x]]  # put all pages text in a list
        days_row_txt <- page[1] # get 1st row of page
        days_value <- sub(".*?(\\d+.\\d.)+.*", "\\1", days_row_txt) # extract the days
        
        # get the date
        date_row_txt <- grep("^.*REPORT", page)
        date_value <- sub(".*?(\\d{1,2} [A-Z]{3} \\d{4})+.*", "\\1", page[date_row_txt])
        date_value <- sub("JLY", "JUL", date_value)  # change JLY by JUL
        
        # get oil currently in place
        ocip_row_txt <- grep("^.*:CURRENTLY IN PLACE", page)
        ocip_value <- sub(".*?(\\d+.)+.*", "\\1", page[ocip_row_txt])
        
        # get OOIP
        ooip_row_txt <- grep("^.*:ORIGINALLY IN PLACE", page)
        ooip_value <- sub(".*?(\\d+.)+.*", "\\1", page[ooip_row_txt])
        
        # get total fluid outflow through wells
        otw_row_txt <- grep("^.*:OUTFLOW THROUGH WELLS", page) # row index at this line
        otw_group_pattern <- ".*?(\\d+.)+.*?(\\d+.)+.*?(\\d+.)+.*"  # groups
        oil_otw_value <- sub(otw_group_pattern, "\\1", page[otw_row_txt]) # get oil outflow
        wat_otw_value <- sub(otw_group_pattern, "\\2", page[otw_row_txt]) # get gas outflow
        gas_otw_value <- sub(otw_group_pattern, "\\3", page[otw_row_txt]) # get water
        
        # get pressure
        pav_row_txt <- grep("PAV =", page)
        pav_value <- sub(".*?(\\d+.\\d.)+.*", "\\1", page[pav_row_txt])
        
        # dataframe
        data.frame(
            date = dmy(date_value), 
            days = as.integer(days_value), 
            ocip = as.double(ocip_value), 
            ooip = as.double(ooip_value), 
            oil_otw = as.double(oil_otw_value),
            wat_otw = as.double(wat_otw_value),
            gas_otw = as.double(gas_otw_value), 
            pav = as.double(pav_value),
            stringsAsFactors = FALSE
        ) 
    })
    
    as_tibble(do.call("rbind", field_totals_dfs))
    
}

