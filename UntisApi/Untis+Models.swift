//
//  Untis+Models.swift
//  timetable-iphone
//
//  Created by Finn Weiler on 13.02.18.
//  Copyright © 2018 Finn Weiler. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

extension Untis {
    
    public class ErrorResponse: Decodable {
        public let id: String
        public let error: UntisError
        
        init(id: String, error: UntisError) {
            self.id = id
            self.error = error
        }
        
        public struct UntisError: Decodable {
            public let message: String
            public let code: Int
        }
    }
    
    public class AuthenticationResponse: Decodable {
        public let id: String
        public let result: UserInfo
        
        public struct UserInfo: Decodable {
            public let sessionId: String
            public let personType: Int
            public let personId: Int
            public let klasseId: Int
        }
    }
    
    
    public struct CustomResponse: Decodable {
        public let data: A
        public struct A: Decodable {
            public let result: B
            public struct B: Decodable {
                public let data: TimetableResponse
            }
        }
    }
    
    public class TimetableResponse: Decodable {
        
        required public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            
            guard let klassenId = Untis.klasseId else { throw NSError() }
            guard let periods = (try values.decode(Dictionary<Int, Array<Period>>.self, forKey: .periods))[klassenId] else { throw NSError() }
            
            self.periods = periods
            self.elements = try values.decode(Array<Element>.self, forKey: .elements)
            
            for period in self.periods {
                period.elements.forEach({ (ref) in
                    if ref.type == 3 { // lesson
                        period.course = elements.first(where: { (course) -> Bool in return course.type == 3 && course.id == ref.id })
                    } else if ref.type == 4 { // room
                        period.room = elements.first(where: { (room) -> Bool in return room.type == 4 && room.id == ref.id })
                    }
                })
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case periods = "elementPeriods"
            case elements
        }
        
        public let periods: Array<Period>
        public let elements: Array<Element>
        
        public var userPeriods: Array<Period> {
            return periods.filter({ (period) -> Bool in
                guard let course = period.course else { return false }
                return Untis.filteredCourses[course.id] == true
            })
        }
        
        public class Period: Decodable {
            public let id: Int
            public let lessonId: Int
            public let lessonNumber: Int
            public let date: Int
            public let startTime: Int
            public let endTime: Int
            
            public let cellState: String
            public let elements: Array<ElementRef>
            
            public var room: Element?
            public var course: Element?
            
            
            public var startTimeMinutes: Int { return convertAPITime(t: startTime) }
            public var endTimeMinutes: Int { return convertAPITime(t: endTime) }
            
            public class ElementRef: Decodable {
                public let id: Int
                public let type: Int
                public let state: String
                
                public init(id: Int, type: Int, state: String) {
                    self.id = id
                    self.type = type
                    self.state = state
                }
            }
            
            public func displayableString() -> NSAttributedString {
                let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared")
                let cancelRgb = defaults?.integer(forKey: "colorCancel") ?? 0xFF0000
                let examRgb = defaults?.integer(forKey: "colorExam") ?? 0x00FF00
                if let name = course?.name.split(separator: " ").first {
                    switch cellState {
                    case "STANDARD": return NSAttributedString(string: "\(name)")
                    case "ROOMSUBSTITUTION":
                        if let displayRoom = room?.displayname.split(separator: " ").first {
                            let str = NSMutableAttributedString()
                            str.append(NSAttributedString(string: "\(name)("))
                            str.append(NSAttributedString(string: "\(displayRoom)", attributes: [NSAttributedString.Key.foregroundColor : UIColor(rgb: cancelRgb)]))
                            str.append(NSAttributedString(string: ")"))
                            return str
                        } else {
                            return NSAttributedString(string: "\(name)(err)")
                        }
                    case "EXAM": return NSAttributedString(string: "\(name)", attributes: [
                        NSAttributedString.Key.foregroundColor : UIColor(rgb: examRgb)//UIColor(red: 0, green: 155/255, blue: 36/255, alpha: 1)
                        ])
                    default: return NSAttributedString(string: "\(name)", attributes: [
                        NSAttributedString.Key.foregroundColor : UIColor(rgb: cancelRgb),
                        ])
                    }
                } else {
                    return NSAttributedString(string: "Err")
                }
            }
            
            @available(iOSApplicationExtension 14.0, *)
            public func displayableLesson() -> Lesson {
                let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared")
                let cancelRgb = defaults?.integer(forKey: "colorCancel") ?? 0xFF0000
                let examRgb = defaults?.integer(forKey: "colorExam") ?? 0x00FF00
                if let name = course?.name.split(separator: " ").first {
                    switch cellState {
                    case "STANDARD":
                        return Lesson(text: String(name), color: Color(UIColor.label), room: nil)
                    case "ROOMSUBSTITUTION":
                        if let displayRoom = room?.displayname.split(separator: " ").first {
                            return Lesson(text: String(name), color: Color(rgb: cancelRgb), room: String(displayRoom))
                        } else {
                            return Lesson(text: String(name), color: .yellow, room: "err")
                        }
                    case "EXAM":
                        return Lesson(text: String(name), color: Color(rgb: examRgb), room: nil)
                    default:
                        return Lesson(text: String(name), color: Color(rgb: cancelRgb), room: nil)
                    }
                } else {
                    return Lesson(text: "err", color: .yellow, room: nil)
                }
            }
            
            private func convertAPITime(t: Int) -> Int {
                var timeStr = "\(t)"
                if (timeStr.count == 3) { timeStr = "0\(timeStr)" }
                let hours = timeStr.prefix(2)
                let minutes = timeStr.suffix(2)
                let minutesTotal = Int(hours)! * 60 + Int(minutes)!
                return minutesTotal
            }
        }
        
        public class Element: Decodable {
            public let id: Int
            public let type: Int
            public let name: String
            public let longName: String
            public let displayname: String
            
            public init(id: Int, type: Int, name: String, longName: String, displayname: String) {
                self.id = id
                self.type = type
                self.name = name
                self.longName = longName
                self.displayname = displayname
            }
        }
    }
}

extension UIColor {
    private convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

@available(iOSApplicationExtension 14.0, *)
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
