/*
c 2023-05-14
m 2023-05-18
*/

void Main() {
    if (Settings::loadMyMapsOnBoot)
        DB::MyMaps::Load();

    if (Settings::loadZonesOnBoot)
        Zones::Load();
}

void RenderMenu() {
	if (UI::MenuItem(Storage::title, "", Settings::windowOpen))
		Settings::windowOpen = !Settings::windowOpen;
}

void RenderInterface() {
    if (Settings::windowOpen) {
        if (Settings::DetectSortMapsNewest())
            DB::MyMaps::Load();

        UI::SetNextWindowSize(600, 800, UI::Cond::Once);
		UI::SetNextWindowPos(100, 100, UI::Cond::Once);
		UI::Begin(Storage::title, Settings::windowOpen);

        UI::BeginTabBar("tabs");
        if (UI::BeginTabItem("My Maps")) {
            UI::Text(
                "Lorem Ipsum is simply dummy text of the printing and typesetting industry.\n" +
                "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s,\n" +
                "when an unknown printer took a galley of type and scrambled it to make a type\n" +
                "specimen book. It has survived not only five centuries, but also the leap into\n" +
                "electronic typesetting, remaining essentially unchanged."
            );

            UI::Separator();

            if (UI::Button(Icons::Refresh + " Refresh Map List (" + Storage::myMaps.Length + ")", vec2(260, 50)))
                Maps::GetMyMaps();

            UI::SameLine();
            if (UI::Button(Icons::Upload, vec2(50, 50)))
                DB::MyMaps::Load();

            UI::SameLine();
            if (UI::Button(Icons::FloppyO, vec2(50, 50)))
                DB::MyMaps::Save();

            if (UI::Button(Icons::Bomb + " Nuke My Maps", vec2(200, 50)))
                DB::MyMaps::Nuke();

            if (Storage::myMapsHidden.Length > 0) {
                UI::SameLine();
                if (UI::Button("Show Hidden (" + Storage::myMapsHidden.Length + ")", vec2(200, 50))) {
                    auto now = Time::Now;
                    for (uint i = 0; i < Storage::myMapsHidden.Length; i++)
                        DB::MyMaps::UnHide(Storage::myMapsHidden[i]);
                    if (Settings::printDurations)
                        trace("unhiding all maps took " + (Time::Now - now) + " ms");
                    DB::MyMaps::Load();
                }
            }

            if (Storage::myMapsHiddenUids.GetKeys().Length > 0) {
                UI::SameLine();
                if (UI::Button("Clear UIDs", vec2(130, 50)))
                    Storage::myMapsHiddenUids.DeleteAll();
            }

            UI::Separator();

            UI::BeginTabBar("MyMapsTabs");
            if (UI::BeginTabItem("Map List")) {
                for (uint i = 0; i < Storage::myMaps.Length; i++) {
                    if (UI::Button(Storage::myMaps[i].timestamp + " " + Storage::myMaps[i].mapNameText)) {
                        DB::MyMaps::Hide(Storage::myMaps[i]);
                        break;
                    }
                }
                UI::EndTabItem();
            }
            UI::EndTabBar();

            UI::EndTabItem();
        }

        UI::EndTabBar();
		UI::End();
    }
}