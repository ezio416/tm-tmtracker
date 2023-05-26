/*
c 2023-05-26
m 2023-05-26
*/

// Functions for rendering tabs in the interface
namespace Tabs {
    void Info() {
        if (!UI::BeginTabItem(Icons::Info + " Info")) return;

        UI::TextWrapped(
            "TMTracker is a project I started back in December of 2022. It was first written in Python, then C#, "    +
            "and now Angelscript, with each iteration having slightly different features. I plan for this to be "     +
            "the final iteration, and there will be more features to come, such as:\n\n - adding other maps and "     +
            "campaigns, such as the current map or from TMX\n - tracking personal records on maps and campaigns\n - " +
            "tracking recent records for all maps \n - probably more!\n\nThis is by far my largest coding project "   +
            "with hundreds of hours put in, so I hope you find it useful! " + Icons::SmileO + "\n\n"
        );

        UI::Separator();

        UI::TextWrapped(
            "Plugin files are kept at " + Globals::storageFolder +
            "\nIf you want to look in the database, I recommend DB Browser: sqlitebrowser.org\n"
        );

        UI::Separator();

        if (Globals::dev) {
            if (UI::Button("Lock Dev Tab")) {
                Various::Trace("dev tab locked");
                Globals::dev = false;
            }
        } else {
            if (UI::InputText("Unlock Dev Tab", "") == "balls") {
                Various::Trace("dev tab unlocked");
                Globals::dev = true;
            }
        }

        UI::EndTabItem();
    }
}