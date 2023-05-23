/*
c 2023-05-20
m 2023-05-21
*/

// Functions that don't fit nicely in other categories
namespace Various {
    string FormatSeconds(int seconds) {
        int minutes = seconds / 60;
        seconds %= 60;
        int hours = minutes / 60;
        minutes %= 60;
        int days = hours / 24;
        hours %= 24;

        if (days > 0)
            return Zpad2(days) + ":" + Zpad2(hours) + ":" + Zpad2(minutes) + ":" + Zpad2(seconds);
        if (hours > 0)
            return "00:" + Zpad2(hours) + ":" + Zpad2(minutes) + ":" + Zpad2(seconds);
        if (minutes > 0)
            return "00:00:" + Zpad2(minutes) + ":" + Zpad2(seconds);
        return "00:00:00:" + Zpad2(seconds);
    }

    void WaitToDoNadeoRequestCoro() {
        if (Storage::latestNadeoRequest == 0) {
            Storage::latestNadeoRequest = Time::Now;
            return;
        }

        while (Storage::requestsInProgress > 0)
            yield();
        if (Storage::requestsInProgress < 0)  // hopefully won't happen
            Storage::requestsInProgress = 0;
        Storage::requestsInProgress++;

        while (Time::Now - Storage::latestNadeoRequest < Settings::timeBetweenNadeoRequests)
            yield();

        Storage::latestNadeoRequest = Time::Now;
    }

    string Zpad2(int num) {
        if (num > 9) return "" + num;
        return "0" + num;
    }
}