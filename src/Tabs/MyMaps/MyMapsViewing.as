// c 2023-05-26
// m 2023-12-26

namespace Tabs { namespace MyMaps {
    void Tab_MyMapsViewing() {
        int tabFlags = 0;
        if (Globals::myMapsViewingSet) {
            Globals::myMapsViewingSet = false;
            tabFlags |= UI::TabItemFlags::SetSelected;
        }

        if (!UI::BeginTabItem(Icons::Eye + " Viewing Maps (" + Globals::myMapsViewing.Length + ")###my-maps-viewing", tabFlags))
            return;

        if (Settings::viewingText)
            UI::TextWrapped(
                "Close map tabs with a middle click or the " + Icons::Kenney::ButtonTimes +
                ".\nIf there are lots of maps here, use the dropdown arrow on the left or the left/right arrows on the right." +
                "\nClick on an account name to open their Trackmania.io page." +
                "\nIf a map is hidden, you cannot get records for it."
            );

        UI::BeginDisabled(Globals::myMapsViewing.Length == 0);
        if (UI::Button(Icons::Times + " Clear All"))
            Globals::ClearMyMapsViewing();
        UI::EndDisabled();

        int barFlags = UI::TabBarFlags::FittingPolicyScroll;
        if (Globals::myMapsViewing.Length > 0)
            barFlags |= UI::TabBarFlags::TabListPopupButton;

        UI::BeginTabBar("my-maps-viewing", barFlags);

        int64 now = Time::Stamp;

        for (uint i = 0; i < Globals::myMapsViewing.Length; i++)
            Tab_MyMapsViewingSingle(now, i);

        UI::EndTabBar();

        UI::EndTabItem();
    }

    void Tab_MyMapsViewingSingle(int64 now, uint i) {
        Models::Map@ map = Globals::myMapsViewing[i];

        int mapTabFlags = UI::TabItemFlags::Trailing;
        if (Globals::myMapsViewingMapId == map.mapId) {
            Globals::myMapsViewingMapId = "";
            mapTabFlags |= UI::TabItemFlags::SetSelected;
        }

        if (UI::BeginTabItem((Settings::mapNameColors ? map.mapNameColor : map.mapNameText) + "###" + map.mapUid, map.viewing, mapTabFlags)) {
            UI::BeginGroup();
                vec2 thumbSize = vec2(Settings::viewingThumbWidth, Settings::viewingThumbWidth);
                try {
                    UI::Image(map.thumbnailTexture, thumbSize);
                } catch {
                    UI::Dummy(thumbSize);
                }

                if (Settings::viewingLoadThumbs) {
                    startnew(CoroutineFunc(map.LoadThumbnailCoro));
                } else if (!Locks::thumbs && map.thumbnailTexture is null && !map.thumbnailLoading) {
                    if (UI::Button(Icons::PictureO + " Load Thumbnail"))
                        startnew(CoroutineFunc(map.LoadThumbnailCoro));
                }

                vec2 pos = UI::GetCursorPos();
                UI::PushTextWrapPos(pos.x + Settings::viewingThumbWidth);
                UI::Text(map.mapNameText);
                UI::PopTextWrapPos();

                UI::Text(Globals::colorMedalAuthor + Icons::Circle + " " + Time::Format(map.authorTime));
                UI::Text(Globals::colorMedalGold   + Icons::Circle + " " + Time::Format(map.goldTime));
                UI::Text(Globals::colorMedalSilver + Icons::Circle + " " + Time::Format(map.silverTime));
                UI::Text(Globals::colorMedalBronze + Icons::Circle + " " + Time::Format(map.bronzeTime));
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
                        Time::FormatString(Globals::dateFormat, map.recordsTimestamp) +
                            " (" + Util::FormatSeconds(now - map.recordsTimestamp) + " ago)" :
                        "never"
                ));

                int flags = UI::TableFlags::RowBg |
                            UI::TableFlags::ScrollY |
                            UI::TableFlags::Sortable;

                if (UI::BeginTable("table_records", 5, flags)) {
                    UI::PushStyleColor(UI::Col::TableRowBgAlt, Globals::colorTableRowBgAlt);

                    int fixed = UI::TableColumnFlags::WidthFixed;
                    int noSort = UI::TableColumnFlags::NoSort;
                    int fixedNoSort = fixed | noSort;

                    UI::TableSetupScrollFreeze(0, 1);
                    UI::TableSetupColumn("Pos",       fixed,                                                                                    Globals::scale * 35);
                    UI::TableSetupColumn("Time",      fixedNoSort,                                                                              Globals::scale * 80);
                    UI::TableSetupColumn("Account",   (Locks::accountNames || Locks::allRecords || Locks::singleRecords ? fixedNoSort : fixed), Globals::scale * 120);
                    UI::TableSetupColumn("Timestamp", fixed,                                                                                    Globals::scale * 180);
                    UI::TableSetupColumn("Recency",   fixed,                                                                                    Globals::scale * 120);
                    UI::TableHeadersRow();

                    UI::TableSortSpecs@ tableSpecs = UI::TableGetSortSpecs();

                    if (tableSpecs !is null && tableSpecs.Dirty) {
                        UI::TableColumnSortSpecs[]@ colSpecs = tableSpecs.Specs;

                        if (colSpecs !is null && colSpecs.Length > 0) {
                            bool ascending = colSpecs[0].SortDirection == UI::SortDirection::Ascending;

                            switch (colSpecs[0].ColumnIndex) {
                                case 0:  // pos
                                    Settings::myMapsViewingSortMethod = ascending ? Sort::SortMethod::RecordsWorstPosFirst : Sort::SortMethod::RecordsBestPosFirst;
                                    break;
                                case 2:  // account
                                    for (uint j = 0; j < map.records.Length; j++) {
                                        Models::Record@ record = map.records[j];
                                        if (record.accountName == "" && Globals::accounts.Length > 0 && Globals::accountsDict.Exists(record.accountId)) {
                                            Models::Account@ account = cast<Models::Account@>(Globals::accountsDict[record.accountId]);
                                            record.accountName = account.accountName;
                                        }
                                    }
                                    Settings::myMapsViewingSortMethod = ascending ? Sort::SortMethod::RecordsAccountsAlpha : Sort::SortMethod::RecordsAccountsAlphaRev;
                                    break;
                                case 3:  // timestamp
                                    Settings::myMapsViewingSortMethod = ascending ? Sort::SortMethod::RecordsOldFirst : Sort::SortMethod::RecordsNewFirst;
                                    break;
                                case 4:  // recency
                                    Settings::myMapsViewingSortMethod = ascending ? Sort::SortMethod::RecordsNewFirst : Sort::SortMethod::RecordsOldFirst;
                                    break;
                                default:;
                            }

                            startnew(CoroutineFunc(map.SortRecordsCoro));
                        }

                        tableSpecs.Dirty = false;
                    }

                    UI::ListClipper clipper(map.recordsSorted.Length);
                    while (clipper.Step()) {
                        for (int j = clipper.DisplayStart; j < clipper.DisplayEnd; j++) {
                            Models::Record@ record = @map.recordsSorted[j];
                            Models::Account@ account = cast<Models::Account@>(Globals::accountsDict[record.accountId]);

                            UI::TableNextRow();
                            UI::TableNextColumn();
                            UI::Text((Settings::highlightTop5 && record.position < 6 ? Globals::colorTop5 : "") + record.position);

                            UI::TableNextColumn();
                            string color;
                            if (Settings::medalColors)
                                switch (record.medals) {
                                    case 1:  color = Globals::colorMedalBronze; break;
                                    case 2:  color = Globals::colorMedalSilver; break;
                                    case 3:  color = Globals::colorMedalGold;   break;
                                    case 4:  color = Globals::colorMedalAuthor; break;
                                    default: color = Globals::colorMedalNone;
                                }
                            UI::Text(color + Time::Format(record.time));

                            UI::TableNextColumn();
                            if (UI::Selectable((account.accountName != "") ? account.accountName : account.accountId, false))
                                Util::TmioPlayer(account.accountId);

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
}}