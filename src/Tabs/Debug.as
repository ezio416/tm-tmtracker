// c 2023-05-26
// m 2023-12-26

namespace Tabs {
    void Tab_Debug() {
        if (!UI::BeginTabItem(Icons::CodeFork + " Debug"))
            return;

        UI::TextWrapped(
            "I take no responsibility if you break the plugin, your game, " +
            "or get yourself banned in here. \\$DA2You've been warned."
        );

        UI::Separator();

        UI::BeginTabBar("debug-tabs");
            if (UI::BeginTabItem("accounts (" + Globals::accounts.Length + ")")) {
                if (UI::Button(Icons::Times + " Clear"))
                    Globals::ClearAccounts();

                UI::SameLine();
                if (UI::Button(Icons::Download + " Get Names"))
                    startnew(CoroutineFunc(Bulk::GetAccountNamesCoro));

                int64 now = Time::Stamp;

                int flags =
                    UI::TableFlags::Resizable |
                    UI::TableFlags::ScrollY;

                if (UI::BeginTable("debug-table-accounts", 4, flags)) {
                    UI::TableSetupScrollFreeze(0, 1);
                    UI::TableSetupColumn("ID");
                    UI::TableSetupColumn("Name");
                    UI::TableSetupColumn("NameValid");
                    UI::TableHeadersRow();

                    UI::ListClipper clipper(Globals::accounts.Length);
                    while (clipper.Step()) {
                        for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                            Models::Account@ account = @Globals::accounts[i];
                            UI::TableNextRow();
                            UI::TableNextColumn();
                            UI::Text(account.accountId);
                            UI::TableNextColumn();
                            UI::Text(account.accountName);
                            UI::TableNextColumn();
                            int64 nameValid = account.nameExpire - now;
                            UI::Text("" + (nameValid > 0 ? nameValid : 0));
                        }
                    }

                    UI::EndTable();
                }

                UI::EndTabItem();
            }

            if (UI::BeginTabItem("maps (" + Globals::myMaps.Length + ")")) {
                if (UI::Button(Icons::Times + " Clear"))
                    Globals::ClearMyMaps();

                int flags =
                    UI::TableFlags::Resizable |
                    UI::TableFlags::ScrollY;

                if (UI::BeginTable("debug-maps-table", 3, flags)) {
                    UI::TableSetupScrollFreeze(0, 1);
                    UI::TableSetupColumn("Name");
                    UI::TableSetupColumn("NameColor");
                    UI::TableSetupColumn("Hidden");
                    UI::TableHeadersRow();

                    UI::ListClipper clipper(Globals::myMaps.Length);
                    while (clipper.Step()) {
                        for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                            Models::Map@ map = @Globals::myMaps[i];

                            UI::TableNextRow();
                            UI::TableNextColumn();
                            UI::Text(map.mapNameText);

                            UI::TableNextColumn();
                            UI::Text(map.mapNameColor);

                            UI::TableNextColumn();
                            UI::Text((map.hidden) ? "yes" : "no");
                        }
                    }
                    UI::EndTable();
                }

                UI::EndTabItem();
            }

            if (UI::BeginTabItem("records (" + Globals::myMapsRecords.Length + ")")) {
                if (UI::Button(Icons::Times + " Clear"))
                    Globals::ClearMyMapsRecords();

                UI::SameLine();
                if (UI::Button(Icons::Download + " Get All"))
                    startnew(CoroutineFunc(Bulk::GetMyMapsRecordsCoro));

                int flags =
                    UI::TableFlags::Resizable |
                    UI::TableFlags::ScrollY;

                if (UI::BeginTable("debug-records-table", 8, flags)) {
                    UI::TableSetupScrollFreeze(0, 1);
                    UI::TableSetupColumn("Map");
                    UI::TableSetupColumn("Account");
                    UI::TableSetupColumn("Time");
                    UI::TableSetupColumn("Medals");
                    UI::TableSetupColumn("Position");
                    UI::TableSetupColumn("RecordId");
                    UI::TableSetupColumn("TimestampIso");
                    UI::TableSetupColumn("TimestampUnix");
                    UI::TableHeadersRow();

                    UI::ListClipper clipper(Globals::myMapsRecords.Length);
                    while (clipper.Step()) {
                        for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                            Models::Record@ record = @Globals::myMapsRecords[i];
                            Models::Account@ account = cast<Models::Account@>(Globals::accountsDict[record.accountId]);

                            UI::TableNextRow();
                            UI::TableNextColumn();
                            UI::Text(record.mapNameText);
                            UI::TableNextColumn();
                            UI::Text((account.accountName != "") ? account.accountName : account.accountId);
                            UI::TableNextColumn();
                            UI::Text("" + record.time);
                            UI::TableNextColumn();
                            UI::Text("" + record.medals);
                            UI::TableNextColumn();
                            UI::Text("" + record.position);
                            UI::TableNextColumn();
                            UI::Text(record.recordId);
                            UI::TableNextColumn();
                            UI::Text(record.timestampIso);
                            UI::TableNextColumn();
                            UI::Text("" + record.timestampUnix);
                        }
                    }

                    UI::EndTable();
                }

                UI::EndTabItem();
            }

            if (UI::BeginTabItem("database")) {
                if (UI::Button("clear"))
                    startnew(CoroutineFunc(Database::ClearCoro));

                UI::EndTabItem();
            }

            if (UI::BeginTabItem("locks")) {
                UI::Text((Locks::accountNames      ? "\\$0F0" : "\\$F00") + "accountNames");
                UI::Text((Locks::allRecords        ? "\\$0F0" : "\\$F00") + "allRecords");
                UI::Text((Locks::db                ? "\\$0F0" : "\\$F00") + "db");
                UI::Text((Locks::editMap           ? "\\$0F0" : "\\$F00") + "editMap");
                UI::Text((Locks::mapInfo           ? "\\$0F0" : "\\$F00") + "mapInfo");
                UI::Text((Locks::myMaps            ? "\\$0F0" : "\\$F00") + "myMaps");
                UI::Text((Locks::myRecords         ? "\\$0F0" : "\\$F00") + "myRecords");
                UI::Text((Locks::playMap           ? "\\$0F0" : "\\$F00") + "playMap");
                UI::Text((Locks::requesting        ? "\\$0F0" : "\\$F00") + "requesting");
                UI::Text((Locks::singleRecords     ? "\\$0F0" : "\\$F00") + "singleRecords");
                UI::Text((Locks::sortMyMapsRecords ? "\\$0F0" : "\\$F00") + "sortMyMapsRecords");
                UI::Text((Locks::sortMyRecords     ? "\\$0F0" : "\\$F00") + "sortMyRecords");
                UI::Text((Locks::sortSingleRecords ? "\\$0F0" : "\\$F00") + "sortSingleRecords");
                UI::Text((Locks::thumbs            ? "\\$0F0" : "\\$F00") + "thumbs");
                UI::Text((Locks::tmx               ? "\\$0F0" : "\\$F00") + "tmx");

                UI::EndTabItem();
            }

        UI::EndTabBar();

        UI::EndTabItem();
    }
}