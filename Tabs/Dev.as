/*
c 2023-05-26
m 2023-05-26
*/

// Functions for rendering tabs in the interface
namespace Tabs {
    void Dev() {
        if (!UI::BeginTabItem(Icons::Cogs + " Dev")) return;

        UI::Text("I take no responsibility if you break shit in here!");

        UI::Separator();

        if (UI::Button(Icons::Download + " Get All Records"))
            startnew(CoroutineFunc(Maps::GetMyMapsRecordsCoro));

        if (UI::Button(Icons::Download + " Get Account Names"))
            startnew(CoroutineFunc(Accounts::GetAccountNamesCoro));

        UI::Text("total accounts: " + Globals::accounts.Length);
        UI::Text("account IDs: " + Globals::accountIds.GetKeys().Length);

        for (uint i = 0; i < Globals::accounts.Length; i++) {
            UI::Text(
                Globals::accounts[i].accountId   + " _ " +
                Globals::accounts[i].accountName + " _ " +
                Globals::accounts[i].NameExpireFormatted()
            );
        }

        UI::EndTabItem();
    }
}