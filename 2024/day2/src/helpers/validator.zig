const std = @import("std");

const MIN_CHANGE = 1;
const MAX_CHANGE = 3;

pub fn isListSafeV2(list: *std.ArrayList(u32), refurbished: bool) bool {
    if (list.items.len < 2) {
        return false;
    }

    if (list.items[0] == list.items[1]) {
        return false;
    }

    var ascending: bool = false;

    if (list.items[1] > list.items[0]) {
        ascending = true;
    }

    for (list.items, 0..) |value, i| {
        const next: usize = i + 1;
        if (list.items.len != next) {
            const next_value = list.items[next];
            if (ascending) {
                if (next_value <= value) {
                    if (!refurbished) {
                        var temp_list = list;
                        _ = temp_list.orderedRemove(next);
                        _ = list.orderedRemove(i);

                        return isListSafeV2(list, true) or isListSafeV2(temp_list, true);
                    } else {
                        return false;
                    }
                }
            } else {
                if (next_value >= value) {
                    if (!refurbished) {
                        var temp_list = list;
                        _ = temp_list.orderedRemove(next);
                        _ = list.orderedRemove(i);

                        return isListSafeV2(list, true) or isListSafeV2(temp_list, true);
                    } else {
                        return false;
                    }
                }
            }

            const max = if (next_value > value) next_value else value;
            const min = if (next_value < value) next_value else value;

            const change: u32 = max - min;

            if (change < MIN_CHANGE or change > MAX_CHANGE) {
                if (!refurbished) {
                    var temp_list = list;
                    _ = temp_list.orderedRemove(next);
                    _ = list.orderedRemove(i);

                    return isListSafeV2(list, true) or isListSafeV2(temp_list, true);
                } else {
                    return false;
                }
            }
        }
    }

    return true;
}

pub fn isListSafe(list: *const std.ArrayList(u32)) bool {
    if (list.items.len < 2) {
        return false;
    }

    if (list.items[0] == list.items[1]) {
        return false;
    }

    var ascending: bool = false;

    if (list.items[1] > list.items[0]) {
        ascending = true;
    }

    for (list.items, 0..) |value, i| {
        const next = i + 1;
        if (list.items.len != next) {
            const next_value = list.items[next];
            if (ascending) {
                if (next_value <= value) {
                    return false;
                }
            } else {
                if (next_value >= value) {
                    return false;
                }
            }

            const max = if (next_value > value) next_value else value;
            const min = if (next_value < value) next_value else value;

            const change: u32 = max - min;

            if (change < MIN_CHANGE or change > MAX_CHANGE) {
                return false;
            }
        }
    }

    return true;
}
