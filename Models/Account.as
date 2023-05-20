/*
c 2023-05-16
m 2023-05-20
*/

// Classes for holding data gathered during plugin operation
namespace Models {
    // Data on a player profile
    class Account {
        string     accountId;
        string     accountName = "";
        dictionary recordMapUids;
        uint       timestamp;

        Account() { }
        Account(const string &in id) { accountId = id; }

        void GetName() {
            if (accountName != "") return;
            accountName = NadeoServices::GetDisplayNameAsync(accountId);
            timestamp = Time::Stamp;
        }
    }
}