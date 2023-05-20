/*
c 2023-05-14
m 2023-05-19
*/

void Main() {
    if (Settings::loadMyMapsOnBoot)
        DB::MyMaps::Load();

    if (Settings::loadZonesOnBoot)
        Zones::Load();

    IO::CreateFolder(Storage::thumbnailFolder);
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

            if (UI::Button(Icons::Refresh + " Refresh Map List (" + Storage::myMaps.Length + ")"))
                Maps::GetMyMaps();

            UI::SameLine();
            if (UI::Button(Icons::CloudDownload + " Get All Thumbnails"))
                startnew(CoroutineFunc(Maps::GetMyMapsThumbnailsCoro));

            UI::SameLine();
            if (UI::Button(Icons::Upload + " Load All Thumbnails"))
                startnew(CoroutineFunc(Maps::LoadMyMapsThumbnailsCoro));

            UI::SameLine();
            if (UI::Button(Icons::Upload))
                DB::MyMaps::Load();

            UI::SameLine();
            if (UI::Button(Icons::FloppyO))
                DB::MyMaps::Save();

            if (UI::Button(Icons::Bomb + " Nuke My Maps"))
                DB::MyMaps::Nuke();

            if (Storage::myMapsHidden.Length > 0) {
                UI::SameLine();
                if (UI::Button("Show Hidden (" + Storage::myMapsHidden.Length + ")")) {
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
                if (UI::Button("Clear Hidden UIDs"))
                    Storage::ClearMyMapsHiddenUIDs();
            }

            if (Storage::currentMap.Length > 0) {
                UI::SameLine();
                if (UI::Button("Clear Current Map"))
                    Storage::ClearCurrentMap();
            }

            UI::Separator();

            bool mapClicked = false;

            UI::BeginTabBar("MyMapsTabs");
            if (UI::BeginTabItem("Map List")) {
                for (uint i = 0; i < Storage::myMaps.Length; i++) {
                    try {
                        UI::Image(Storage::myMaps[i].thumbnailTexture, vec2(50, 50));
                    } catch {
                        UI::Image(Storage::defaultTexture, vec2(50, 50));
                    }
                    UI::SameLine();
                    if (UI::Button(Storage::myMaps[i].timestamp + " " + Storage::myMaps[i].mapNameText)) {
                        Storage::currentMap.RemoveRange(0, Storage::currentMap.Length);
                        Storage::currentMap.InsertAt(0, Storage::myMaps[i]);
                        startnew(CoroutineFunc(Storage::currentMap[0].LoadThumbnailCoro));
                        mapClicked = true;
                    }
                }
                UI::EndTabItem();
            }

            if (Storage::currentMap.Length > 0) {
                auto map = Storage::currentMap[0];

                if (!Storage::mapTabOpen)
                    Storage::ClearCurrentMap();

                uint flags = UI::TabItemFlags::None;
                if (mapClicked) {
                    flags = UI::TabItemFlags::SetSelected;
                    mapClicked = false;
                }
                if (UI::BeginTabItem(Icons::Map + " " + map.mapNameColor, Storage::mapTabOpen, flags)) {
                    try { UI::Image(map.thumbnailTexture, vec2(300, 300)); } catch { }
                    if (map.hidden) {
                        if (UI::Button(Icons::Eye + " Unhide This Map")) {
                            Storage::currentMap[0].hidden = false;
                            DB::MyMaps::UnHide(map);
                        }
                    } else {
                        if (UI::Button(Icons::EyeSlash + " Hide This Map")) {
                            Storage::currentMap[0].hidden = true;
                            DB::MyMaps::Hide(map);
                        }
                    }

                    UI::Text(map.mapNameText);
                    UI::Text(map.mapNameColor);
                    UI::Text("" + map.timestamp);
                    UI::Text("" + map.authorTime);
                    UI::Text("" + map.goldTime);
                    UI::Text("" + map.silverTime);
                    UI::Text("" + map.bronzeTime);
                    UI::EndTabItem();
                }
            }
            UI::EndTabBar();
            UI::EndTabItem();
        }

        UI::EndTabBar();
		UI::End();
    }
}