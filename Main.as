/*
c 2023-05-14
m 2023-05-16
*/

void Main() {
    if (Settings::loadMyMapsOnBoot)
        Core::LoadMaps();
}

void RenderMenu() {
	if (UI::MenuItem(Storage::title, "", Settings::windowOpen))
		Settings::windowOpen = !Settings::windowOpen;
}

void RenderInterface() {
    if (Settings::windowOpen) {
        UI::SetNextWindowSize(500, 300, UI::Cond::Once);
		UI::SetNextWindowPos(100, 100, UI::Cond::Once);
		UI::Begin(Storage::title, Settings::windowOpen);

        if (UI::Button(Icons::Refresh + " Refresh Map List", vec2(250, 50))) {
            print("refreshing map list...");
            Storage::maps = Core::GetMyMaps();
            Core::SaveMaps();
        }

        UI::SameLine();
        if (UI::Button(Icons::Refresh + " Refresh All Records", vec2(250, 50))) {
            print("refreshing all records...");

        }

        UI::SameLine();
        if (UI::Button(Icons::Upload, vec2(50, 50)))
            Core::LoadMaps();

        UI::SameLine();
        if (UI::Button(Icons::FloppyO, vec2(50, 50)))
            Core::SaveMaps();

        UI::Separator();

        for (uint i = 0; i < Storage::maps.Length; i++) {
            if (UI::Button(Storage::maps[i].mapNameText))
                print(Storage::maps[i].mapNameColor);
        }

		UI::End();
    }
}