/*
c 2023-05-26
m 2023-07-12
*/

namespace Tabs {
    void Tab_Maps() {
        if (!UI::BeginTabItem(Icons::Map + " Maps")) return;

        UI::BeginTabBar("MapsTabs");
            Maps::Tab_MyMapsList();
            Maps::Tabs_Current();
        UI::EndTabBar();

        UI::EndTabItem();
    }
}