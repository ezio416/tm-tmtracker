namespace Tabs {
    void Tab_Info() {
        if (!UI::BeginTabItem(Icons::Info + " Info"))
            return;

        UI::TextWrapped(
            "TMTracker is a project I started back in December of 2022.\nIt has moved from Python " + Icons::ArrowRight +
            " C# " + Icons::ArrowRight + " Angelscript (this), which will probably be the final version.\nThis is by far my " +
            "largest coding project with hundreds of hours put in, so I hope you find it useful! "
        );

        UI::Separator();

        UI::TextWrapped(
            "If you have suggestions or problems, please submit an issue!\n" +
            "It's very easy to add a setting, and probably easy to add a small feature."
        );
        string linkGH = "https://github.com/ezio416/tm-tmtracker/issues";
        if (UI::Button(Icons::Github + " Issues"))
            OpenBrowserURL(linkGH);

        UI::Separator();

        UI::TextWrapped("Files are kept in: ");

        UI::SameLine();
        if (UI::Selectable("\\$1F1" + Files::storageFolder, false))
            IO::SetClipboard(Files::storageFolder);
        Util::HoverTooltip("copy to clipboard");

        if (UI::Button(Icons::FolderOpen + " Open Folder in Explorer"))
            OpenExplorerPath(Files::storageFolder);

        UI::TextWrapped("If you want to look in the database, I recommend DB Browser:");

        string linkSQL = "sqlitebrowser.org";
        if (UI::Button(Icons::Database + " " + linkSQL))
            OpenBrowserURL("https://" + linkSQL);

        UI::EndTabItem();
    }
}
