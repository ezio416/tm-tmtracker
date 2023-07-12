/*
c 2023-05-16
m 2023-07-12
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

    [Setting category="General" name="Account name valid time (days)" min=0 max=60 description="time after which names will be retrieved again"]
    uint accountNameExpirationDays = 7;

    ///////////////////////////////////////////////////////////////////////////
    // STARTUP
    ///////////////////////////////////////////////////////////////////////////
    [Setting category="Startup" name="Remember window open state" description="if unchecked, the window is never shown when the game starts"]
    bool rememberOpen = false;

    [Setting category="Startup" name="Refresh maps"]
    bool startupMyMaps = true;

    ///////////////////////////////////////////////////////////////////////////
    // LOGGING
    ///////////////////////////////////////////////////////////////////////////
    [Setting category="Logging" name="Enabled" description="only Openplanet log, no file yet"]
    bool logEnabled = true;

    [Setting category="Logging" name="Task durations"]
    bool logDurations = false;

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
    bool mapRecordsMedalColors = true;

    [Setting category="Map Tabs" name="Thumbnail width" min=10 max=1000]
    uint myMapsCurrentThumbnailWidth = 400;

    [Setting category="Map Tabs" name="Max records to get per map" min=100 max=1000 description="records are fetched in batches of 100 until this limit"]
    uint maxRecordsPerMap = 100;

    ///////////////////////////////////////////////////////////////////////////
    // RECORDS
    ///////////////////////////////////////////////////////////////////////////
    [Setting category="Records" name="Show time estimate"]
    bool recordsEstimate = true;

    [Setting category="Records" name="Highlight top 5 world" description="so you can spectate with proper access"]
    bool recordsHighlight5 = true;

    [Setting category="Records" name="Highlight color"]
    string recordsHighlightColor = "F71";

    [Setting category="Records" name="Show record times with medal colors"]
    bool recordsMedalColors = true;

    ///////////////////////////////////////////////////////////////////////////
    // HIDDEN
    ///////////////////////////////////////////////////////////////////////////
    [Setting hidden]
    string dateFormat = "\\$AAA%a \\$G%Y-%m-%d %H:%M:%S \\$AAA";

    [Setting hidden]
    bool debugHidden = true;

    [Setting hidden]
    uint timeBetweenNadeoRequests = 500;

    [Setting hidden]
    bool windowOpen = false;
}