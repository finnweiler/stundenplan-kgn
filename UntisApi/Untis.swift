//
//  main.swift
//  timetable-iphone
//
//  Created by Finn Weiler on 13.02.18.
//  Copyright © 2018 Finn Weiler. All rights reserved.
//

import Foundation


public class Untis {
    
    public static var username: String {
        if let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared") {
            return defaults.string(forKey: "username") ?? ""
        } else {
            return ""
        }
    }
    public static var password: String {
        if let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared") {
            return defaults.string(forKey: "password") ?? ""
        } else {
            return ""
        }
    } //"eqt-f79-3V2-3aL"
    
    internal static var sessionId: String?
    internal static var klasseId: Int?
    
    internal static var filteredCourses: Dictionary<Int, Bool> = {
        guard let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared") else { return [:] }
        return (NSKeyedUnarchiver.unarchiveObject(with: defaults.data(forKey: "courses") ?? Data()) as? Dictionary<Int, Bool>) ?? [:]
    }()
    
    private static func saveFilteredCourses() {
        if let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared") {
            defaults.removeObject(forKey: "lastFetch")
            defaults.removeObject(forKey: "today")
            defaults.removeObject(forKey: "tomorrow")
            defaults.set(NSKeyedArchiver.archivedData(withRootObject: filteredCourses), forKey: "courses")
            defaults.synchronize()
        }
    }
    
    
    /* [
        119: true, // PHILO
        27: true, // DEUTSCH
        161: true, // SOWI
        97: true, // MATHE
        136: true, // SPORT
        35: true, // ENGLISCH
        111: true, // PHYSIK
        155: true, // GESCHI
        76: true, // KUNST
        64: true  // INFO
        ]*/
    
    public static func setUserCredentials(username: String, password: String) {
        if let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared") {
            defaults.set(username, forKey: "username")
            defaults.set(password, forKey: "password")
            defaults.synchronize()
        }
    }
    
    public static func addElement(id: Int) {
        filteredCourses[id] = true
        saveFilteredCourses()
    }
    
    public static func removeElement(id: Int) {
        filteredCourses.removeValue(forKey: id)
        saveFilteredCourses()
    }
    
    public static func syncCourses() {
        filteredCourses = {
            guard let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared") else { return [:] }
            return (NSKeyedUnarchiver.unarchiveObject(with: defaults.data(forKey: "courses") ?? Data()) as? Dictionary<Int, Bool>) ?? [:]
        }()
    }
    
    public static func reset() {
        if let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared") {
            filteredCourses = [:]
            defaults.removePersistentDomain(forName: "group.com.finnweiler.shared")
            defaults.synchronize()
        }
    }
    
    public static func auth(completion: @escaping ((_ success: Bool) -> Void)) {
        
        request(Request(id: "auth", type: .authenticate, params: ["user" : .string(username), "password": .string(password)]), completion: { (data) in
            let decoder = JSONDecoder()
            let authResponse = try! decoder.decode(AuthenticationResponse.self, from: data)
            sessionId = authResponse.result.sessionId
            klasseId = authResponse.result.klasseId
            print("Successfully logged into Account '\(username)'...")
            completion(true)
        }) { (error, errorResponse) in
            print("internal error: ", error ?? "-", " | ", "server error: ", errorResponse?.error.message ?? "-")
            completion(false)
        }
    }
    
    public static func fetchLessons(date: Date, completion: @escaping ((TimetableResponse?) -> Void)) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyy-MM-dd"
        
        guard let klasseId = klasseId else { return }
        
        request(Request(type: .getTimetable, params: [URLQueryItem(name: "elementType", value: "1"),
                                                      URLQueryItem(name: "elementId", value: "\(klasseId)"),
                                                      URLQueryItem(name: "date", value: formatter.string(from: date)),
                                                      URLQueryItem(name: "formatId", value: "2")]), completion: { (data) in
            
                                                        let decoder = JSONDecoder()
                                                        let rawResponse = try? decoder.decode(CustomResponse.self, from: data)
                                                        
                                                        completion(rawResponse?.data.result.data)
        }, error: { (error, _) in
            completion(nil)
        })
    }
}
