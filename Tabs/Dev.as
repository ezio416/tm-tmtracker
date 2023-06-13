/*
c 2023-05-26
m 2023-06-13
*/

// Functions for rendering tabs in the interface
namespace Tabs {
    void Dev() {
        if (!UI::BeginTabItem(Icons::Cogs + " Dev")) return;

        UI::TextWrapped(
            "I take no responsibility if you break shit in here!" +
            "\nThis is all debug stuff and could get you banned." +
            "\n\nLock (hide) this tab from the 'Info' tab."
        );

        UI::Separator();

        if (UI::Button(Icons::Download + " Get All Records"))
            startnew(CoroutineFunc(Maps::GetMyMapsRecordsCoro));

        if (UI::Button(Icons::FloppyO + " save accounts"))
            DB::AllAccounts::Save();

        if (UI::Button(Icons::Times + " clear accounts"))
            DB::AllAccounts::Clear();

        UI::EndTabItem();
    }
}