# Patient Feedback data Rapid-Reporting pipeline: Limesurvey and R

**Date:** 2023-03-30

The idea of the pipeline is to collect and analyse feedback data in a quick
and easy way and minimise the amount of time everyone (_patients, therapists, 
assistant-psychologists, admin-people, performance-managers_) spends on data. 

For starters we can have any easy to do questionnaire
which takes less than a minute to do at the beginning of a therapy session. 
We then are able to visualize the data straight from the survey server -
it takes about 10 seconds to produce the report that visualizes the data. Because 
we are using R, we can make report as simple or as complex as we need to; making 
of the report will be quick and automatic.

_Make once, use, rinse and repeat._

The output of the report is in _PDF_ format and is easy to share, print and modify
 by editing the `.Rmd` script.

## How to collect data

To reproduce steps of this demo one presumes that you have access to:

* a limesurvey installation
	- easily installed on most cloud providers -e.g. via `softaculous` in `cPanel` - it takes about 10 seconds
	- or easily installed on your own LAMP server (e.g. your laptop) - [instructions here](https://manual.limesurvey.org/Installation_-_LimeSurvey_CE/en)
		+ in case you are installing on Linux - a package is available on [AUR](https://aur.archlinux.org/) and installing on any linux distribution is described in the manual and many places over internet, including [YouTube](https://www.youtube.com/watch?v=MEO9kUWIumc) videos.
	- enable [RPC interface](https://manual.limesurvey.org/RemoteControl_2_API#How_to_configure_LSRC2.) - it is known as Lime Survey Remote Control 2 (LSRC2) 
* R and Rstudio installation
	- you need to enable the libraries as seen in the `.Rmd` script
	- installation of [limer](https://github.com/cloudyr/limer) library is done via devtools 
* Make QRcodes to collect your demo-session-user responses
	- the format of the link will be
	- `https://yourserver.org/surveynumber/?Q003ID=yourusercode`

> `suverynumber` is an integer and in the test data I have used 6 digit integers for `yourusercode`.

Making QR codes and/or easy shortlinks makes data entry much easier, so I would advise to prepare the QR-Codes. I do it via R - running a script over an Excel file that other users can easily prepare.

## Format of .properties file
 
So that one would not need to modify the script in order to set the time window for
analysis, or make graphs for an individual patient, all the variables that may change
are saved in the `script.properties` file consisting of `key=value` pairs and explanatory
comments (lines starting with `#`). As the file contains mildly sensitive information - such
as your web server name and lime survey RPC api address, as well as your read-only
limesurvey user that fetches the data, the file itself is not included in the repo. 
Instead you can create a plain text file, save it as `script.properties` in the project
directory and paste the contents of this code section into it to modify as needed:

```properties
# CHANGE IF NECESSARY: #########################################

# for one person report type YES here instead of NO
onePerson=NO
# then write the correct id number (hint: read from the graph)
onePersonNumber=111333  
# to reset DEMO data type YES here instead of NO 
resetDemo=NO

# Dates for which feedback is analysed ########################
# Date Time Formats: ##########################################
# Date: yyyy-mm-dd   e.g. 2018-10-01 is 1st Oct 2018
# Time: hh:mm        according to 24 hour clock

dateStart=2019-10-08
timeStart=00:00
dateEnd=2023-09-15
timeEnd=23:30

################################################################
################################################################
# do not touch - variables to communicate with limesurvey
################################################################
limeAPI=https://your.limeserver.name/index.php/admin/remotecontrol
limeUser=yourReadOnlyUserName
limePassword=ThatUser'sPassword
# DEMO survey - replace with your demo survey number
limeSurveyNumber=222234
```

## Sample survey structure and data

The `.lss` file that you can use to create the demo survey structure is 
in the directory `survey_structure` in this project. You can import the
survey from the main menu `Surveys | Import Survey`. To populate the
survey with the sample data you can use the `vvexport` file in the same
directory.


## Need for reliable demo data

It is better to utilise actual data, but at times we need to demo how
the pipeline works. Therefore a set of 126 demo measurements has been made. 
The date when the measurement is made (`submitdate`) is used to make a time
series graph. However if there is a considerable time-gap between the
submitdates in DEMO data and today, the graphs look odd. It is not exactly
something one wishes to explain to people who are looking at the demo for 
the first time. 

Therefore I have made a script `resetDemoData.R` for deleting extraneous 
responses and bringing the dates in the demo survey on the server to where 
the latest date is about 10 days in the past. 
The script is activated via the `properties` file - you need
to write YES at `resetDemo=` parameter in the said file.

### Resetting demo data

Then `resetDemoData.R` script automatically does the following:

* obtains dataset from the survey
* filters out any invalid responder IDs (there are 7 valid ones for this demo, people in their zest to experiment sometimes may adjust the GET parameter in the link - ?Q003ID=yourusercode)
* arranges data by submitdate and for each response adds 'mdate'- a floor-date (monday) on the week when the 'submitdate' was produced. For comparisons and graphs it is better to set a uniform weekday when we think the responses should be produced. When we analyze data in detail, we can always use the correct date in the data as that does not get modified.
* checks that there are 7 day intervals between 'mdates'
* checks that for every mdate there are responses present from all 7 responders
* deletes all the responses on te survey server that do not match the above criteria
	- this way we get back to the original 126 records (18 weeks of 7 unique obs each)
* then we calculate max `submitdate` and we can see how many days ago from today (`Sys.Date()`) it is
* then add that number - 10 to each `submitdate` on the server
	- _Voilà!_ we have brought the response block to end -10 days from now
	- that means we can demo the survey to people again and the new results will look fine
	
This method of reporting can work for surveys of any complexity, but I find that a demonstration should be simple. For longer surveys the report may take a dozen seconds more, but it will be a good looking report,  produced in an automated and reproducible way, saving human labour that otherwise _is being_ spent on getting data, putting together tables, making charts by clicking in spreadsheets then writing the same thing again and again in MS Word. $_{No\:\: assistant-psychologists\: were\: harmed\: in\: making\: this\: project}$