/*
c 2023-05-14
m 2023-07-06
*/

void Main() {
    if (!Settings::rememberOpen)
        Settings::windowOpen = false;

#if SIG_DEVELOPER
    if (!Settings::devHiddenByUser)
        Globals::dev = !Settings::devHidden;
#endif

    Zones::Load();

    IO::CreateFolder(Globals::thumbnailFolder);

    NadeoServices::AddAudience("NadeoLiveServices");

    // auto mapLoadCoro = startnew(CoroutineFunc(DB::MyMaps::LoadCoro));
    // while (mapLoadCoro.IsRunning()) yield();
    // auto recLoadCoro = startnew(CoroutineFunc(DB::Records::LoadCoro));
    // while (recLoadCoro.IsRunning()) yield();
    // auto accLoadCoro = startnew(CoroutineFunc(DB::AllAccounts::LoadCoro));
    // while (accLoadCoro.IsRunning()) yield();
}

void RenderMenu() {
	if (UI::MenuItem(Globals::title, "", Settings::windowOpen))
		Settings::windowOpen = !Settings::windowOpen;
}

void RenderInterface() {
    if (!Settings::windowOpen) return;

    UI::SetNextWindowSize(600, 540, UI::Cond::FirstUseEver);
    UI::SetNextWindowPos(300, 300, UI::Cond::FirstUseEver);

    UI::Begin(Globals::title, Settings::windowOpen);
        if (Settings::welcomeText)
            UI::Text("Welcome to TMTracker! Check out these tabs to see what the plugin offers:");
        RenderTabs();
    UI::End();
}

void RenderTabs() {
    UI::BeginTabBar("tabs");
        Tabs::Tab_MyMaps();
        if (Settings::infoTab) Tabs::Tab_Info();
        if (Globals::dev)      Tabs::Tab_Dev();
    UI::EndTabBar();
}