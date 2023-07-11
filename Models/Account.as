/*
c 2023-05-16
m 2023-07-10
*/

namespace Models {
    class Account {
        string accountId;
        string accountName = "";
        uint64 nameExpire = 0;
        string zoneId;

        string get_zoneName() { return Zones::Get(zoneId); }

        Account() { }
        Account(const string &in id) { accountId = id; }
        Account(Record@ record) {
            accountId = record.accountId;
            zoneId = record.zoneId;
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
            nameExpire = Settings::accountNameExpirationDays * 86400 + now;
        }
    }
}