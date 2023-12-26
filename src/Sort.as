// c 2023-12-25
// m 2023-12-25

// most things here courtesy of "BetterTOTD" plugin - https://github.com/XertroV/tm-better-totd
namespace Sort {
    uint64 maxFrameTime = 10;
    uint64 sortLastYield = 0;

    funcdef int RecordSortFunc(Models::Record@ r1, Models::Record@ r2);

    int RecordsNewFirst(Models::Record@ r1, Models::Record@ r2) {
        return Math::Clamp(r2.timestampUnix - r1.timestampUnix, -1, 1);
    }

    int RecordsOldFirst(Models::Record@ r1, Models::Record@ r2) {
        return Math::Clamp(r1.timestampUnix - r2.timestampUnix, -1, 1);
    }

    int RecordsBestFirst(Models::Record@ r1, Models::Record@ r2) {
        return Math::Clamp(r1.time - r2.time, -1, 1);
    }

    int RecordsWorstFirst(Models::Record@ r1, Models::Record@ r2) {
        return Math::Clamp(r2.time - r1.time, -1, 1);
    }

    // int RecordsShortestAuthorFirst(Models::Record@ r1, Models::Record@ r2) {
    //     return Math::Clamp(r2.mapAuthorTime - r1.mapAuthorTime, -1, 1);
    // }

    // int RecordsLongestAuthorFirst(Models::Record@ r1, Models::Record@ r2) {
    //     return Math::Clamp(r1.mapAuthorTime - r2.mapAuthorTime, -1, 1);
    // }

    enum SortMethod {
        RecordsNewFirst,
        RecordsOldFirst,
        RecordsBestFirst,
        RecordsWorstFirst
        // RecordsShortestAuthorFirst,
        // RecordsLongestAuthorFirst
    }

    RecordSortFunc@[] sortFunctions = {
        RecordsNewFirst,
        RecordsOldFirst,
        RecordsBestFirst,
        RecordsWorstFirst
        // RecordsShortestAuthorFirst,
        // RecordsLongestAuthorFirst
    };

    Models::Record@[]@ QuickSortRecords(Models::Record@[]@ arr, RecordSortFunc@ f, int left = 0, int right = -1) {
        uint64 now = Time::Now;
        if (now - sortLastYield > maxFrameTime) {
            sortLastYield = now;
            yield();
        }

        if (right < 0)
            right = arr.Length - 1;

        if (arr.Length == 0)
            return arr;

        int i = left;
        int j = right;
        Models::Record@ pivot = arr[(left + right) / 2];

        while (i <= j) {
            while (f(arr[i], pivot) < 0)
                i++;

            while (f(arr[j], pivot) > 0)
                j--;

            if (i <= j) {
                Models::Record@ temp = arr[i];
                @arr[i] = arr[j];
                @arr[j] = temp;
                i++;
                j--;
            }
        }

        if (left < j)
            arr = QuickSortRecords(arr, f, left, j);

        if (i < right)
            arr = QuickSortRecords(arr, f, i, right);

        return arr;
    }

    void MyMapsRecordsCoro() {
        while (Locks::sortMyMapsRecords)
            yield();
        Locks::sortMyMapsRecords = true;
        string timerId = Log::TimerBegin("sorting my maps records");
        string statusId = "sort-records";

        Globals::myMapsRecordsSorted.RemoveRange(0, Globals::myMapsRecordsSorted.Length);

        for (uint i = 0; i < Globals::myMapsRecords.Length; i++)
            Globals::myMapsRecordsSorted.InsertLast(@Globals::myMapsRecords[i]);

        sortLastYield = Time::Now;

        Globals::myMapsRecordsSorted = QuickSortRecords(Globals::myMapsRecordsSorted, sortFunctions[Settings::myMapsRecordsSortMethod]);

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
        Locks::sortMyMapsRecords = false;

        startnew(Database::SaveCoro);
    }

    void MyRecordsCoro() {
        while (Locks::sortMyRecords)
            yield();
        Locks::sortMyRecords = true;
        string timerId = Log::TimerBegin("sorting my records");
        string statusId = "sort-my-records";

        Globals::myRecordsSorted.RemoveRange(0, Globals::myRecordsSorted.Length);

        for (uint i = 0; i < Globals::myRecords.Length; i++)
            Globals::myRecordsSorted.InsertLast(@Globals::myRecords[i]);

        sortLastYield = Time::Now;

        Globals::myRecordsSorted = QuickSortRecords(Globals::myRecordsSorted, sortFunctions[Settings::myRecordsSortMethod]);

        Globals::status.Delete(statusId);
        Log::TimerEnd(timerId);
        Locks::sortMyRecords = false;
    }
}