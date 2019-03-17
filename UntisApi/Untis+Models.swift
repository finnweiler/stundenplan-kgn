//
//  Untis+Models.swift
//  timetable-iphone
//
//  Created by Finn Weiler on 13.02.18.
//  Copyright © 2018 Finn Weiler. All rights reserved.
//

import Foundation
import UIKit


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
                if let name = course?.name.split(separator: " ").first {
                    switch cellState {
                    case "STANDARD": return NSAttributedString(string: "\(name)")
                    case "ROOMSUBSTITUTION":
                        if let displayRoom = room?.displayname.split(separator: " ").first {
                            let str = NSMutableAttributedString()
                            str.append(NSAttributedString(string: "\(name)("))
                            str.append(NSAttributedString(string: "\(displayRoom)", attributes: [NSAttributedString.Key.foregroundColor : UIColor.red]))
                            str.append(NSAttributedString(string: ")"))
                            return str
                        } else {
                            return NSAttributedString(string: "\(name)(err)")
                        }
                    case "EXAM": return NSAttributedString(string: "\(name)", attributes: [
                        NSAttributedString.Key.foregroundColor : UIColor.green,
                        ])
                    default: return NSAttributedString(string: "\(name)", attributes: [
                        NSAttributedString.Key.foregroundColor : UIColor.red,
                        ])
                    }
                } else {
                    return NSAttributedString(string: "Err")
                }
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
