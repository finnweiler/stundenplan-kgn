//
//  Untis+Requests.swift
//  timetable-iphone
//
//  Created by Finn Weiler on 13.02.18.
//  Copyright © 2018 Finn Weiler. All rights reserved.
//

import Foundation

extension Untis {
    
    static func auth(completion: @escaping ((_ success: Bool) -> Void)) {
        request(.authenticate, params: ["user" : .string(username), "password": .string(password)], completion: { (data) in
            let decoder = JSONDecoder()
            let authResponse = try! decoder.decode(AuthenticationResponse.self, from: data)
            sessionId = authResponse.result.sessionId
            print("Successfully logged into Account '\(username)'...")
            completion(true)
        }) { (error, errorResponse) in
            print("internal error: ", error ?? "-", " | ", "server error: ", errorResponse?.error.message ?? "-")
            completion(false)
        }
    }
    
    static func fetchLessons(completion: @escaping ((Array<LessonsResponse.Lesson>?) -> Void)) {
        request(.fetchLessons, params: ["id": .int(39),
                                        "type": .int(1),
                                        "startDate": .int(20180217),
                                        "endDate": .int(20180216)], completion: { (data) in
            let decoder = JSONDecoder()
            let lessonResponse = try! decoder.decode(LessonsResponse.self, from: data)
            completion(lessonResponse.result)
        }) { (error, errorResponse) in
            completion(nil)
        }
    }
    
    
    internal struct RequestBody: Encodable {
        let id: String
        let method: RequestMethods
        let params: [String : MetadataType]
        let jsonrpc = "2.0"
        
        enum MetadataType: Encodable {
            case int(Int)
            case string(String)
            case dic(Dictionary<String, MetadataType>)
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .int(let int):
                    try container.encode(int)
                case .string(let string):
                    try container.encode(string)
                case .dic(let dic):
                    try container.encode(dic)
                }
            }
        }
        
        var data: Data {
            let encoder = JSONEncoder()
            
            do {
                return try encoder.encode(self)
            } catch {
                fatalError("Could not encode requestBody")
            }
        }
    }
    
    internal static func request(_ method: RequestMethods, params: [String: RequestBody.MetadataType], completion: @escaping ((Data) -> Void), error completionWithError: ((Error?, ErrorResponse?) -> Void)?) {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "borys.webuntis.com"
        urlComponents.path = "/WebUntis/jsonrpc.do"
        urlComponents.queryItems = [URLQueryItem(name: "school", value: "kopernikus-gym-nk")]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "text/plain"
        headers["JSESSIONID"] = sessionId
        request.allHTTPHeaderFields = headers
        
        request.httpBody = RequestBody(id: "req", method: method, params: params).data
        
        //print("jsonData: ", String(data: request.httpBody!, encoding: .utf8) ?? "no body data")
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            print("jsonData: ", String(data: responseData ?? Data(), encoding: .utf8) ?? "no response data")
            DispatchQueue.main.async {
                if let error = responseError {
                    completionWithError?(error, nil)
                } else if let jsonData = responseData {
                    let decoder = JSONDecoder()
                    if let errorResponse = try? decoder.decode(ErrorResponse.self, from: jsonData) {
                        completionWithError?(nil, errorResponse)
                    } else {
                        completion(jsonData)
                    }
                } else {
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Data was not retrieved from request"]) as Error
                    completionWithError?(error, nil)
                }
            }
        }
        
        task.resume()
    }
    
}
