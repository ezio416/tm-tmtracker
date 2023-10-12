/*
c 2023-07-16
m 2023-10-11
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

    [Setting category="General" name="Max records to get per map"]
    uint maxRecordsPerMap = 100;


    [Setting category="Startup" name="Refresh my map list"]
    bool refreshMaps = false;

    [Setting category="Startup" name="Remember if window was open"]
    bool rememberOpen = false;


    [Setting category="Colors" name="Show map names with color"]
    bool mapNameColors = true;

    [Setting category="Colors" name="Show record times with medal colors"]
    bool medalColors = true;

    [Setting category="Colors" name="Top 5 highlight color"]
    string top5HighlightColor = "F71";


    [Setting category="Logging" name="Log level" description="Debug clutters the log - only use if needed!"]
    Log::Level logLevel = Log::Level::Normal;


    [Setting category="Map List" name="Show help text"]
    bool myMapsListText = true;

    [Setting category="Map List" name="Show number of records"]
    bool myMapsListColRecords = true;

    [Setting category="Map List" name="Show latest record update time"]
    bool myMapsListColRecordsTime = true;

    [Setting category="Map List" name="Show latest map upload time"]
    bool myMapsListColUpload = true;


    [Setting category="My Map Records" name="Show time estimate + help text"]
    bool recordsEstimate = true;

    [Setting category="My Map Records" name="Highlight top 5 world"]
    bool recordsHighlight5 = true;


    [Setting category="Viewing Maps" name="Show help text"]
    bool viewingText = true;

    [Setting category="Viewing Maps" name="Automatically load thumbnails"]
    bool viewingLoadThumbs = false;

    [Setting category="Viewing Maps" name="Thumbnail width" min=100 max=1000]
    uint viewingThumbWidth = uint(Globals::scale * 150);


    [Setting category="My Records" name="Show help text"]
    bool myRecordsText = true;
}