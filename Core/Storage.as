/*
c 2023-05-16
m 2023-05-16
*/

namespace Storage {
    string            title  = "\\$2f3" + Icons::MapO + "\\$z TMTracker";
    string            dbFile = IO::FromStorageFolder("TMTracker.db");
    SQLite::Database@ db     = SQLite::Database(dbFile);
    Models::Account[] accounts;
    Models::Map[]     maps;
    Models::Record[]  records;
}