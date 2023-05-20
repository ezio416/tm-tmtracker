/*
c 2023-05-16
m 2023-05-20
*/

// Classes for holding data gathered during plugin operation
namespace Models {
    // Data on a player profile
    class Account {
        string   accountId;
        string   accountName;
        uint     accountNameTimestamp;
        string   clubTagColor;
        uint     clubTagTimestamp;
        string   clubTagRaw;
        string   clubTagText;
        string[] recordUids;
        uint     timestamp;
    }
}