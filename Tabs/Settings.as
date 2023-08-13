/*
c 2023-07-16
m 2023-08-12
*/

namespace Tabs {
    void Tab_Settings() {
        if (!UI::BeginTabItem(Icons::Cog + " Settings")) return;

        // UI::SameLine();
        // if (UI::Button(Icons::Refresh + " Reset all to defaults")) {
        //     Settings::Reset(Settings::Category::General);
        //     Settings::Reset(Settings::Category::Startup);
        //     Settings::Reset(Settings::Category::MyMapsList);
        //     Settings::Reset(Settings::Category::MyMapsTabs);
        //     Settings::Reset(Settings::Category::Records);
        // }

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
                plugin.GetSetting("accountNameValidDays").Reset();
                break;
            case Category::Startup:
                plugin.GetSetting("rememberOpen").Reset();
                break;
            case Category::MyMapsList:
                plugin.GetSetting("myMapsListHint").Reset();
                plugin.GetSetting("myMapsListColor").Reset();
                plugin.GetSetting("myMapsListThumbWidth").Reset();
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

            UI::Separator();

            if (UI::Selectable("\\$2F3" + Icons::Cogs + " General", false))
                Reset(Category::General);
            Util::HoverTooltip("click to reset section to defaults");
            statusBar = UI::Checkbox("Show status bar", statusBar);
            welcomeText = UI::Checkbox("Show welcome text", welcomeText);
            infoTab = UI::Checkbox("Show info tab", infoTab);
            accountNameValidDays = UI::SliderInt("Account name valid time (days)", accountNameValidDays, 0, 60);

            UI::Separator();
            if (UI::Selectable("\\$2F3" + Icons::PlayCircle + " Startup", false))
                Reset(Category::Startup);
            Util::HoverTooltip("click to reset section to defaults");
            rememberOpen = UI::Checkbox("Remember if window was open", rememberOpen);

            UI::Separator();
            if (UI::Selectable("\\$2F3" + Icons::MapO + " My Maps List", false))
                Reset(Category::MyMapsList);
            Util::HoverTooltip("click to reset section to defaults");
            myMapsListHint = UI::Checkbox("Show help text", myMapsListHint);
            myMapsListColor = UI::Checkbox("Show map names with color", myMapsListColor);
            myMapsListThumbWidth = UI::SliderInt("Thumbnail size (list)", myMapsListThumbWidth, 10, 1000);

            UI::Separator();
            if (UI::Selectable("\\$2F3" + Icons::Map + " My Map Tabs", false))
                Reset(Category::MyMapsTabs);
            Util::HoverTooltip("click to reset section to defaults");
            myMapsTabsColor = UI::Checkbox("Show map names with color (tab label)", myMapsTabsColor);
            myMapsSwitchOnClicked = UI::Checkbox("Switch to map when clicked", myMapsSwitchOnClicked);
            mapRecordsMedalColors = UI::Checkbox("Show map record times with medal colors", mapRecordsMedalColors);
            myMapsCurrentThumbWidth = UI::SliderInt("Thumbnail size (tab)", myMapsCurrentThumbWidth, 10, 1000);
            maxRecordsPerMap = UI::SliderInt("Max records to get per map", maxRecordsPerMap, 100, 1000);

            UI::Separator();
            if (UI::Selectable("\\$2F3" + Icons::Trophy + " Records", false))
                Reset(Category::Records);
            Util::HoverTooltip("click to reset section to defaults");
            recordsEstimate = UI::Checkbox("Show time estimate", recordsEstimate);
            recordsMedalColors = UI::Checkbox("Show record times with medal colors", recordsMedalColors);
            recordsHighlight5 = UI::Checkbox("Highlight top 5 world", recordsHighlight5);
            recordsHighlightColor = UI::InputText("Highlight color", recordsHighlightColor, false);
        UI::EndGroup();
    }

    void Window_Settings() {
        if (!settingsWindow) {
            if (Globals::saveSettings) {
                Meta::SaveSettings();
                Globals::saveSettings = false;
            }
            return;
        }

        Globals::saveSettings = true;

        int flags = UI::WindowFlags::None;
        if (settingsResize) flags |= UI::WindowFlags::AlwaysAutoResize;

        UI::Begin("TMTracker Settings", settingsWindow, flags);
            Group_Settings();
        UI::End();
    }

    [Setting hidden] uint   accountNameValidDays     = 7;
    [Setting hidden] bool   infoTab                  = true;
    [Setting hidden] bool   mapRecordsMedalColors    = true;
    [Setting hidden] uint   maxRecordsPerMap         = 100;
    [Setting hidden] uint   myMapsCurrentThumbWidth  = uint(Globals::scale * 200);
    [Setting hidden] bool   myMapsListHint           = true;
    [Setting hidden] bool   myMapsListColor          = true;
    [Setting hidden] uint   myMapsListThumbWidth     = uint(Globals::scale * 120);
    [Setting hidden] bool   myMapsSwitchOnClicked    = true;
    [Setting hidden] bool   myMapsTabsColor          = true;
    [Setting hidden] bool   recordsEstimate          = true;
    [Setting hidden] bool   recordsHighlight5        = true;
    [Setting hidden] string recordsHighlightColor    = "F71";
    [Setting hidden] bool   recordsMedalColors       = true;
    [Setting hidden] bool   rememberOpen             = false;
    [Setting hidden] bool   settingsResize           = true;
    [Setting hidden] bool   statusBar                = true;
    [Setting hidden] bool   welcomeText              = true;

    [Setting hidden] string dateFormat               = "\\$AAA%a \\$G%Y-%m-%d %H:%M:%S \\$AAA";
    [Setting hidden] bool   debugHidden              = true;
    [Setting hidden] bool   settingsWindow           = false;
    [Setting hidden] uint   timeBetweenNadeoRequests = 500;
    [Setting hidden] bool   windowOpen               = false;
}