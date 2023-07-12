/*
c 2023-07-11
m 2023-07-12
*/

namespace Tabs {
    void Tab_Records() {
        if (!UI::BeginTabItem(Icons::Trophy + " Records")) return;

        if (UI::Button(Icons::Download + " Get All Records"))
            startnew(CoroutineFunc(Bulk::GetMyMapsRecordsCoro));

        uint low = uint(0.6 * Globals::shownMaps);
        uint lowMin = low / 60;
        uint lowSec = low % 60;
        uint high = uint(1.5 * Globals::shownMaps);
        uint highMin = high / 60;
        uint highSec = high % 60;
        UI::TextWrapped(
            "Getting records for \\$2F2" + Globals::shownMaps + " \\$Gmaps should take between \\$2F2" +
            lowMin + "m" + lowSec + "s - " + highMin + "m" + highSec +
            "s\\$G.\nIt could be faster, but each map takes 2+ API requests and we don't want to spam." +
            "\nTask will take longer if:\n - your maps have lots of records\n - there are lots of unique accounts\n - you have low framerate"
        );

        UI::BeginTabBar("RecordsTabs");
            Records::Tab_MyMapsRecords();
        UI::EndTabBar();

        UI::EndTabItem();
    }
}