/*
c 2023-05-26
m 2023-07-10
*/

namespace Tabs {
    void Tab_Dev() {
        if (!UI::BeginTabItem(Icons::CodeFork + " Dev")) return;

        Button_LockDev();

        UI::TextWrapped(
            "I take no responsibility if you break the plugin, your game, or get yourself" +
            " banned in here. Turn back with the lock above. \\$DA2You've been warned."
        );

        UI::Separator();

        UI::BeginTabBar("dev-tabs");
            if (UI::BeginTabItem("accounts (" + Globals::accounts.Length + ")")) {
                if (UI::Button(Icons::Times + " Clear"))
                    Globals::ClearAccounts();

                UI::SameLine();
                if (UI::Button(Icons::Download + " Get Names"))
                    startnew(CoroutineFunc(API::GetAccountNamesCoro));

                auto now = Time::Stamp;

                int flags =
                    UI::TableFlags::Resizable |
                    UI::TableFlags::ScrollY;

                if (UI::BeginTable("table_accounts", 4, flags)) {
                    UI::TableSetupScrollFreeze(0, 1);
                    UI::TableSetupColumn("ID");
                    UI::TableSetupColumn("Name");
                    UI::TableSetupColumn("NameValid");
                    UI::TableSetupColumn("Zone");
                    UI::TableHeadersRow();

                    UI::ListClipper clipper(Globals::accounts.Length);
                    while (clipper.Step()) {
                        for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                            auto account = @Globals::accounts[i];
                            UI::TableNextRow();
                            UI::TableNextColumn();
                            UI::Text(account.accountId);
                            UI::TableNextColumn();
                            UI::Text(account.accountName);
                            UI::TableNextColumn();
                            auto nameValid = account.nameExpire - now;
                            UI::Text("" + (nameValid > 0 ? nameValid : 0));
                            UI::TableNextColumn();
                            UI::Text(account.zoneName);
                        }
                    }

                    UI::EndTable();
                }

                UI::EndTabItem();
            }

            if (UI::BeginTabItem("maps (" + Globals::maps.Length + ")")) {
                auto keys = Globals::hiddenMapsIndex.GetKeys();
                UI::Text("hidden (" + keys.Length + "):");
                if (UI::BeginChild("dev-hidden-maps")) {
                    for (uint i = 0; i < keys.Length; i++) {
                        auto map = cast<Models::Map@>(Globals::hiddenMapsIndex[keys[i]]);
                        UI::Text(map.mapNameRaw);
                    }
                    UI::EndChild();
                }

                UI::EndTabItem();
            }

            if (UI::BeginTabItem("records (" + Globals::records.Length + ")")) {
                if (UI::Button(Icons::Times + " Clear"))
                    Globals::ClearRecords();

                int flags =
                    UI::TableFlags::Resizable |
                    UI::TableFlags::ScrollY;

                if (UI::BeginTable("dev-records-table", 5, flags)) {
                    UI::TableSetupScrollFreeze(0, 1);
                    UI::TableSetupColumn("Map");
                    UI::TableSetupColumn("Account");
                    UI::TableSetupColumn("Time");
                    UI::TableSetupColumn("Medals");
                    UI::TableSetupColumn("Position");
                    UI::TableHeadersRow();

                    UI::ListClipper clipper(Globals::records.Length);
                    while (clipper.Step()) {
                        for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                            auto record = @Globals::records[i];
                            auto account = cast<Models::Account>(Globals::accountsIndex[record.accountId]);

                            UI::TableNextRow();
                            UI::TableNextColumn();
                            UI::Text(record.mapName);
                            UI::TableNextColumn();
                            UI::Text((account.accountName != "") ? account.accountName : account.accountId);
                            UI::TableNextColumn();
                            UI::Text("" + record.time);
                            UI::TableNextColumn();
                            UI::Text("" + record.medals);
                            UI::TableNextColumn();
                            UI::Text("" + record.position);
                        }
                    }

                    UI::EndTable();
                }

                UI::EndTabItem();
            }
        UI::EndTabBar();

        UI::EndTabItem();
    }

    void Button_LockDev() {
        if (UI::Button(Icons::Lock + " Lock Dev Tab")) {
            Util::Trace("dev tab locked");
            Settings::devHidden = true;
            Settings::devHiddenByUser = true;
            Globals::dev = false;
        }
    }
}