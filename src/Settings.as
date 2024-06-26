// c 2023-07-16
// m 2024-01-19

namespace Settings {
    [Setting hidden] Sort::Maps::SortMethod    myMapsSortMethod        = Sort::Maps::SortMethod::HighestFirst;
    [Setting hidden] Sort::Records::SortMethod myMapsRecordsSortMethod = Sort::Records::SortMethod::NewFirst;
    [Setting hidden] Sort::Records::SortMethod myMapsViewingSortMethod = Sort::Records::SortMethod::BestPosFirst;
    [Setting hidden] Sort::Records::SortMethod myRecordsSortMethod     = Sort::Records::SortMethod::NewFirst;
    [Setting hidden] uint                      nandoRequestWait        = 1000;
    [Setting hidden] bool                      windowOpen              = false;

    [Setting category="General" name="Show status bar"]
    bool statusBar = true;

    [Setting category="General" name="Show welcome text"]
    bool welcomeText = true;

    [Setting category="General" name="Days to keep account names" min=0 max=30]
    uint accountNameValidDays = 7;

    [Setting category="General" name="Max records to get per map" min=100 max=1000]
    uint maxRecordsPerMap = 100;

    [Setting category="General" name="Max recent maps to get" description="0 (default) means all maps. If your game crashes, limit to about 500 (exact number unknown)."]
    uint maxMaps = 0;

    [Setting category="General" name="Show My Maps tab"]
    bool myMapsTab = true;

    [Setting category="General" name="Show My Records tab"]
    bool myRecordsTab = true;

    [Setting category="General" name="Show Info tab"]
    bool infoTab = true;

#if SIG_DEVELOPER
    [Setting category="General" name="Show Debug tab" description="Developer mode only"]
    bool debugTab = false;
#endif


    [Setting category="Startup" name="Refresh my map list"]
    bool refreshMaps = false;

    [Setting category="Startup" name="Remember if window was open"]
    bool rememberOpen = false;


    [Setting category="Colors" name="Show map names with color"]
    bool mapNameColors = true;

    [Setting category="Colors" name="Highlight top 5 world"]
    bool highlightTop5 = true;

    [Setting category="Colors" name="Top 5 color" color]
    vec3 colorTop5 = vec3(1.0f, 0.55f, 0.0f);

    [Setting category="Colors" name="Show record times with medal colors"]
    bool medalColors = true;

    [Setting category="Colors" name="Author medal" color]
    vec3 colorMedalAuthor = vec3(0.17f, 0.75f, 0.0f);

    [Setting category="Colors" name="Gold medal" color]
    vec3 colorMedalGold = vec3(1.0f, 0.97f, 0.0f);

    [Setting category="Colors" name="Silver medal" color]
    vec3 colorMedalSilver = vec3(0.75f, 0.75f, 0.75f);

    [Setting category="Colors" name="Bronze medal" color]
    vec3 colorMedalBronze = vec3(0.69f, 0.5f, 0.0f);

    [Setting category="Colors" name="No medal" color]
    vec3 colorMedalNone = vec3(1.0f, 1.0f, 1.0f);


    [Setting category="My Maps" name="Show help text"]
    bool myMapsListText = true;

    [Setting category="My Maps" name="Show map search field"]
    bool myMapsSearch = true;

    [Setting category="My Maps" name="Show column: map number"]
    bool myMapsListColNumber = true;

    [Setting category="My Maps" name="Show column: number of records"]
    bool myMapsListColRecords = true;

    [Setting category="My Maps" name="Show column: latest record update time"]
    bool myMapsListColRecordsTime = true;

    [Setting category="My Maps" name="Show column: latest map upload time"]
    bool myMapsListColUpload = true;


    [Setting category="My Maps' Records" name="Show time estimate + help text"]
    bool recordsEstimate = true;

    [Setting category="My Maps' Records" name="Notify when done getting records"]
    bool myMapsRecordsNotify = true;

    [Setting category="My Maps' Records" name="Show map search field"]
    bool myMapsRecordsMapSearch = true;

    [Setting category="My Maps' Records" name="Show account search field"]
    bool myMapsRecordsAccountSearch = true;

    [Setting category="My Maps' Records" name="Show column: position"]
    bool myMapsRecordsColPos = true;

    [Setting category="My Maps' Records" name="Show column: time"]
    bool myMapsRecordsColTime = true;

    [Setting category="My Maps' Records" name="Show column: timestamp"]
    bool myMapsRecordsColTimestamp = true;

    [Setting category="My Maps' Records" name="Show column: recency"]
    bool myMapsRecordsColRecency = true;


    [Setting category="My Records" name="Show help text"]
    bool myRecordsText = true;

    [Setting category="My Records" name="Show map search field"]
    bool myRecordsMapSearch = true;

    [Setting category="My Records" name="Show author search field"]
    bool myRecordsAuthorSearch = true;

    [Setting category="My Records" name="Show column: author"]
    bool myRecordsColAuthor = true;

    [Setting category="My Records" name="Show column: author time"]
    bool myRecordsColAT = true;

    [Setting category="My Records" name="Show column: personal best"]
    bool myRecordsColPB = true;

    [Setting category="My Records" name="Show column: delta to author medal"]
    bool myRecordsColDelta = true;

    [Setting category="My Records" name="Show column: timestamp"]
    bool myRecordsColTimestamp = true;

    [Setting category="My Records" name="Show column: recency"]
    bool myRecordsColRecency = true;


    [Setting category="Viewing Maps" name="Show help text"]
    bool viewingText = true;

    [Setting category="Viewing Maps" name="Switch to map tab when clicked"]
    bool viewingSwitchOnClicked = true;

    [Setting category="Viewing Maps" name="Automatically load thumbnails"]
    bool viewingLoadThumbs = false;

    [Setting category="Viewing Maps" name="Thumbnail width" min=100 max=1000]
    uint viewingThumbWidth = uint(Globals::scale * 150);

    [Setting category="Viewing Maps" name="Show map's last upload time"]
    bool viewingMapUploadTime = true;

    [Setting category="Viewing Maps" name="(My maps) Show column: position"]
    bool viewingMyMapColPos = true;

    [Setting category="Viewing Maps" name="(My maps) Show column: time"]
    bool viewingMyMapColTime = true;

    [Setting category="Viewing Maps" name="(My maps) Show column: timestamp"]
    bool viewingMyMapColTimestamp = true;

    [Setting category="Viewing Maps" name="(My maps) Show column: recency"]
    bool viewingMyMapColRecency = true;

    [Setting category="Viewing Maps" name="(My records) Show column: delta to bronze medal"]
    bool viewingMyRecordColBronze = true;

    [Setting category="Viewing Maps" name="(My records) Show column: delta to silver medal"]
    bool viewingMyRecordColSilver = true;

    [Setting category="Viewing Maps" name="(My records) Show column: delta to gold medal"]
    bool viewingMyRecordColGold = true;

    [Setting category="Viewing Maps" name="(My records) Show column: delta to author medal"]
    bool viewingMyRecordColAT = true;

    [Setting category="Viewing Maps" name="(My records) Show column: timestamp"]
    bool viewingMyRecordColTimestamp = true;

    [Setting category="Viewing Maps" name="(My records) Show column: recency"]
    bool viewingMyRecordColRecency = true;


    [Setting category="Logging" name="Log level" description="Debug clutters the log - only use if needed!"]
    Log::Level logLevel = Log::Level::Normal;
}
