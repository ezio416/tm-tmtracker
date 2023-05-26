/*
c 2023-05-26
m 2023-05-26
*/

// Functions for rendering tabs in the interface
namespace Tabs {
    void MyMaps() {
        if (!UI::BeginTabItem(Icons::Map + " My Maps")) return;

        if (Settings::welcomeText)
            UI::TextWrapped(
                "Once you've updated your maps, click on a thumbnail to open a tab for that map. " +
                "Close tabs with the 'X' or with a middle click."
            );

        if (UI::Button(Icons::Refresh + " Update Map List (" + Globals::myMaps.Length + ")"))
            startnew(CoroutineFunc(Maps::GetMyMapsCoro));

        if (Globals::myHiddenMaps.Length > 0) {
            UI::SameLine();
            if (UI::Button(Icons::Eye + " Show Hidden (" + Globals::myHiddenMaps.Length + ")")) {
                string timerId = Various::LogTimerStart("unhiding all maps");

                for (uint i = 0; i < Globals::myHiddenMaps.Length;)
                    DB::MyMaps::UnHide(Globals::myHiddenMaps[i]);

                Various::LogTimerEnd(timerId);
            }
        }

        if (Globals::currentMaps.Length > 0) {
            UI::SameLine();
            if (UI::Button(Icons::Times + " Clear Current Maps (" + Globals::currentMaps.Length + ")"))
                Globals::ClearCurrentMaps();
        }

        UI::Separator();

        Globals::mapClicked = false;

        UI::BeginTabBar("MyMapsTabs");
            MyMapsList();
            MyMapsCurrent();
        UI::EndTabBar();

        UI::EndTabItem();
    }
}