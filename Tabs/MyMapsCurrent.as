/*
c 2023-05-26
m 2023-06-13
*/

// Functions for rendering tabs in the interface
namespace Tabs {
    void MyMapsCurrent() {
        for (uint i = 0; i < Globals::currentMaps.Length; i++) {
            uint flags = UI::TabItemFlags::Trailing;
            if (
                Globals::mapClicked &&
                Settings::myMapsSwitchOnClicked &&
                i == Globals::currentMaps.Length - 1
            ) {
                flags |= UI::TabItemFlags::SetSelected;
                Globals::mapClicked = false;
            }

            auto map = Globals::currentMaps[i];

            if (UI::BeginTabItem(Settings::myMapsTabsColor ? map.mapNameColor : map.mapNameText, map.viewing, flags)) {
                UI::BeginGroup();
                    auto thumbSize = vec2(Settings::myMapsThumbnailWidthTabs, Settings::myMapsThumbnailWidthTabs);
                    try   { UI::Image(map.thumbnailTexture, thumbSize); }
                    catch { UI::Image(Globals::defaultTexture, thumbSize); }

                    UI::BeginGroup();
                        UI::Text(map.mapNameText);
                        UI::Text(Time::FormatStringUTC(Settings::dateFormat + "UTC", map.timestamp));
                        UI::Text(Time::FormatString(Settings::dateFormat + "Local", map.timestamp));
                        UI::Text("\\$4B0" + Icons::Circle + " " + Time::Format(map.authorTime));
                        UI::Text("\\$DD1" + Icons::Circle + " " + Time::Format(map.goldTime));
                        UI::Text("\\$AAA" + Icons::Circle + " " + Time::Format(map.silverTime));
                        UI::Text("\\$C80" + Icons::Circle + " " + Time::Format(map.bronzeTime));
                    UI::EndGroup();

                    if (map.hidden) {
                        if (UI::Button(Icons::Eye + " Show This Map (currently hidden)"))
                            DB::MyMaps::UnHide(map);
                    } else {
                        if (UI::Button(Icons::EyeSlash + " Hide This Map"))
                            DB::MyMaps::Hide(map);
                    }
                UI::EndGroup();

                UI::SameLine();
                UI::BeginGroup();
                    if (UI::Button(Icons::Download + " Get Records (" + map.records.Length + ")"))
                        startnew(CoroutineFunc(map.GetRecordsCoro));

                    UI::SameLine();
                    UI::Text(
                        "Last Updated: " + (
                            map.recordsTimestamp > 0 ?
                                Time::FormatString(Settings::dateFormat + "Local\\$Z", map.recordsTimestamp) +
                                    " (" + Util::FormatSeconds(Time::Stamp - map.recordsTimestamp) + " ago)" :
                                "not yet"
                        )
                    );

                    int flags =
                        UI::TableFlags::ScrollY;

                    if (UI::BeginTable("table_records", 4, flags)) {
                        UI::TableSetupScrollFreeze(0, 1);
                        UI::TableSetupColumn("Pos", UI::TableColumnFlags::WidthFixed, 30);
                        UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed, 100);
                        UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed, 300);
                        UI::TableSetupColumn("Zone");
                        UI::TableHeadersRow();

                        UI::ListClipper clipper(map.records.Length);
                        while (clipper.Step()) {
                            for (uint j = clipper.DisplayStart; j < clipper.DisplayEnd; j++) {
                                UI::TableNextRow();
                                UI::TableNextColumn();
                                UI::Text("" + map.records[j].position);
                                UI::TableNextColumn();
                                UI::Text(Time::Format(map.records[j].time));
                                UI::TableNextColumn();
                                string name;
                                Globals::accountIds.Get(map.records[j].accountId, name);
                                UI::Text(name);
                                UI::TableNextColumn();
                                UI::Text(map.records[j].zoneName);
                            }
                        }

                        UI::EndTable();
                    }
                UI::EndGroup();

                UI::EndTabItem();
            }

            if (!map.viewing) {
                Globals::currentMaps.RemoveAt(i);
                Globals::currentMapIds.Delete(map.mapId);
            }
        }
    }
}