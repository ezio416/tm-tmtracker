/*
c 2023-07-16
m 2023-10-09
*/

namespace Settings {
    [Setting hidden] uint nandoRequestWait = 1000;
    [Setting hidden] bool windowOpen       = false;


    [Setting category="General" name="Show status bar"]
    bool statusBar = true;

    [Setting category="General" name="Show welcome text"]
    bool welcomeText = true;

    [Setting category="General" name="Show info tab"]
    bool infoTab = true;

    [Setting category="General" name="Days to keep account names" min=0 max=30]
    uint accountNameValidDays = 7;


    [Setting category="Startup" name="Refresh my maps"]
    bool refreshMaps = false;

    [Setting category="Startup" name="Remember if window was open"]
    bool rememberOpen = false;


    [Setting category="Logging" name="Log level" description="Debug clutters the log - only use if needed!"]
    Log::Level logLevel = Log::Level::Normal;


    [Setting category="My Maps List" name="Show help text"]
    bool myMapsListHint = true;

    [Setting category="My Maps List" name="Show map names with color"]
    bool myMapsListColor = true;

    [Setting category="My Maps List" name="Show number of records"]
    bool myMapsListColRecords = true;

    [Setting category="My Maps List" name="Show latest record update time"]
    bool myMapsListColRecordsTime = true;

    [Setting category="My Maps List" name="Show latest map upload time"]
    bool myMapsListColUpload = true;


    [Setting category="My Map Tabs" name="Show map names with color"]
    bool myMapTabsColor = true;

    [Setting category="My Map Tabs" name="Switch to map when clicked"]
    bool myMapTabsSwitchOnClicked = true;

    [Setting category="My Map Tabs" name="Thumbnail width" min=100 max=1000]
    uint myMapTabsThumbWidth = uint(Globals::scale * 150);

    [Setting category="My Map Tabs" name="Automatically load thumbnails"]
    bool myMapTabsLoadThumbs = false;

    [Setting category="My Map Tabs" name="Max records to get per map"]
    uint maxRecordsPerMap = 100;

    [Setting category="My Map Tabs" name="Show map record times with medal colors"]
    bool mapRecordsMedalColors = true;


    [Setting category="My Map Records" name="Show time estimate"]
    bool recordsEstimate = true;

    [Setting category="My Map Records" name="Show record times with medal colors"]
    bool recordsMedalColors = true;

    [Setting category="My Map Records" name="Highlight top 5 world"]
    bool recordsHighlight5 = true;

    [Setting category="My Map Records" name="Top 5 highlight color"]
    string recordsHighlightColor = "F71";
}