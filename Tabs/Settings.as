/*
c 2023-07-16
m 2023-09-24
*/

namespace Tabs {
    void Tab_Settings() {
        if (!UI::BeginTabItem(Icons::Cog + " Settings")) return;

        if (Settings::settingsWindow) {
            if (UI::Button(Icons::WindowClose + " Close settings window")) {
                Settings::settingsWindow = false;
            }
            UI::SameLine();
            Settings::settingsResize = UI::Checkbox("Auto-resize", Settings::settingsResize);
        } else {
            if (UI::Button(Icons::WindowRestore + " Open settings window")) {
                Settings::settingsWindow = true;
            }
        }

        UI::Separator();

        if (UI::BeginChild("settings")) {
            Settings::Group_Settings();
            UI::EndChild();
        }

        UI::EndTabItem();
    }
}

namespace Settings {
    bool save = false;

    [Setting hidden] uint   accountNameValidDays     = 7;
    [Setting hidden] bool   autoThumbnails           = false;
    [Setting hidden] bool   infoTab                  = true;
    [Setting hidden] int    maxMaps                  = -1;
    [Setting hidden] bool   mapRecordsMedalColors    = true;
    [Setting hidden] uint   maxRecordsPerMap         = 100;
    [Setting hidden] uint   myMapsCurrentThumbWidth  = uint(Globals::scale * 150);
    [Setting hidden] bool   myMapsListHint           = true;
    [Setting hidden] bool   myMapsListColor          = true;
    [Setting hidden] bool   myMapsListColRecords     = true;
    [Setting hidden] bool   myMapsListColRecordsTime = true;
    [Setting hidden] bool   myMapsListColUpload      = true;
    [Setting hidden] bool   myMapsListThumbnails     = true;
    [Setting hidden] uint   myMapsListThumbWidth     = uint(Globals::scale * 16);
    [Setting hidden] bool   myMapsSwitchOnClicked    = true;
    [Setting hidden] bool   myMapsTabsColor          = true;
    [Setting hidden] bool   recordsEstimate          = true;
    [Setting hidden] bool   recordsHighlight5        = true;
    [Setting hidden] string recordsHighlightColor    = "F71";
    [Setting hidden] bool   recordsMedalColors       = true;
    [Setting hidden] bool   refreshMaps              = false;
    [Setting hidden] bool   rememberOpen             = false;
    [Setting hidden] bool   settingsResize           = true;
    [Setting hidden] bool   statusBar                = true;
    [Setting hidden] bool   welcomeText              = true;

    [Setting hidden] string dateFormat               = "\\$AAA%a \\$G%Y-%m-%d %H:%M:%S \\$AAA";
    [Setting hidden] bool   debugHidden              = true;
    [Setting hidden] bool   settingsWindow           = false;
    [Setting hidden] uint   timeBetweenNadeoRequests = 1000;
    [Setting hidden] bool   windowOpen               = false;

    enum Category {
        General,
        Startup,
        MyMapsList,
        MyMapsTabs,
        Records
    }

    void Reset(Category cat) {
        auto plugin = Meta::ExecutingPlugin();
        switch (cat) {
            case Category::General:
                plugin.GetSetting("statusBar").Reset();
                plugin.GetSetting("welcomeText").Reset();
                plugin.GetSetting("infoTab").Reset();
                plugin.GetSetting("autoThumbnails").Reset();
                plugin.GetSetting("accountNameValidDays").Reset();
                break;
            case Category::Startup:
                plugin.GetSetting("refreshMaps").Reset();
                plugin.GetSetting("rememberOpen").Reset();
                break;
            case Category::MyMapsList:
                plugin.GetSetting("myMapsListHint").Reset();
                plugin.GetSetting("maxMaps").Reset();
                plugin.GetSetting("myMapsListThumbnails").Reset();
                plugin.GetSetting("myMapsListThumbWidth").Reset();
                plugin.GetSetting("myMapsListColor").Reset();
                plugin.GetSetting("myMapsListColRecords").Reset();
                plugin.GetSetting("myMapsListColRecordsTime").Reset();
                plugin.GetSetting("myMapsListColUpload").Reset();
                break;
            case Category::MyMapsTabs:
                plugin.GetSetting("myMapsTabsColor").Reset();
                plugin.GetSetting("myMapsSwitchOnClicked").Reset();
                plugin.GetSetting("mapRecordsMedalColors").Reset();
                plugin.GetSetting("myMapsCurrentThumbWidth").Reset();
                plugin.GetSetting("maxRecordsPerMap").Reset();
                break;
            case Category::Records:
                plugin.GetSetting("recordsEstimate").Reset();
                plugin.GetSetting("recordsMedalColors").Reset();
                plugin.GetSetting("recordsHighlight5").Reset();
                plugin.GetSetting("recordsHighlightColor").Reset();
                break;
            default: break;
        }
    }

    void Group_Settings() {
        UI::BeginGroup();
            if (UI::Button(Icons::FloppyO + " Save"))
                Meta::SaveSettings();
            Util::HoverTooltip("shouldn't be necessary, but here just in case");

            UI::SameLine();
            if (UI::Button(Icons::Refresh + " Reset all to defaults")) {
                Settings::Reset(Settings::Category::General);
                Settings::Reset(Settings::Category::Startup);
                Settings::Reset(Settings::Category::MyMapsList);
                Settings::Reset(Settings::Category::MyMapsTabs);
                Settings::Reset(Settings::Category::Records);
            }

            UI::Separator();

            if (UI::Selectable("\\$2F3" + Icons::Cogs + " General", false))
                Reset(Category::General);
            Util::HoverTooltip("click to reset section to defaults");
            statusBar            = UI::Checkbox("Show status bar", statusBar);
            welcomeText          = UI::Checkbox("Show welcome text", welcomeText);
            infoTab              = UI::Checkbox("Show info tab", infoTab);
            autoThumbnails       = UI::Checkbox("Load thumbnails automatically", autoThumbnails);
            accountNameValidDays = UI::SliderInt("Account name valid time (days)", accountNameValidDays, 0, 30);

            UI::Separator();
            if (UI::Selectable("\\$2F3" + Icons::PlayCircle + " Startup", false))
                Reset(Category::Startup);
            Util::HoverTooltip("click to reset section to defaults");
            refreshMaps  = UI::Checkbox("Refresh map list", refreshMaps);
            rememberOpen = UI::Checkbox("Remember if window was open", rememberOpen);

            UI::Separator();
            if (UI::Selectable("\\$2F3" + Icons::MapO + " My Maps List", false))
                Reset(Category::MyMapsList);
            Util::HoverTooltip("click to reset section to defaults");
            myMapsListHint           = UI::Checkbox("Show help text", myMapsListHint);
            maxMaps                  = UI::InputInt("Total maps to get (-1 means all)", maxMaps);
            myMapsListThumbnails     = UI::Checkbox("Show thumbnails", myMapsListThumbnails);
            UI::BeginDisabled(!myMapsListThumbnails);
            myMapsListThumbWidth     = UI::SliderInt("Thumbnail size##thumbList", myMapsListThumbWidth, 10, 150);
            UI::EndDisabled();
            myMapsListColor          = UI::Checkbox("Show map names with color##colorList", myMapsListColor);
            myMapsListColRecords     = UI::Checkbox("Show number of records", myMapsListColRecords);
            myMapsListColRecordsTime = UI::Checkbox("Show latest record update time", myMapsListColRecordsTime);
            myMapsListColUpload      = UI::Checkbox("Show latest map upload time", myMapsListColUpload);

            UI::Separator();
            if (UI::Selectable("\\$2F3" + Icons::Map + " My Map Tabs", false))
                Reset(Category::MyMapsTabs);
            Util::HoverTooltip("click to reset section to defaults");
            myMapsTabsColor         = UI::Checkbox("Show map names with color##colorTab", myMapsTabsColor);
            myMapsSwitchOnClicked   = UI::Checkbox("Switch to map when clicked", myMapsSwitchOnClicked);
            mapRecordsMedalColors   = UI::Checkbox("Show map record times with medal colors", mapRecordsMedalColors);
            myMapsCurrentThumbWidth = UI::SliderInt("Thumbnail size##thumbTab", myMapsCurrentThumbWidth, 10, 1000);
            maxRecordsPerMap        = UI::SliderInt("Max records to get per map", maxRecordsPerMap, 100, 1000);

            UI::Separator();
            if (UI::Selectable("\\$2F3" + Icons::Trophy + " Records", false))
                Reset(Category::Records);
            Util::HoverTooltip("click to reset section to defaults");
            recordsEstimate       = UI::Checkbox("Show time estimate", recordsEstimate);
            recordsMedalColors    = UI::Checkbox("Show record times with medal colors", recordsMedalColors);
            recordsHighlight5     = UI::Checkbox("Highlight top 5 world", recordsHighlight5);
            UI::BeginDisabled(!recordsHighlight5);
            recordsHighlightColor = UI::InputText("Highlight color", recordsHighlightColor, false, UI::InputTextFlags::CharsHexadecimal | UI::InputTextFlags::CharsUppercase);
            if (recordsHighlightColor.Length > 3)
                recordsHighlightColor = recordsHighlightColor.SubStr(0, 3);
            UI::EndDisabled();
        UI::EndGroup();
    }

    void Window_Settings() {
        if (!settingsWindow) {
            if (save) {
                Meta::SaveSettings();
                save = false;
            }
            return;
        }

        save = true;

        int flags = UI::WindowFlags::None;
        if (settingsResize)
            flags |= UI::WindowFlags::AlwaysAutoResize;

        UI::Begin("TMTracker Settings", settingsWindow, flags);
            Group_Settings();
        UI::End();
    }
}