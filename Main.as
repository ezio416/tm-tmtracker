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

            UI::SameLine();
            if (UI::Button(Icons::Bomb + " Nuke My Maps"))
                DB::MyMaps::Nuke();

            if (Storage::currentMaps.Length > 0) {
                UI::SameLine();
                if (UI::Button("Clear Current Maps"))
                    Storage::ClearCurrentMaps();
            }

            UI::Separator();

            bool mapClicked = false;

            UI::BeginTabBar("MyMapsTabs");
            if (UI::BeginTabItem("Map List")) {
                uint currentX = 0;
                auto size = UI::GetWindowSize();

                for (uint i = 0; i < Storage::myMaps.Length; i++) {
                    auto map = Storage::myMaps[i];

                    if (i > 0 && currentX + Settings::myMapsThumbnailWidthList < size.x)
                        UI::SameLine();

                    UI::BeginGroup();
                    auto thumbSize = vec2(Settings::myMapsThumbnailWidthList, Settings::myMapsThumbnailWidthList);
                    auto pos = UI::GetCursorPos();
                    try {
                        UI::Image(map.thumbnailTexture, thumbSize);
                    } catch {
                        UI::Image(Storage::defaultTexture, thumbSize);
                    }
                    UI::SetCursorPos(pos);

                    if (UI::InvisibleButton("invis_" + map.mapUid, thumbSize)) {
                        if (!Storage::currentMapsUids.Exists(map.mapUid)) {
                            Storage::currentMapsUids.Set(map.mapUid, "");
                            Storage::currentMaps.InsertLast(map);
                        }
                        mapClicked = true;
                    }

                    currentX = UI::GetCursorPos().x + Settings::myMapsThumbnailWidthList + 44;
                    UI::PushTextWrapPos(currentX - 44);  // this wrapping works on 1.5x scaling at 4K
                    UI::Text(map.mapNameColor);
                    UI::PopTextWrapPos();
                    UI::EndGroup();
                }

                UI::EndTabItem();
            }

            if (Storage::currentMaps.Length > 0) {
                for (uint i = 0; i < Storage::currentMaps.Length; i++) {
                    auto map = Storage::currentMaps[i];

                    uint flags = UI::TabItemFlags::Trailing;
                    if (
                        mapClicked &&
                        Settings::myMapsSwitchOnClicked &&
                        i == Storage::currentMaps.Length - 1
                    ) {
                        flags |= UI::TabItemFlags::SetSelected;
                        mapClicked = false;
                    }

                    if (UI::BeginTabItem(Icons::Map + " " + map.mapNameColor, Storage::currentMaps[i].viewing, flags)) {
                        auto thumbSize = vec2(Settings::myMapsThumbnailWidthPage, Settings::myMapsThumbnailWidthPage);
                        try {
                            UI::Image(map.thumbnailTexture, thumbSize);
                        } catch {
                            UI::Image(Storage::defaultTexture, thumbSize);
                        }

                        if (map.hidden) {
                            if (UI::Button(Icons::Eye + " Unhide This Map")) {
                                Storage::currentMaps[0].hidden = false;
                                DB::MyMaps::UnHide(map);
                            }
                        } else {
                            if (UI::Button(Icons::EyeSlash + " Hide This Map")) {
                                Storage::currentMaps[0].hidden = true;
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

                    if (!Storage::currentMaps[i].viewing) {
                        Storage::currentMaps.RemoveAt(i);
                        Storage::currentMapsUids.Delete(map.mapUid);
                    }
                }
            }
            UI::EndTabBar();
            UI::EndTabItem();
        }
        UI::EndTabBar();
		UI::End();
    }
}