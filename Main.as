/*
c 2023-05-14
m 2023-05-20
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

void RenderMapListTab() {
    if (UI::BeginTabItem(Icons::Map + " Map List " + Icons::Map)) {
        uint currentX = 0;
        auto size = UI::GetWindowSize();

        for (uint i = 0; i < Storage::myMaps.Length; i++) {
            auto map = Storage::myMaps[i];

            currentX += Settings::myMapsThumbnailWidthList;
            if (i > 0 && currentX < size.x)
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
                    Storage::mapClicked = true;
                }

                currentX = UI::GetCursorPos().x + Settings::myMapsThumbnailWidthList + 44;
                UI::PushTextWrapPos(currentX - 44);  // 44 pixels for scrollbar works on 1.5x scaling at 4K
                if (Settings::myMapsListColor)
                    UI::Text(map.mapNameColor);
                else
                    UI::Text(map.mapNameText);
                UI::PopTextWrapPos();
            UI::EndGroup();
        }

        UI::EndTabItem();
    }
}

void RenderMapsTabs() {
    for (uint i = 0; i < Storage::currentMaps.Length; i++) {
        auto map = Storage::currentMaps[i];

        uint flags = UI::TabItemFlags::Trailing;
        if (
            Storage::mapClicked &&
            Settings::myMapsSwitchOnClicked &&
            i == Storage::currentMaps.Length - 1
        ) {
            flags |= UI::TabItemFlags::SetSelected;
            Storage::mapClicked = false;
        }

        string tabTitle = Settings::myMapsTabsColor ? map.mapNameColor : map.mapNameText;
        if (UI::BeginTabItem(tabTitle, Storage::currentMaps[i].viewing, flags)) {
            auto thumbSize = vec2(Settings::myMapsThumbnailWidthTabs, Settings::myMapsThumbnailWidthTabs);
            try {
                UI::Image(map.thumbnailTexture, thumbSize);
            } catch {
                UI::Image(Storage::defaultTexture, thumbSize);
            }

            if (map.hidden) {
                if (UI::Button(Icons::Eye + " Show This Map (currently hidden)")) {
                    Storage::currentMaps[i].hidden = false;
                    DB::MyMaps::UnHide(map);
                }
            } else {
                if (UI::Button(Icons::EyeSlash + " Hide This Map")) {
                    Storage::currentMaps[i].hidden = true;
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

void RenderTabs() {
    UI::BeginTabBar("tabs");
        if (UI::BeginTabItem("My Maps")) {
            UI::TextWrapped(
                "Once you've updated your maps, click on a thumbnail to open a tab for that map. " +
                "Close tabs with the 'X' or with a middle click."
            );

            if (UI::Button(Icons::Refresh + " Update Map List (" + Storage::myMaps.Length + ")"))
                startnew(CoroutineFunc(Maps::GetMyMapsCoro));

            uint totalMaps = Storage::myMaps.Length + Storage::myMapsHidden.Length;
            if (totalMaps > 0) {
                UI::SameLine();
                if (UI::Button(Icons::Bomb + " Nuke (" + totalMaps + ")"))
                    DB::MyMaps::Nuke();
            }

            if (Storage::myMapsHidden.Length > 0) {
                UI::SameLine();
                if (UI::Button(Icons::Eye + " Show Hidden (" + Storage::myMapsHidden.Length + ")")) {
                    auto now = Time::Now;

                    for (uint i = 0; i < Storage::myMapsHidden.Length;)
                        DB::MyMaps::UnHide(Storage::myMapsHidden[i]);

                    for (uint i = 0; i < Storage::currentMaps.Length; i++)
                        Storage::currentMaps[i].hidden = false;

                    if (Settings::printDurations)
                        trace("unhiding all maps took " + (Time::Now - now) + " ms");

                    DB::MyMaps::Load();
                }
            }

            if (Storage::currentMaps.Length > 0) {
                UI::SameLine();
                if (UI::Button(Icons::Times + " Clear Current Maps (" + Storage::currentMaps.Length + ")")) {
                    Storage::ClearCurrentMaps();
                    Storage::ClearCurrentMapsUids();
                }
            }

            UI::Separator();

            Storage::mapClicked = false;

            UI::BeginTabBar("MyMapsTabs");
            RenderMapListTab();
            if (Storage::currentMaps.Length > 0)
                RenderMapsTabs();
            UI::EndTabBar();
            UI::EndTabItem();
        }
        UI::EndTabBar();
}

void RenderInterface() {
    if (Settings::windowOpen) {
        if (Settings::DetectSortMapsNewest())
            DB::MyMaps::Load();

        UI::SetNextWindowSize(600, 800, UI::Cond::Once);
		UI::SetNextWindowPos(100, 100, UI::Cond::Once);

		UI::Begin(Storage::title, Settings::windowOpen);
            UI::Text("Welcome to TMTracker! Check out these tabs to see what I can do:");
            RenderTabs();
		UI::End();
    }
}