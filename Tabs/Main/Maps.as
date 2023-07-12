/*
c 2023-05-26
m 2023-07-12
*/

namespace Tabs {
    void Tab_Maps() {
        if (!UI::BeginTabItem(Icons::Map + " Maps")) return;

        if (UI::Button(Icons::Refresh + " Refresh My Maps (" + Globals::shownMaps + ")"))
            startnew(CoroutineFunc(Bulk::GetMyMapsCoro));

        UI::SameLine();
        int hiddenMapCount = Globals::hiddenMapsIndex.GetSize();
        if (Globals::showHidden) {
            if (UI::Button(Icons::EyeSlash + " Hide Hidden (" + hiddenMapCount + ")"))
                Globals::showHidden = false;
        } else {
            if (UI::Button(Icons::Eye + " Show Hidden (" + hiddenMapCount + ")"))
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

        UI::BeginTabBar("MapsTabs");
            Maps::Tab_MyMapsList();
            Maps::Tabs_Current();
        UI::EndTabBar();

        UI::EndTabItem();
    }
}