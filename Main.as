/*
c 2023-05-14
m 2023-10-11
*/

void RenderMenu() {
    if (UI::MenuItem(Globals::title, "", Settings::windowOpen))
        Settings::windowOpen = !Settings::windowOpen;
}

void Main() {
    Globals::myAccountId = GetApp().LocalPlayerInfo.WebServicesUserId;

    if (!Settings::rememberOpen)
        Settings::windowOpen = false;

    NadeoServices::AddAudience(Globals::apiCore);
    NadeoServices::AddAudience(Globals::apiLive);

    Zones::Load();

    IO::CreateFolder(Files::thumbnailFolder);

    if (Version::CheckFile()) {
        startnew(CoroutineFunc(Database::LoadAccountsCoro));

        string timerId = Log::TimerBegin("loading hiddenMaps.json");
        if (IO::FileExists(Files::hiddenMaps)) {
            try {
                Globals::hiddenMapsJson = Json::FromFile(Files::hiddenMaps);
            } catch {
                Log::Write(Log::Level::Errors, "error loading hiddenMaps.json! " + getExceptionInfo());
            }
        } else {
            Log::Write(Log::Level::Warnings, "file not found: hiddenMaps.json");
        }
        Log::TimerEnd(timerId);

        timerId = Log::TimerBegin("loading mapRecordsTimestamps.json");
        if (IO::FileExists(Files::mapRecordsTimestamps)) {
            try {
                Globals::recordsTimestampsJson = Json::FromFile(Files::mapRecordsTimestamps);
            } catch {
                Log::Write(Log::Level::Errors, "error loading mapRecordsTimestamps.json! " + getExceptionInfo());
            }
        } else {
            Log::Write(Log::Level::Warnings, "file not found: mapRecordsTimestamps.json");
        }
        Log::TimerEnd(timerId);
    }

    if (Settings::refreshMaps)
        startnew(CoroutineFunc(Bulk::GetMyMapsCoro));

#if SIG_DEVELOPER
    Globals::debugTab = true;
#endif
}

void RenderInterface() {
    if (!Settings::windowOpen)
        return;

    UI::SetNextWindowSize(600, 540, UI::Cond::FirstUseEver);
    UI::SetNextWindowPos(300, 300, UI::Cond::FirstUseEver);

    int flags = 0;
    if (Settings::statusBar)
        flags |= UI::WindowFlags::MenuBar;

    UI::Begin(Globals::title, Settings::windowOpen, flags);
        if (Settings::statusBar && UI::BeginMenuBar()) {
            UI::Text("v" + Version::version.x + "." + Version::version.y + "." + Version::version.z + "   |");

            string[]@ keys = Globals::status.GetKeys();
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
            if (Settings::infoTab)
                Tabs::Tab_Info();
            if (Globals::debugTab)
                Tabs::Tab_Debug();
            // Tabs::Tab_Test();
        UI::EndTabBar();
    UI::End();
}

// void OnSettingsChanged() {
//     // highlight color vec4 to string
// }