/*
c 2023-07-16
m 2023-08-07
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

        if (UI::BeginChild("settings")) {
            UI::Separator();
            Settings::Group_Settings();
            UI::EndChild();
        }

        UI::EndTabItem();
    }
}

namespace Settings {
    void Group_Settings() {
        UI::BeginGroup();
            UI::Text("\\$2F3" + Icons::Cogs + " General");
            statusBar = UI::Checkbox("Show status bar", statusBar);
            welcomeText = UI::Checkbox("Show welcome text", welcomeText);
            infoTab = UI::Checkbox("Show info tab", infoTab);
            accountNameValidDays = UI::SliderInt("Account name valid time (days)", accountNameValidDays, 0, 60);

            UI::Separator();
            UI::Text("\\$2F3" + Icons::PlayCircle + " Startup");
            rememberOpen = UI::Checkbox("Remember if window was open", rememberOpen);

            UI::Separator();
            UI::Text("\\$2F3" + Icons::MapO + " My Maps");
            myMapsListHint = UI::Checkbox("Show help text", myMapsListHint);
            myMapsListColor = UI::Checkbox("Show map names with color", myMapsListColor);
            myMapsListThumbWidth = UI::SliderInt("Thumbnail size (list)", myMapsListThumbWidth, 10, 1000);

            UI::Separator();
            UI::Text("\\$2F3" + Icons::Map + " My Map Tabs");
            myMapsTabsColor = UI::Checkbox("Show map names with color (tab label)", myMapsTabsColor);
            myMapsSwitchOnClicked = UI::Checkbox("Switch to map when clicked", myMapsSwitchOnClicked);
            mapRecordsMedalColors = UI::Checkbox("Show map record times with medal colors", mapRecordsMedalColors);
            myMapsCurrentThumbWidth = UI::SliderInt("Thumbnail size (tab)", myMapsCurrentThumbWidth, 10, 1000);
            maxRecordsPerMap = UI::SliderInt("Max records to get per map", maxRecordsPerMap, 100, 1000);

            UI::Separator();
            UI::Text("\\$2F3" + Icons::Trophy + " Records");
            recordsEstimate = UI::Checkbox("Show time estimate", recordsEstimate);
            recordsMedalColors = UI::Checkbox("Show record times with medal colors", recordsMedalColors);
            recordsHighlight5 = UI::Checkbox("Highlight top 5 world", recordsHighlight5);
            recordsHighlightColor = UI::InputText("Highlight color", recordsHighlightColor, false);
        UI::EndGroup();
    }

    void Window_Settings() {
        if (!settingsWindow) return;

        int flags = UI::WindowFlags::None;
        if (settingsResize) flags |= UI::WindowFlags::AlwaysAutoResize;

        UI::Begin("TMTracker Settings", settingsWindow, flags);
            Group_Settings();
        UI::End();
    }

    [Setting hidden] uint   accountNameValidDays = 7;
    [Setting hidden] bool   infoTab = true;
    [Setting hidden] bool   mapRecordsMedalColors = true;
    [Setting hidden] uint   maxRecordsPerMap = 100;
    [Setting hidden] uint   myMapsCurrentThumbWidth = 400;
    [Setting hidden] bool   myMapsListHint = true;
    [Setting hidden] bool   myMapsListColor = true;
    [Setting hidden] uint   myMapsListThumbWidth = 200;
    [Setting hidden] bool   myMapsSwitchOnClicked = true;
    [Setting hidden] bool   myMapsTabsColor = true;
    [Setting hidden] bool   recordsEstimate = true;
    [Setting hidden] bool   recordsHighlight5 = true;
    [Setting hidden] string recordsHighlightColor = "F71";
    [Setting hidden] bool   recordsMedalColors = true;
    [Setting hidden] bool   rememberOpen = false;
    [Setting hidden] bool   settingsResize = true;
    [Setting hidden] bool   statusBar = true;
    [Setting hidden] bool   welcomeText = true;

    [Setting hidden] string dateFormat = "\\$AAA%a \\$G%Y-%m-%d %H:%M:%S \\$AAA";
    [Setting hidden] bool   debugHidden = true;
    [Setting hidden] bool   settingsWindow = false;
    [Setting hidden] uint   timeBetweenNadeoRequests = 500;
    [Setting hidden] bool   windowOpen = false;
}