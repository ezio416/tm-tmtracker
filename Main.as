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
            if (i > 0 && currentX < uint(size.x))
                UI::SameLine();

            UI::BeginGroup();
                auto pos = UI::GetCursorPos();
                auto thumbSize = vec2(Settings::myMapsThumbnailWidthList, Settings::myMapsThumbnailWidthList);
                try   { UI::Image(map.thumbnailTexture, thumbSize); }
                catch { UI::Image(Storage::defaultTexture, thumbSize); }

                UI::SetCursorPos(pos);
                if (UI::InvisibleButton("invis_" + map.mapUid, thumbSize)) {
                    if (!Storage::currentMapsUids.Exists(map.mapUid)) {
                        Storage::currentMapsUids.Set(map.mapUid, "");
                        Storage::currentMaps.InsertLast(map);
                    }
                    Storage::mapClicked = true;
                }

                currentX = uint(UI::GetCursorPos().x) + Settings::myMapsThumbnailWidthList + 44;
                UI::PushTextWrapPos(currentX - 44);  // 44 pixels for scrollbar works on 1.5x scaling at 4K
                UI::Text((Settings::myMapsListColor) ? map.mapNameColor : map.mapNameText);
                UI::PopTextWrapPos();
                UI::Text("\n");
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
            try   { UI::Image(map.thumbnailTexture, thumbSize); }
            catch { UI::Image(Storage::defaultTexture, thumbSize); }

            UI::SameLine();
            UI::BeginGroup();
                UI::Text(map.mapNameText);
                UI::Text(Time::FormatStringUTC(Settings::dateFormat + "UTC", map.timestamp));
                UI::Text(Time::FormatString(Settings::dateFormat + "Local", map.timestamp));
                UI::Text("\\$4B0" + Icons::Circle + " " + Time::Format(map.authorTime));
                UI::Text("\\$DD1" + Icons::Circle + " " + Time::Format(map.goldTime));
                UI::Text("\\$AAA" + Icons::Circle + " " + Time::Format(map.silverTime));
                UI::Text("\\$C80" + Icons::Circle + " " + Time::Format(map.bronzeTime));
            UI::EndGroup();

            UI::SameLine();
            UI::BeginGroup();
                for (uint j = 0; j < map.records.Length; j++) {
                    UI::Text(
                        map.records[j].position  + " " + Time::Format(map.records[j].time) + "\n" +
                        map.records[j].accountId + "\n" +
                        map.records[j].zoneId    + "\n" +
                        map.records[j].zoneName
                    );
                }
            UI::EndGroup();

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

            if (UI::Button(Icons::Download + " Get Records"))
                startnew(CoroutineFunc(map.GetRecordsCoro));

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