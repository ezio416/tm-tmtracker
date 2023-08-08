/*
c 2023-05-16
m 2023-08-07
*/

namespace Models {
    class Account {
        string accountId;
        string accountName = "";
        int64  nameExpire = 0;
        string zoneId;

        string get_zoneName() { return Zones::Get(zoneId); }

        Account() { }
        Account(const string &in id) { accountId = id; }
        Account(Record@ record) {
            accountId = record.accountId;
            zoneId = record.zoneId;
        }
        Account(SQLite::Statement@ s) {
            accountId   = s.GetColumnString("accountId");
            accountName = s.GetColumnString("accountName");
            nameExpire  = s.GetColumnInt("nameExpire");
            zoneId      = s.GetColumnString("zoneId");
        }

        bool IsNameExpired() {
            return (nameExpire - Time::Stamp < 0);
        }

        string NameExpireFormatted() {
            if (IsNameExpired()) return "expired";
            return Time::FormatString(Settings::dateFormat + "Local\\$G", nameExpire);
        }

        void SetNameExpire(uint64 now = 0, int64 timestamp = 0) {
            if (timestamp != 0) {
                nameExpire = timestamp;
                return;
            }
            if (now == 0) now = Time::Stamp;
            nameExpire = Settings::accountNameValidDays * 86400 + now;
        }
    }
}