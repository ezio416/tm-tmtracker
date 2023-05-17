/*
c 2023-05-14
m 2023-05-17
*/

void Main() {
    if (Settings::loadMyMapsOnBoot)
        DB::MyMaps::LoadAll();
    if (Settings::loadZonesOnBoot)
        Zones::Load();
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
            Maps::GetMyMaps();
            DB::MyMaps::SaveAll();
        }

        UI::SameLine();
        if (UI::Button(Icons::Upload, vec2(50, 50)))
            DB::MyMaps::LoadAll();

        UI::SameLine();
        if (UI::Button(Icons::FloppyO, vec2(50, 50)))
            DB::MyMaps::SaveAll();

        if (Storage::myMapsIgnoredUids.GetKeys().Length > 0) {
            UI::SameLine();
            if (UI::Button("clear uids", vec2(130, 50)))
                Storage::myMapsIgnoredUids.DeleteAll();
        }

        UI::Separator();

        for (uint i = 0; i < Storage::myMaps.Length; i++) {
            if (UI::Button(Storage::myMaps[i].timestamp + " " + Storage::myMaps[i].mapNameText)) {
                trace("ignoring my map: " + Storage::myMaps[i].mapNameText);
                DB::MyMaps::Ignore(Storage::myMaps[i]);
                break;
            }
        }

		UI::End();
    }
}