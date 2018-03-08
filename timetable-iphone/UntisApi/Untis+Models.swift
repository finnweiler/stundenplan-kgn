//
//  Untis+Models.swift
//  timetable-iphone
//
//  Created by Finn Weiler on 13.02.18.
//  Copyright © 2018 Finn Weiler. All rights reserved.
//

import Foundation



protocol UntisRequestableResponse: Decodable {
    static var requestMethod: Untis.RequestMethods { get }
}

extension Untis {
    
    enum RequestMethods: String, Encodable {
        case authenticate = "authenticate"
        case fetchLessons = "getTimetable"
        case fetchSubjects = "getSubjects"
    }
    
    struct ErrorResponse: Decodable {
        let id: String
        let error: UntisError
        
        
        struct UntisError: Decodable {
            let message: String
            let code: Int
        }
    }
    
    struct AuthenticationResponse: Decodable, UntisRequestableResponse {
        let id: String
        let result: UserInfo
        
        static let requestMethod = RequestMethods.authenticate
        
        struct UserInfo: Decodable {
            let sessionId: String
            let personType: Int
            let personId: Int
            let klasseId: Int
        }
    }
    
    struct SubjectsResponse: Decodable, UntisRequestableResponse {
        let id: String
        let result: Array<Subject>
        
        static let requestMethod = RequestMethods.fetchSubjects
        
        struct Subject: Decodable {
            let id: Int
            let name: String
            let longName: String
        }
    }
    
    struct LessonsResponse: Decodable, UntisRequestableResponse {
        let id: String
        let result: Array<Lesson>
        
        static let requestMethod = RequestMethods.fetchLessons
        
        struct Lesson: Decodable {
            let id: Int
            private let dateString: Int
            private let startTimeString: Int
            private let endTimeString: Int
            private let codeString: String
            
            var date: Date {
                let formatter = DateFormatter()
                formatter.dateFormat = "YYYYMMDD"
                return formatter.date(from: "\(dateString)")!
            }
            
            var startTime: Date {
                let formatter = DateFormatter()
                formatter.dateFormat = "HHMM"
                return formatter.date(from: "\(startTimeString)")!
            }
            
            var endTime: Date {
                let formatter = DateFormatter()
                formatter.dateFormat = "HHMM"
                return formatter.date(from: "\(endTimeString)")!
            }
            
            var code: Code {
                switch codeString {
                case "":
                    return .scheduled
                case "cancelled":
                    return .cancelled
                case "irregular":
                    return .irregular
                default:
                    return .unknown
                }
            }
            
            enum CodingKeys: String, CodingKey {
                case id
                case dateString = "date"
                case startTimeString = "startTime"
                case endTimeString = "endTime"
                case codeString = "code"
            }
            
            enum Code: String {
                case scheduled = ""
                case cancelled = "cancelled"
                case irregular = "irregular"
                case unknown
            }
        }
    }
}
