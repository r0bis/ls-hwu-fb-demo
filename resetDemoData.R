# dataframe already obtained
### !!! don't forget set survey participant setting to TRUE
### Allow multiple responses or update responses with one token !!!

# seven (7) valid response IDs for this demo are:
validIdVec <- c(111111,111333,121212,131313,444444,666666,777117)
# we just know that, there is nothing to calculate
UPDATEonSERVER = ""


allIDs <- unique(initData$id)

# prepare column names
names(initData) <- gsub("\\.$", "", names(initData))
# initData <- initData %>% mutate(submitdate = ymd_hms(submitdate))
# add date and mdate (floor on monday) fields order by date
initData <- initData %>% mutate(date = as_date(submitdate))
initData <- initData %>% arrange(submitdate)
initData <- initData %>% mutate(mdate = 
                                  floor_date(date, unit = "week", week_start = getOption("lubridate.week.start", 1)))

# 1. filter out data with invalid response IDs
initData <- initData %>% filter(Q003ID %in% validIdVec)

# 2. prepare to filter out data with bigger than 7 day intervals for mdate
df.uniqMdate <- as.data.frame(unique(sort(initData$mdate)))
names(df.uniqMdate) <- c("mdate")
# add columns with lag and cumsum
df.uniqMdate <- df.uniqMdate %>% 
  mutate(BETWEEN0=as.numeric(difftime(mdate,lag(mdate,1))),BETWEEN=ifelse(is.na(BETWEEN0),0,BETWEEN0),FIRST=cumsum(as.numeric(BETWEEN)))%>%
  select(-BETWEEN0)
# add day lag values to main dataframe
initData <- inner_join(initData, df.uniqMdate, by="mdate")

# 3. prepare to filter out data with less than 7 unique ids per mdate 
# now set number of unique responder IDs per mdate (we need 7) and add to main dataframe
df.goodObs <- initData %>% select(mdate,Q003ID) %>% distinct() %>% group_by(mdate) %>%  count()
names(df.goodObs) <- c('mdate','goodObs')
initData <- inner_join(initData, df.goodObs, by="mdate")

# actually filter out the unneeded data
initData <- initData %>% filter(.,BETWEEN <= 7, goodObs == 7)
# set response ids that we want to keep
goodIDs <- unique(initData$id)

# 4. delete invalid responses from server (using question ids)
deletableIds <- setdiff(allIDs,goodIDs)

# if there are rows to delete, then do so
if (length(deletableIds) > 0) {
  for (i in 1:length(deletableIds)) {
    id2delete <- deletableIds[i]
    print(paste(id2delete, "id will be deleted" ))
    call_limer(method = "delete_response",
               params = list(iSurveyID = props$limeSurveyNumber,
                             iResponseID = id2delete))
  }
}
# 5. update the submitdate field 

# set N days to add to all submitdate values. Should be 10 days less than
# the difference between today and max/latest submitdate in the dataset
# so the new experimental values added would be just about a week after the last 
days2add <- round(-as.numeric(max(as_datetime(initData$submitdate)) - Sys.time()),0) - 10

# unless we have run it already let's  add to submitdate
if (round(abs(as.numeric(max(as_datetime(initData$submitdate)) - Sys.time())),0) > 10) {
  print("updating dataset dates to minus 10")
  initData <- initData %>% 
    mutate(submitdate = as_datetime(submitdate) + days(days2add)) %>% 
    mutate(submitdate = as.character(format(submitdate,"%Y-%m-%d %H:%M:%S")))
  # so now we have correct/desired dates in our LOCAL dataframe
} else {"no date update was detected as needed for the LOCAL dataframe"
        UPDATEonSERVER <- "NO"  
}


# main loop to update submitdate on server
if (UPDATEonSERVER != "NO") {
  for (row in 1:nrow(initData)) {
    id <- initData[row, "id"]
    submitdate  <- initData[row, "submitdate"]
    # question  <- initData[row, "Q01"]
    
    aResponseData <- list("id" = id, "submitdate" = submitdate)
    
    
    if(nchar(id) > 0) {
      call_limer(method = "update_response",
                 params = list(iSurveyID = props$limeSurveyNumber,
                               aResponseData = aResponseData)
      )
      print(paste("The response with ID", id, 
                  "has submitdate updated to", submitdate))
    }
  }
}

# TEST UPDATING don't forget to set 'Allow response updates to TRUE !!!
# aResponseData <- list("id" = 209, "submitdate" = "2020-07-03 15:36:45")
# call_limer(method = "update_response",
#            params = list(iSurveyID = props$limeSurveyNumber,
#                          aResponseData = aResponseData))


print("Finished updating DEMO dataset on LimeSurvey")
