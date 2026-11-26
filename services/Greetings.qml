pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var lines: ({
        "lateNight": [
            ["Late night, %1?", "The quiet hours are the best for focus."],
            ["Still up, %1?", "Don't forget to drink some water."],
            ["Night owl mode.", "Just one more thing before bed?"],
            ["Burning the midnight oil, %1?", "Your future self will want some sleep."],
            ["Hello, fellow insomniac.", "The world is asleep. Your turn soon."]
        ],
        "morning": [
            ["Good morning, %1.", "Coffee first, then everything else."],
            ["Ready to start, %1?", "A new day, a fresh start."],
            ["Early start today?", "Let's make it count."],
            ["Morning, %1.", "What are we making today?"],
            ["Up and running, %1?", "Breakfast counts as productivity."]
        ],
        "afternoon": [
            ["Good afternoon, %1.", "Past the halfway mark."],
            ["Afternoon slump?", "A short walk works wonders."],
            ["How's the day going, %1?", "Keep the momentum."],
            ["Coffee number two?", "No judgement here."],
            ["Focus time, %1.", "Close a few tabs, you'll feel better."]
        ],
        "evening": [
            ["Good evening, %1.", "Time to slow down a little."],
            ["Winding down, %1?", "You did enough for today."],
            ["Evening, %1.", "Something good to watch tonight?"],
            ["Still at it?", "Remember to take a break."],
            ["Long day, %1?", "The couch is calling."]
        ],
        "night": [
            ["Good night, %1.", "Almost time to call it a day."],
            ["Late shift, %1?", "Don't stay up too late."],
            ["Last round for today?", "Save your work and get some rest."],
            ["Night mode on, %1.", "Your eyes will thank you."]
        ],
        "friday": [
            ["It's Friday, %1!", "The weekend is right there."]
        ],
        "weekend": [
            ["Weekend mode, %1.", "No rush today."]
        ],
        "monday": [
            ["Monday again, %1?", "One step at a time."]
        ]
    })

    function periodFor(date) {
        const hour = date.getHours();
        if (hour < 5)
            return "lateNight";
        if (hour < 12)
            return "morning";
        if (hour < 18)
            return "afternoon";
        if (hour < 22)
            return "evening";
        return "night";
    }

    function candidates(date) {
        const hour = date.getHours();
        const day = date.getDay();
        let pool = root.lines[root.periodFor(date)].slice();
        if (day === 5 && hour >= 17)
            pool = pool.concat(root.lines.friday);
        if ((day === 6 || day === 0) && hour >= 8 && hour < 20)
            pool = pool.concat(root.lines.weekend);
        if (day === 1 && hour >= 5 && hour < 12)
            pool = pool.concat(root.lines.monday);
        return pool;
    }

    function pick(name, date, salt) {
        const pool = root.candidates(date);
        const key = `${date.getFullYear()}-${date.getMonth()}-${date.getDate()}-${date.getHours()}-${salt}`;
        let hash = 0;
        for (let i = 0; i < key.length; i++)
            hash = (hash * 31 + key.charCodeAt(i)) | 0;
        const line = pool[Math.abs(hash) % pool.length];
        return {
            "title": Translation.tr(line[0]).replace("%1", name),
            "subtitle": Translation.tr(line[1])
        };
    }
}
