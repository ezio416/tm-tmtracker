/*
c 2023-05-16
m 2023-07-06
*/

namespace Settings {
    ///////////////////////////////////////////////////////////////////////////
    // GENERAL
    ///////////////////////////////////////////////////////////////////////////
    [Setting category="General" name="Show status bar"]
    bool statusBar = true;

    [Setting category="General" name="Show welcome text"]
    bool welcomeText = true;

    [Setting category="General" name="Show info tab"]
    bool infoTab = true;

    [Setting category="General" name="Account name valid time (days)" min=0 max=60 description="time after which the name will be retrieved again"]
    uint accountNameExpirationDays = 7;

    ///////////////////////////////////////////////////////////////////////////
    // STARTUP
    ///////////////////////////////////////////////////////////////////////////
    [Setting category="Startup" name="Remember window open state"]
    bool rememberOpen = false;

    ///////////////////////////////////////////////////////////////////////////
    // LOGGING
    ///////////////////////////////////////////////////////////////////////////
    [Setting category="Logging" name="Enabled" description="only Openplanet log, no file yet"]
    bool logEnabled = true;

    [Setting category="Logging" name="Task durations"]
    bool logDurations = false;

    [Setting category="Logging" name="    + thumbnail load times"]
    bool logThumbnailTimes = false;

    ///////////////////////////////////////////////////////////////////////////
    // MAP LIST
    ///////////////////////////////////////////////////////////////////////////
    [Setting category="Map List" name="Show map names with color"]
    bool myMapsListColor = true;

    [Setting category="Map List" name="Thumbnail width" min=10 max=1000]
    uint myMapsListThumbnailWidth = 200;

    ///////////////////////////////////////////////////////////////////////////
    // MAP TABS
    ///////////////////////////////////////////////////////////////////////////
    [Setting category="Map Tabs" name="Switch to map when clicked"]
    bool myMapsSwitchOnClicked = true;

    [Setting category="Map Tabs" name="Show map name with color on tab"]
    bool myMapsTabsColor = true;

    [Setting category="Map Tabs" name="Show record times with medal colors"]
    bool recordMedalColors = true;

    [Setting category="Map Tabs" name="Thumbnail width" min=10 max=1000]
    uint myMapsCurrentThumbnailWidth = 400;

    [Setting category="Map Tabs" name="Max records to get per map" min=100 max=1000 description="records are fetched in batches of 100 until this limit"]
    uint maxRecordsPerMap = 100;

    ///////////////////////////////////////////////////////////////////////////
    // HIDDEN
    ///////////////////////////////////////////////////////////////////////////
    [Setting hidden]
    string dateFormat = "%a \\$F98%Y-%m-%d \\$Z%H:%M:%S \\$F98";

    [Setting hidden]
    bool devHidden = false;

    [Setting hidden]
    bool devHiddenByUser = false;

    [Setting hidden]
    uint timeBetweenNadeoRequests = 500;

    [Setting hidden]
    bool windowOpen = false;
}