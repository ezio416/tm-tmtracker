/*
c 2023-05-26
m 2023-10-11
*/

namespace Tabs { namespace MyMaps {
    void Tab_MyMapsViewing() {
        if (!UI::BeginTabItem(Icons::Eye + " Viewing Maps (" + Globals::myMapsViewing.Length + ")###my-maps-viewing"))
            return;

        if (Settings::myMapsViewingText)
            UI::TextWrapped(
                "Close map tabs with a middle click or the " + Icons::Kenney::ButtonTimes +
                ".\nIf there are lots of maps here, use the dropdown arrow on the left or the left/right arrows on the right."
            );

        UI::BeginDisabled(Globals::myMapsViewing.Length == 0);
        if (UI::Button(Icons::Times + " Clear All"))
            Globals::ClearMyMapsViewing();
        UI::EndDisabled();

        int flags = UI::TabBarFlags::FittingPolicyScroll;
        if (Globals::myMapsViewing.Length > 0)
            flags |= UI::TabBarFlags::TabListPopupButton;

        UI::BeginTabBar("my-maps-viewing", flags);

        int64 now = Time::Stamp;

        for (uint i = 0; i < Globals::myMapsViewing.Length; i++) {
            Models::Map@ map = @Globals::myMapsViewing[i];

            if (UI::BeginTabItem((Settings::mapNameColors ? map.mapNameColor : map.mapNameText) + "###" + map.mapUid, map.viewing, UI::TabItemFlags::Trailing)) {
                UI::BeginGroup();
                    vec2 thumbSize = vec2(Settings::myMapsViewingThumbWidth, Settings::myMapsViewingThumbWidth);
                    try {
                        UI::Image(map.thumbnailTexture, thumbSize);
                    } catch {
                        UI::Dummy(thumbSize);
                    }

                    if (Settings::myMapsViewingLoadThumbs) {
                        startnew(CoroutineFunc(map.LoadThumbnailCoro));
                    } else if (!Locks::thumbs && map.thumbnailTexture is null && !map.thumbnailLoading) {
                        if (UI::Button(Icons::PictureO + " Load Thumbnail"))
                            startnew(CoroutineFunc(map.LoadThumbnailCoro));
                    }

                    UI::Text(map.mapNameText);
                    UI::Text(Globals::colorAuthor + Icons::Circle + " " + Time::Format(map.authorTime));
                    UI::Text(Globals::colorGold   + Icons::Circle + " " + Time::Format(map.goldTime));
                    UI::Text(Globals::colorSilver + Icons::Circle + " " + Time::Format(map.silverTime));
                    UI::Text(Globals::colorBronze + Icons::Circle + " " + Time::Format(map.bronzeTime));
                UI::EndGroup();

                UI::SameLine();
                UI::BeginGroup();
                    UI::BeginDisabled(Locks::playMap);
                    if (UI::Button(Icons::Play + " Play"))
                        startnew(CoroutineFunc(map.PlayCoro));
                    UI::EndDisabled();

                    UI::SameLine();
                    UI::BeginDisabled(Locks::editMap);
                    if (UI::Button(Icons::Pencil + " Edit"))
                        startnew(CoroutineFunc(map.EditCoro));
                    UI::EndDisabled();

                    UI::SameLine();
                    if (map.hidden) {
                        if (UI::Button(Icons::Eye + " Show"))
                            Globals::ShowMyMap(map);
                    } else {
                        if (UI::Button(Icons::EyeSlash + " Hide"))
                            Globals::HideMyMap(map);
                    }

                    UI::SameLine();
                    if (UI::Button(Icons::Heartbeat + " Trackmania.io"))
                        Util::TmioMap(map.mapUid);

                    UI::BeginDisabled(Locks::tmx);
                    UI::SameLine();
                    if (UI::Button(Icons::Exchange + " Trackmania.exchange"))
                        startnew(CoroutineFunc(map.TmxCoro));
                    UI::EndDisabled();

                    UI::BeginDisabled(map.hidden || Locks::singleRecords || Locks::allRecords);
                    if (UI::Button(Icons::Download + " Get Records (" + map.records.Length + ")"))
                        startnew(CoroutineFunc(map.GetRecordsCoro));
                    UI::EndDisabled();

                    UI::SameLine();
                    UI::Text("Last Updated: " + (
                        map.recordsTimestamp > 0 ?
                            Time::FormatString(Globals::dateFormat + "Local\\$G", map.recordsTimestamp) +
                                " (" + Util::FormatSeconds(now - map.recordsTimestamp) + " ago)" :
                            "never"
                    ));

                    if (UI::BeginTable("table_records", 5, UI::TableFlags::ScrollY | UI::TableFlags::RowBg)) {
                        UI::PushStyleColor(UI::Col::TableRowBgAlt, Globals::tableRowBgAltColor);

                        UI::TableSetupScrollFreeze(0, 1);
                        UI::TableSetupColumn("Pos",       UI::TableColumnFlags::WidthFixed, Globals::scale * 35);
                        UI::TableSetupColumn("Time",      UI::TableColumnFlags::WidthFixed, Globals::scale * 80);
                        UI::TableSetupColumn("Name",      UI::TableColumnFlags::WidthFixed, Globals::scale * 150);
                        UI::TableSetupColumn("Timestamp", UI::TableColumnFlags::WidthFixed, Globals::scale * 180);
                        UI::TableSetupColumn("Recency",   UI::TableColumnFlags::WidthFixed, Globals::scale * 120);
                        UI::TableHeadersRow();

                        UI::ListClipper clipper(map.records.Length);
                        while (clipper.Step()) {
                            for (int j = clipper.DisplayStart; j < clipper.DisplayEnd; j++) {
                                Models::Record@ record = @map.records[j];
                                Models::Account@ account = cast<Models::Account@>(Globals::accountsDict[record.accountId]);

                                UI::TableNextRow();
                                UI::TableNextColumn();
                                UI::Text("" + record.position);

                                UI::TableNextColumn();
                                string timeColor = "";
                                if (Settings::medalColors)
                                    switch (record.medals) {
                                        case 1: timeColor = Globals::colorBronze; break;
                                        case 2: timeColor = Globals::colorSilver; break;
                                        case 3: timeColor = Globals::colorGold;   break;
                                        case 4: timeColor = Globals::colorAuthor; break;
                                    }
                                UI::Text(timeColor + Time::Format(record.time));

                                UI::TableNextColumn();
                                if (UI::Selectable((account.accountName != "") ? account.accountName : account.accountId, false))
                                    Util::TmioPlayer(account.accountId);
                                Util::HoverTooltip("Trackmania.io profile");

                                UI::TableNextColumn();
                                UI::Text(Util::UnixToIso(record.timestampUnix));

                                UI::TableNextColumn();
                                UI::Text(Util::FormatSeconds(now - record.timestampUnix));
                            }
                        }

                        UI::PopStyleColor();
                        UI::EndTable();
                    }

                UI::EndGroup();

                UI::EndTabItem();
            }

            if (!map.viewing) {
                Globals::myMapsViewing.RemoveAt(i);
                Globals::myMapsViewingDict.Delete(map.mapId);
            }
        }

        UI::EndTabBar();

        UI::EndTabItem();
    }
}}