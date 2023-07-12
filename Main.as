/*
c 2023-05-14
m 2023-07-12
*/

void Main() {
    if (!Settings::rememberOpen)
        Settings::windowOpen = false;

#if SIG_DEVELOPER
    Globals::debug = !Settings::debugHidden;
#endif

    Zones::Load();

    try { Globals::hiddenMapsIndex = Util::JsonLoadToDict(Globals::hiddenMapsFile); } catch { }

    IO::CreateFolder(Globals::thumbnailFolder);

    NadeoServices::AddAudience("NadeoServices");
    NadeoServices::AddAudience("NadeoLiveServices");

    if (Settings::startupMyMaps)
        startnew(CoroutineFunc(Bulk::GetMyMapsCoro));
}

void OnSettingsChanged() {
    uint tmp = 3 - Settings::recordsHighlightColor.Length;
    for (uint i = 0; i < tmp; i++)
        Settings::recordsHighlightColor += "0";
}

void RenderMenu() {
	if (UI::MenuItem(Globals::title, "", Settings::windowOpen))
		Settings::windowOpen = !Settings::windowOpen;
}

void RenderInterface() {
    if (!Settings::windowOpen) return;

    UI::SetNextWindowSize(600, 540, UI::Cond::FirstUseEver);
    UI::SetNextWindowPos(300, 300, UI::Cond::FirstUseEver);

    uint flags = 0;
    if (Settings::statusBar)
        flags |= UI::WindowFlags::MenuBar;

    UI::Begin(Globals::title, Settings::windowOpen, flags);
        if (Settings::statusBar && UI::BeginMenuBar()) {
            UI::Text("v3.0.0   |");
            auto keys = Globals::status.GetKeys();
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
            if (Settings::infoTab) Tabs::Tab_Info();
            if (Globals::debug)    Tabs::Tab_Debug();
        UI::EndTabBar();
    UI::End();
}