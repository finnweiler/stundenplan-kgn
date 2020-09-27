//
//  widget14.swift
//  widget14
//
//  Created by Finn Weiler on 25.09.20.
//  Copyright © 2020 Finn Weiler. All rights reserved.
//

import WidgetKit
import SwiftUI
import UntisApi

struct TimeTableEntry: TimelineEntry {
    let date: Date
    let todayTitleLabel: String
    let tomorrowTitleLabel: String
    let dayAfterTomorrowTitleLabel: String
    let todayData: Array<UntisApi.Lesson>
    let tomorrowData: Array<UntisApi.Lesson>
    let dayAfterTomorrowData: Array<UntisApi.Lesson>
    let darkRgb: Int
    let brightRgb: Int
}

struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> TimeTableEntry {
        let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared")
        let brightRgb = defaults?.integer(forKey: "colorLightBg") ?? 0xFFFFFF
        let darkRgb = defaults?.integer(forKey: "colorDarkBg") ?? 0
        return TimeTableEntry(date: Date(), todayTitleLabel: "Heute", tomorrowTitleLabel: "Morgen", dayAfterTomorrowTitleLabel: "Übermorgen", todayData: [Lesson(text: "", color: .primary, room: nil)], tomorrowData: [Lesson(text: "", color: .primary, room: nil)], dayAfterTomorrowData: [Lesson(text: "", color: .primary, room: nil)], darkRgb: darkRgb, brightRgb: brightRgb)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TimeTableEntry) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared")
        let brightRgb = defaults?.integer(forKey: "colorLightBg") ?? 0xFFFFFF
        let darkRgb = defaults?.integer(forKey: "colorDarkBg") ?? 0
        completion(TimeTableEntry(date: Date(), todayTitleLabel: "Heute", tomorrowTitleLabel: "Morgen", dayAfterTomorrowTitleLabel: "Übermorgen", todayData:
                                    [
                                        Lesson(text: "SW", color: .primary, room: nil),
                                        Lesson(text: "M", color: .primary, room: nil),
                                        Lesson(text: "M", color: .primary, room: nil),
                                        Lesson(text: "GE", color: .red, room: "H24"),
                                        Lesson(text: "GE", color: .red, room: "H24"),
                                        Lesson(text: "BI", color: .primary, room: nil),
                                    ]
                                  , tomorrowData:
                                    [
                                        Lesson(text: "E", color: .primary, room: nil),
                                        Lesson(text: "E", color: .primary, room: nil),
                                        Lesson(text: "BI", color: .red, room: nil),
                                        Lesson(text: "BI", color: .red, room: nil),
                                        Lesson(text: "GE", color: .primary, room: nil),
                                        Lesson(text: "BI", color: .primary, room: nil),
                                        Lesson(text: "BI", color: .primary, room: nil),
                                    ]
                                  , dayAfterTomorrowData:
                                    [
                                        Lesson(text: "PA", color: .green, room: nil),
                                        Lesson(text: "PA", color: .green, room: nil),
                                        Lesson(text: "PA", color: .green, room: nil),
                                        Lesson(text: "D", color: .red, room: "G01"),
                                        Lesson(text: "D", color: .red, room: "G01"),
                                        Lesson(text: "CH", color: .primary, room: nil),
                                        Lesson(text: "E", color: .primary, room: nil),
                                        Lesson(text: "E", color: .primary, room: nil),
                                    ], darkRgb: darkRgb, brightRgb: brightRgb))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TimeTableEntry>) -> Void) {
        
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        
        Untis.auth { (success) in
            guard success else {
                return
            }
            
            var date = Date()
            
            let day: TimeInterval =  60 * 60 * 24
            let weekday = Calendar.current.component(.weekday, from: date)
            
            var todayTitleLabel: String
            var tomorrowTitleLabel: String
            var dayAfterTomorrowTitleLabel: String
            
            if weekday == 1 {
                date += day
                todayTitleLabel = "Montag"
                tomorrowTitleLabel = "Dienstag"
                dayAfterTomorrowTitleLabel = "Mittwoch"
            } else if weekday == 7 {
                date += day + day
                todayTitleLabel = "Montag"
                tomorrowTitleLabel = "Dienstag"
                dayAfterTomorrowTitleLabel = "Mittwoch"
            } else {
                todayTitleLabel = "Heute"
                tomorrowTitleLabel = "Morgen"
                dayAfterTomorrowTitleLabel = "Übermorgen"
            }
            
            Untis.fetchLessons(date: date, completion: { (timetable) in
                guard timetable != nil else {
                    return
                }
                
                let todayContent = lessonsForDate(timetable: timetable!, date: date)
                let tomorrowContent = lessonsForDate(timetable: timetable!, date: date + day)
                let dayAfterTomorrowContent = lessonsForDate(timetable: timetable!, date: date + day + day)
                
                /*if weekday == 6 {
                    tomorrowContent = [UntisApi.Lesson(text: "Schönes Wochenende!", color: .white, room: nil)]
                }*/
                
                let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared")
                let brightRgb = defaults?.integer(forKey: "colorLightBg") ?? 0xFFFFFF
                let darkRgb = defaults?.integer(forKey: "colorDarkBg") ?? 0
                
                let entry = TimeTableEntry(date: date, todayTitleLabel: todayTitleLabel, tomorrowTitleLabel: tomorrowTitleLabel, dayAfterTomorrowTitleLabel: dayAfterTomorrowTitleLabel, todayData: todayContent, tomorrowData: tomorrowContent, dayAfterTomorrowData: dayAfterTomorrowContent, darkRgb: darkRgb, brightRgb: brightRgb)
                let currentHour = Calendar.current.component(.hour, from: Date())
                var time: Date
                if (weekday > 1 && weekday < 7) {
                    if (currentHour > 5 && currentHour < 9) {
                        time = Date(timeIntervalSinceNow: 60 * 15)
                    } else {
                        time = Date(timeIntervalSinceNow: 60 * 60 * 1)
                    }
                } else {
                    time = Date(timeIntervalSinceNow: 60 * 60 * 2)
                }
                
                var entries: Array<TimeTableEntry> = [entry]
                if let nextDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: date + day) {
                    let entryNextDay = TimeTableEntry(
                        date: nextDate,
                        todayTitleLabel: todayTitleLabel == "Heute" ? "Gestern" : "Montag",
                        tomorrowTitleLabel: tomorrowTitleLabel == "Morgen" ? "Heute" : "Dienstag",
                        dayAfterTomorrowTitleLabel: dayAfterTomorrowTitleLabel == "Übermorgen" ? "Morgen" : "Mittwoch",
                        todayData: todayContent,
                        tomorrowData: tomorrowContent,
                        dayAfterTomorrowData: dayAfterTomorrowContent,
                        darkRgb: darkRgb,
                        brightRgb: brightRgb
                    )
                    entries.append(entryNextDay)
                }
                
                let timeline = Timeline(entries: entries, policy: TimelineReloadPolicy.after(time))
                completion(timeline)
            })
        }
    }
    
    func lessonsForDate(timetable: Untis.TimetableResponse, date: Date) -> Array<UntisApi.Lesson> {
        
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        
        let periods = timetable.userPeriods.filter({ (per) -> Bool in
            return "\(per.date)" ==  f.string(from: date)
        }).sorted(by: { (per1, per2) -> Bool in
            if per1.startTime == per2.startTime {
                return per1.cellState != "EXAM"
            } else {
                return per1.startTime < per2.startTime
            }
        })
        
        var content: Array<UntisApi.Lesson> = []
        var lastPeriod: Untis.TimetableResponse.Period?
        periods.forEach({ (per) in
            if let last = lastPeriod {
                if per.cellState == "EXAM" && per.startTime == last.startTime {
                    content.removeLast()
                }
            }
            content.append(per.displayableLesson())
            lastPeriod = per
        })
        return content
    }
}

struct PlaceholderView: View {
    var body: some View {
        Text("loading")
    }
}

struct LessonView: View {
    let lesson: Lesson
    
    var body: some View {
        if let room = lesson.room {
            Text(lesson.text) +
            Text("(") +
            Text(room)
                .foregroundColor(lesson.color) +
            Text(")")
        } else {
            Text(lesson.text)
                .foregroundColor(lesson.color)
        }
    }
}

struct LessonsView: View {
    let lessons: Array<Lesson>
    
    var body: some View {
        HStack {
            ForEach(lessons, id: \.self) { lesson in
                LessonView(lesson: lesson)
            }
        }
        .font(.system(size: 18, weight: .bold, design: .default))
        .allowsTightening(true)
    }
}

struct LessonText: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .regular, design: .default))
            .opacity(0.5)
    }
}

struct WidgetEntryView: View {
    @Environment(\.colorScheme) var colorScheme
    let entry: Provider.Entry
    
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        ZStack {
            Color(rgb: colorScheme == .dark ? entry.darkRgb : entry.brightRgb)
            VStack {
                Spacer()
                LessonText(text: entry.todayTitleLabel)
                LessonsView(lessons: entry.todayData)
                Spacer()
                LessonText(text: entry.tomorrowTitleLabel)
                LessonsView(lessons: entry.tomorrowData)
                Spacer()
                LessonText(text: entry.dayAfterTomorrowTitleLabel)
                LessonsView(lessons: entry.dayAfterTomorrowData)
                /*Text("Zuletzt aktualisiert um \(formatter.string(from: entry.date)) Uhr")
                    .font(.system(size: 10, weight: .regular, design: .default))
                    .opacity(0.5)*/
                Spacer()
            }
        }
    }
}


@main
struct Widget14: Widget {
    private let kind = "Widget14"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind,
                            provider: Provider()
        ) { (entry) in
            WidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Stundenplan")
    }
}


extension Color {
    
    private init(red: Int, green: Int, blue: Int) {
           assert(red >= 0 && red <= 255, "Invalid red component")
           assert(green >= 0 && green <= 255, "Invalid green component")
           assert(blue >= 0 && blue <= 255, "Invalid blue component")

           self.init(red: Double(red) / 255.0, green: Double(green) / 255.0, blue: Double(blue) / 255.0)
    }
    
    init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
    
    var rgb: Int {
        let rgb =
            (Int(self.components.red * 255.0) << 16) +
            (Int(self.components.green * 255.0) << 8) +
            (Int(self.components.blue * 255.0))
        return rgb
    }
    
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {

        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #endif

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0

        guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &o) else {
            // You can handle the failure here as you want
            return (0, 0, 0, 0)
        }

        return (r, g, b, o)
    }
}

