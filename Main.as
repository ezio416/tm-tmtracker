/*
c 2023-05-14
m 2023-08-12
*/

void Main() {
    if (!Settings::rememberOpen)
        Settings::windowOpen = false;

#if SIG_DEVELOPER
    Globals::debug = !Settings::debugHidden;
#endif

    Zones::Load();

    string timerId = Util::LogTimerBegin("loading hiddenMaps.json");
    if (IO::FileExists(Globals::hiddenMapsFile)) {
        Globals::hiddenMapsIndex = Json::FromFile(Globals::hiddenMapsFile);
    } else {
        warn("hiddenMaps.json not found!");
    }
    Util::LogTimerEnd(timerId);

    timerId = Util::LogTimerBegin("loading mapRecordsTimestamps.json");
    if (IO::FileExists(Globals::mapRecordsTimestampsFile)) {
        Globals::recordsTimestampsIndex = Json::FromFile(Globals::mapRecordsTimestampsFile);
    } else {
        warn("mapRecordsTimestamps.json not found!");
    }
    Util::LogTimerEnd(timerId);

    IO::CreateFolder(Globals::thumbnailFolder);

    NadeoServices::AddAudience("NadeoServices");
    NadeoServices::AddAudience("NadeoLiveServices");

    startnew(CoroutineFunc(Database::LoadAccountsCoro));
    startnew(CoroutineFunc(Bulk::GetMyMapsCoro));
}

void RenderMenu() {
	if (UI::MenuItem(Globals::title, "", Settings::windowOpen))
		Settings::windowOpen = !Settings::windowOpen;
}

void RenderInterface() {
    if (!Settings::windowOpen) return;

    Settings::Window_Settings();

    UI::SetNextWindowSize(600, 540, UI::Cond::FirstUseEver);
    UI::SetNextWindowPos(300, 300, UI::Cond::FirstUseEver);

    int flags = 0;
    if (Settings::statusBar)
        flags |= UI::WindowFlags::MenuBar;

    UI::Begin(Globals::title, Settings::windowOpen, flags);
        if (Settings::statusBar && UI::BeginMenuBar()) {
            UI::Text("v3.0.0   |");
            string[] keys = Globals::status.GetKeys();
            if (keys.Length > 0) {
                for (uint i = 0; i < keys.Length; i++) {
                    string statusText;
                    if (Globals::status.Get(keys[i], statusText))
                        UI::Text(statusText);
                }
            } else {
                UI::Text("idle");
            }
            UI::EndMenuBar();
        }

        if (Settings::welcomeText)
            UI::Text("Welcome to TMTracker! Check out these tabs to see what the plugin offers:");

        UI::BeginTabBar("tabs");
            Tabs::Tab_Maps();
            Tabs::Tab_Records();
            Tabs::Tab_Settings();
            if (Settings::infoTab) Tabs::Tab_Info();
            if (Globals::debug)    Tabs::Tab_Debug();
        UI::EndTabBar();
    UI::End();
}