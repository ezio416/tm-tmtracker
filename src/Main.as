// c 2023-05-14
// m 2023-12-27

void RenderMenu() {
    if (UI::MenuItem(Globals::title, "", Settings::windowOpen))
        Settings::windowOpen = !Settings::windowOpen;
}

void Main() {
    Globals::myAccountId = GetApp().LocalPlayerInfo.WebServicesUserId;
    Globals::SetColors();

    if (!Settings::rememberOpen)
        Settings::windowOpen = false;

    NadeoServices::AddAudience(Globals::apiCore);
    NadeoServices::AddAudience(Globals::apiLive);

    IO::CreateFolder(Files::thumbnailFolder);

    if (Version::CheckFile()) {
        startnew(Database::LoadAccountsCoro);

        Files::LoadHiddenMaps();
        Files::LoadRecordsTimestamps();
    }

    if (Settings::refreshMaps)
        startnew(Bulk::GetMyMapsCoro);
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
            UI::Text("Welcome to TMTracker!\nAll timestamps are shown in your local time.\nCheck out these tabs to see what the plugin offers:");

        UI::BeginTabBar("tabs");
            Tabs::Tab_MyMaps();
            Tabs::Tab_MyRecords();
            if (Settings::infoTab)
                Tabs::Tab_Info();
#if SIG_DEVELOPER
            if (Settings::debugTab)
                Tabs::Tab_Debug();
            // Tabs::Tab_Test();
#endif
        UI::EndTabBar();
    UI::End();
}

void OnSettingsChanged() {
    Globals::SetColors();

    if (Settings::maxMaps > 10000)
        Settings::maxMaps = 10000;
}