// c 2023-10-11
// m 2023-12-27

namespace Tabs { namespace MyRecords {
    void Tab_MyRecordsMapsViewing() {
        int tabFlags = 0;
        if (Globals::myRecordsMapsViewingSet) {
            Globals::myRecordsMapsViewingSet = false;
            tabFlags |= UI::TabItemFlags::SetSelected;
        }

        if (!UI::BeginTabItem(Icons::Eye + " Viewing Maps (" + Globals::myRecordsMapsViewing.Length + ")###my-records-maps-viewing", tabFlags))
            return;

        if (Settings::viewingText)
            UI::TextWrapped(
                "Close map tabs with a middle click or the " + Icons::Kenney::ButtonTimes +
                ".\nIf there are lots of maps here, use the dropdown arrow on the left or the left/right arrows on the right."
            );

        UI::BeginDisabled(Globals::myRecordsMapsViewing.Length == 0);
        if (UI::Button(Icons::Times + " Clear All"))
            Globals::ClearMyRecordsMapsViewing();
        UI::EndDisabled();

        int barFlags = UI::TabBarFlags::FittingPolicyScroll;
        if (Globals::myRecordsMapsViewing.Length > 0)
            barFlags |= UI::TabBarFlags::TabListPopupButton;

        UI::BeginTabBar("my-records-viewing", barFlags);

        int64 now = Time::Stamp;

        for (uint i = 0; i < Globals::myRecordsMapsViewing.Length; i++)
            Tab_MyRecordsMapsViewingSingle(now, i);

        UI::EndTabBar();

        UI::EndTabItem();
    }

    void Tab_MyRecordsMapsViewingSingle(int64 now, uint i) {
        Models::Map@ map = Globals::myRecordsMapsViewing[i];

        int mapTabFlags = UI::TabItemFlags::Trailing;
        if (Globals::myRecordsMapsViewingMapId == map.mapId) {
            Globals::myRecordsMapsViewingMapId = "";
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

                Models::Account@ account = cast<Models::Account@>(Globals::accountsDict[map.authorId]);
                if (account !is null)
                    UI::Text(account.accountName != "" ? account.accountName : "unknown");

                if (Settings::viewingMapUploadTime)
                    UI::Text(Util::UnixToIso(Math::Max(map.uploadTimestamp, map.updateTimestamp), true));

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
                if (UI::Button(Icons::Heartbeat + " Trackmania.io"))
                    Util::TmioMap(map.mapUid);

                UI::BeginDisabled(Locks::tmx);
                UI::SameLine();
                if (UI::Button(Icons::Exchange + " Trackmania.exchange"))
                    startnew(CoroutineFunc(map.TmxCoro));
                UI::EndDisabled();

                int colCount = 1;
                if (Settings::viewingMyRecordColBronze)    colCount++;
                if (Settings::viewingMyRecordColSilver)    colCount++;
                if (Settings::viewingMyRecordColGold)      colCount++;
                if (Settings::viewingMyRecordColAT)        colCount++;
                if (Settings::viewingMyRecordColTimestamp) colCount++;
                if (Settings::viewingMyRecordColRecency)   colCount++;

                if (UI::BeginTable("table_records", colCount, UI::TableFlags::RowBg | UI::TableFlags::ScrollY)) {
                    UI::PushStyleColor(UI::Col::TableRowBgAlt, Globals::colorTableRowBgAlt);

                    UI::TableSetupScrollFreeze(0, 1);
                                                               UI::TableSetupColumn("PB",                                                                UI::TableColumnFlags::WidthFixed, Globals::scale * 80);
                    if (Settings::viewingMyRecordColBronze)    UI::TableSetupColumn((Settings::medalColors ? Globals::colorMedalBronze : "") + "Bronze", UI::TableColumnFlags::WidthFixed, Globals::scale * 80);
                    if (Settings::viewingMyRecordColSilver)    UI::TableSetupColumn((Settings::medalColors ? Globals::colorMedalSilver : "") + "Silver", UI::TableColumnFlags::WidthFixed, Globals::scale * 80);
                    if (Settings::viewingMyRecordColGold)      UI::TableSetupColumn((Settings::medalColors ? Globals::colorMedalGold   : "") + "Gold",   UI::TableColumnFlags::WidthFixed, Globals::scale * 80);
                    if (Settings::viewingMyRecordColAT)        UI::TableSetupColumn((Settings::medalColors ? Globals::colorMedalAuthor : "") + "Author", UI::TableColumnFlags::WidthFixed, Globals::scale * 80);
                    if (Settings::viewingMyRecordColTimestamp) UI::TableSetupColumn("Timestamp",                                                         UI::TableColumnFlags::WidthFixed, Globals::scale * 180);
                    if (Settings::viewingMyRecordColRecency)   UI::TableSetupColumn("Recency",                                                           UI::TableColumnFlags::WidthFixed, Globals::scale * 120);
                    UI::TableHeadersRow();

                    Models::Record@ record = cast<Models::Record@>(Globals::myRecordsDict[map.mapId]);

                    UI::TableNextRow();
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

                    if (Settings::viewingMyRecordColBronze) {
                        UI::TableNextColumn();
                        UI::Text(Util::TimeFormatColored(int(record.time) - int(map.bronzeTime)));
                    }

                    if (Settings::viewingMyRecordColSilver) {
                        UI::TableNextColumn();
                        UI::Text(Util::TimeFormatColored(int(record.time) - int(map.silverTime)));
                    }

                    if (Settings::viewingMyRecordColGold) {
                        UI::TableNextColumn();
                        UI::Text(Util::TimeFormatColored(int(record.time) - int(map.goldTime)));
                    }

                    if (Settings::viewingMyRecordColAT) {
                        UI::TableNextColumn();
                        UI::Text(Util::TimeFormatColored(int(record.time) - int(map.authorTime)));
                    }

                    if (Settings::viewingMyRecordColTimestamp) {
                        UI::TableNextColumn();
                        UI::Text(Util::UnixToIso(record.timestampUnix));
                    }

                    if (Settings::viewingMyRecordColRecency) {
                        UI::TableNextColumn();
                        UI::Text(Util::FormatSeconds(now - record.timestampUnix));
                    }

                    UI::PopStyleColor();
                    UI::EndTable();
                }

            UI::EndGroup();

            UI::EndTabItem();
        }

        if (!map.viewing) {
            Globals::myRecordsMapsViewing.RemoveAt(i);
            Globals::myRecordsMapsViewingDict.Delete(map.mapId);
        }
    }
}}