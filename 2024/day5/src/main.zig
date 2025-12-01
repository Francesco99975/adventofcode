const std = @import("std");
const Rule = @import("models/rule.zig").Rule;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file = try std.fs.cwd().openFile("data.txt", .{});

    const stream = file.reader();


    var rules = std.ArrayList(Rule()).init(allocator);

    // Create a chapters: an ArrayList of ArrayLists
    var chapters = std.ArrayList(std.ArrayList(u32)).init(allocator);

    defer {
        // Clean up all rows first
        for (chapters.items) |row| {
            row.deinit();
        }
        // Then clean up the outer ArrayList
        chapters.deinit();
    }

    defer rules.deinit();


    var end_of_rules = false;

    while (try stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        defer allocator.free(line);

        if(line.len == 0) {
            end_of_rules = true;
            continue;
        }

        if(end_of_rules) {
            // Split the line into two parts
            var tokenizer = std.mem.tokenize(u8, line, ",");

            var chapter = std.ArrayList(u32).init(allocator);

            while (tokenizer.next()) |token| {
                const value: u32 = try std.fmt.parseInt(u32, token, 10);
                try chapter.append(value);
            }

            try chapters.append(chapter);
        } else {
            // Split the line into two parts
            var tokenizer = std.mem.tokenize(u8, line, "|");

            const left = try std.fmt.parseInt(u32, tokenizer.next() orelse "", 10);
            const right = try std.fmt.parseInt(u32, tokenizer.next() orelse "", 10);

            const rule = Rule().init(left, right);

            try rules.append(rule);
        }
    }

    std.debug.print("RULES LEN: {} --- chapters LEN {}\n", .{ rules.items.len, chapters.items.len });

    var problematic_chapters = try part1(&chapters, &rules);

    try part2(&problematic_chapters, &rules);
}

fn part2(problematic_chapters: *std.ArrayList(std.ArrayList(u32)), rules: *std.ArrayList(Rule())) !void {
    
    std.debug.print("\nPROBLEMATIC CHAPTERS Chapters LEN {}\n", .{ problematic_chapters.items.len });

    var sum_of_middle_elements: u32 = 0;

    while(true) {
        var fixes_made = false;

        for (problematic_chapters.items, 0..) |chapter, i| {
            for(chapter.items, 0..) |page, current_page_index| {
                for (0..chapter.items.len) |index| {
                    for (rules.items) |rule| {
                        const next_element_index = index + current_page_index + 1;
                        if(next_element_index < chapter.items.len) {
                            if(rule.isRuleBroken(page, chapter.items[next_element_index])) {
                                std.debug.print("FIXING CHAPTER {} CAUSE: <RULE BROKEN -> {}|{} AGAINST {}--{}> CURRENT STATE {any}", .{ i + 1, rule.left, rule.right, page, chapter.items[next_element_index], chapter.items});
                                
                                const tmp = chapter.items[current_page_index];
                                chapter.items[current_page_index] = chapter.items[next_element_index];
                                chapter.items[next_element_index] = tmp;

                                std.debug.print(" FIXED TO -> {any}\n\n", .{ chapter.items });

                                fixes_made = true;
                            }
                        }
                    }
                }
            }
        }

        if(!fixes_made) break;
    }

    

    for (problematic_chapters.items) |chapter| {
        const middle_index = chapter.items.len / 2;

        sum_of_middle_elements += chapter.items[middle_index];
    }

    std.debug.print("\n\n< PART 2 > SUM OF MIDDLE PROBLEMATIC CHAPTERS: {}\n", .{ sum_of_middle_elements });
}


fn part1(chapters: *std.ArrayList(std.ArrayList(u32)), rules: *std.ArrayList(Rule())) !std.ArrayList(std.ArrayList(u32)) {
    const allocator = std.heap.page_allocator;
    var approved_chapters = std.ArrayList(std.ArrayList(u32)).init(allocator);
    defer approved_chapters.deinit();
    var problematic_chapters = std.ArrayList(std.ArrayList(u32)).init(allocator);
    defer problematic_chapters.deinit();

    for (chapters.items, 0..) |chapter, i| {
        var approved = true;
        std.debug.print("CHECKING CHAPTER {}\n", .{ i + 1 });
        outer: for (chapter.items, 0..) |page, current_page_index| {
             for (0..chapter.items.len) |index| {
                for (rules.items) |rule| {
                    const next_element_index = index + current_page_index + 1;
                    if(next_element_index < chapter.items.len) {
                        //std.debug.print("CHECKING RULE: {}|{} AGAINST ELEMETS: {}--{}\n", .{ rule.left, rule.right,  page, chapter.items[next_element_index]});
                        if(rule.isRuleBroken(page, chapter.items[next_element_index])) {
                            std.debug.print("CHAPTER {} INVALIDATED <RULE BROKEN -> {}|{} AGAINST {}--{}>\n\n", .{ i + 1, rule.left, rule.right, page, chapter.items[next_element_index]});
                            try problematic_chapters.append(chapter);
                            approved = false;
                            break :outer;
                        }
                    }
                }
            }
        }
        if (approved) { 
            std.debug.print("CHAPTER {} APPROVED <RULES FOLLOWED>\n\n", .{ i + 1 });
            try approved_chapters.append(chapter);
        }
    }

    std.debug.print("\nAPPROVED Chapters LEN {}\n", .{ approved_chapters.items.len });

    var sum_of_middle_elements: u32 = 0;

    for (approved_chapters.items) |chapter| {
        const middle_index = chapter.items.len / 2;

        sum_of_middle_elements += chapter.items[middle_index];
    }

    std.debug.print("\n\n< PART 1 > SUM OF MIDDLE APPROVED CHAPTERS: {}\n", .{ sum_of_middle_elements });

    return problematic_chapters.clone();
}
