/*
c 2023-05-26
m 2023-07-11
*/

namespace Tabs {
    void Tab_MyMaps() {
        if (!UI::BeginTabItem(Icons::Map + " Maps")) return;

        if (UI::Button(Icons::Refresh + " Get My Maps (" + (Globals::maps.Length - Globals::hiddenMapsIndex.GetSize()) + ")"))
            startnew(CoroutineFunc(API::GetMyMapsCoro));

        UI::SameLine();
        if (Globals::showHidden) {
            if (UI::Button(Icons::EyeSlash + " Hide Hidden (" + Globals::hiddenMapsIndex.GetSize() + ")"))
                Globals::showHidden = false;
        } else {
            if (UI::Button(Icons::Eye + " Show Hidden (" + Globals::hiddenMapsIndex.GetSize() + ")"))
                Globals::showHidden = true;
        }

        if (Globals::currentMaps.Length > 0) {
            UI::SameLine();
            if (UI::Button(Icons::Times + " Clear Current Maps (" + Globals::currentMaps.Length + ")"))
                Globals::ClearCurrentMaps();
        }

        if (Settings::welcomeText) {
            UI::TextWrapped(
                "Once you've updated your maps, click on a thumbnail to open a tab for that map. " +
                "\nClose tabs with a middle click or the \uE997"
            );
        }

        UI::BeginTabBar("MyMapsTabs");
            MyMaps::Tab_List();
            MyMaps::Tabs_Current();
        UI::EndTabBar();

        UI::EndTabItem();
    }
}