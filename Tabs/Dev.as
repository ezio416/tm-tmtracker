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

        UI::EndTabItem();
    }
}