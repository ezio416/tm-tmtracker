/*
c 2023-10-11
m 2023-10-11
*/

namespace Tabs { namespace MyRecords {
    void Tab_MyRecordsMapsViewing() {
        if (!UI::BeginTabItem(Icons::Eye + " Viewing Maps (" + Globals::myRecordsMapsViewing.Length + ")###my-records-maps-viewing"))
            return;

        int flags = UI::TabBarFlags::FittingPolicyScroll;
        if (Globals::myMapsViewing.Length > 0)
            flags |= UI::TabBarFlags::TabListPopupButton;

        UI::BeginTabBar("my-records-viewing", flags);

        int64 now = Time::Stamp;


        UI::EndTabBar();

        UI::EndTabItem();
    }
}}