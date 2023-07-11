/*
c 2023-05-26
m 2023-07-11
*/

namespace Tabs { namespace MyMaps {
    void Tabs_Current() {
        auto now = Time::Stamp;

        for (uint i = 0; i < Globals::currentMaps.Length; i++) {
            auto map = @Globals::currentMaps[i];

            int flags = UI::TabItemFlags::Trailing;
            if (
                Globals::clickedMapId == map.mapId &&
                Settings::myMapsSwitchOnClicked
            ) {
                flags |= UI::TabItemFlags::SetSelected;
                Globals::clickedMapId = "";
            }

            if (UI::BeginTabItem(Settings::myMapsTabsColor ? map.mapNameColor : map.mapNameText, map.viewing, flags)) {
                UI::BeginGroup();
                    auto thumbSize = vec2(Settings::myMapsCurrentThumbnailWidth, Settings::myMapsCurrentThumbnailWidth);
                    try   { UI::Image(map.thumbnailTexture, thumbSize); }
                    catch { UI::Image(Globals::defaultTexture, thumbSize); }

                    UI::BeginGroup();
                        UI::Text(map.mapNameText);
                        UI::Text("\\$4B0" + Icons::Circle + " " + Time::Format(map.authorTime));
                        UI::Text("\\$DD1" + Icons::Circle + " " + Time::Format(map.goldTime));
                        UI::Text("\\$AAA" + Icons::Circle + " " + Time::Format(map.silverTime));
                        UI::Text("\\$C80" + Icons::Circle + " " + Time::Format(map.bronzeTime));
                    UI::EndGroup();

                    if (map.hidden) {
                        if (UI::Button(Icons::Eye + " Show This Map (currently hidden)"))
                            Globals::ShowMap(map);
                    } else {
                        if (UI::Button(Icons::EyeSlash + " Hide This Map"))
                            Globals::HideMap(map);
                    }
                UI::EndGroup();

                UI::SameLine();
                UI::BeginGroup();
                    if (UI::Button(Icons::Download + " Get Records (" + map.records.Length + ")"))
                        startnew(CoroutineFunc(map.GetRecordsCoro));

                    UI::SameLine();
                    UI::Text("Last Updated: " + (
                        map.recordsTimestamp > 0 ?
                            Time::FormatString(Settings::dateFormat + "Local\\$G", map.recordsTimestamp) +
                                " (" + Util::FormatSeconds(now - map.recordsTimestamp) + " ago)" :
                            "not yet"
                    ));

                    if (UI::BeginTable("table_records", 5, UI::TableFlags::ScrollY)) {
                        UI::TableSetupScrollFreeze(0, 1);
                        UI::TableSetupColumn("Pos", UI::TableColumnFlags::WidthFixed, 30);
                        UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed, 100);
                        UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed, 300);
                        UI::TableSetupColumn("Timestamp", UI::TableColumnFlags::WidthFixed, 300);
                        UI::TableSetupColumn("Recency");
                        UI::TableHeadersRow();

                        UI::ListClipper clipper(map.records.Length);
                        while (clipper.Step()) {
                            for (int j = clipper.DisplayStart; j < clipper.DisplayEnd; j++) {
                                auto record = @map.records[j];
                                auto account = cast<Models::Account@>(Globals::accountsIndex[record.accountId]);

                                UI::TableNextRow();
                                UI::TableNextColumn();
                                UI::Text("" + record.position);
                                UI::TableNextColumn();
                                string timeColor = "";
                                if (Settings::recordMedalColors)
                                    switch (record.medals) {
                                        case 1: timeColor = "\\$C80"; break;
                                        case 2: timeColor = "\\$AAA"; break;
                                        case 3: timeColor = "\\$DD1"; break;
                                        case 4: timeColor = "\\$4B0"; break;
                                    }
                                UI::Text(timeColor + Time::Format(record.time));
                                UI::TableNextColumn();
                                UI::Text((account.accountName != "") ? account.accountName : account.accountId);
                                UI::TableNextColumn();
                                UI::Text(Time::FormatString("%Y-%m-%d %H:%M:%S \\$AAA(%a)", record.timestampUnix));
                                UI::TableNextColumn();
                                UI::Text(Util::FormatSeconds(now - record.timestampUnix));
                            }
                        }
                        UI::EndTable();
                    }
                UI::EndGroup();

                UI::EndTabItem();
            }

            if (!map.viewing) {
                Globals::currentMaps.RemoveAt(i);
                Globals::currentMapsIndex.Delete(map.mapId);
            }
        }
    }
}}