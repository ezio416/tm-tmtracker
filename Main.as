/*
c 2023-05-14
m 2023-05-16
*/

Models::Map[] maps;

void RenderMenu() {
	if (UI::MenuItem(Settings::title, "", Settings::windowOpen))
		Settings::windowOpen = !Settings::windowOpen;
}

void RenderInterface() {
    if (Settings::windowOpen) {
        UI::SetNextWindowSize(400, 600, UI::Cond::Once);
		UI::SetNextWindowPos(200, 200, UI::Cond::Once);
		UI::Begin(Settings::title, Settings::windowOpen);
        if (UI::Button("Refresh Map List", vec2(250, 50))) {
            print("clicked 1");
            maps = Core::GetMyMaps();
            print(maps.Length);
        }
        UI::SameLine();
        if (UI::Button("Refresh Records", vec2(250, 50))) {
            print("clicked 2");
        }
        UI::Separator();

        for (uint i = 0; i < maps.Length; i++) {
            UI::Button(maps[i].mapNameText);
        }

		UI::End();
    }
}