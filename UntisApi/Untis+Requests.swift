//
//  Untis+Requests.swift
//  timetable-iphone
//
//  Created by Finn Weiler on 13.02.18.
//  Copyright © 2018 Finn Weiler. All rights reserved.
//

import Foundation

extension Untis {
    
    
    internal class Request {
        
        init(id: String, type: JsonType, params: [String: Request.HttpBody.MetadataType]?) {
            httpBody = HttpBody(id: id, method: type.rawValue, params: params ?? [:])
            configuration = Configuration(scheme: "https",
                                          host: "borys.webuntis.com",
                                          path: "/WebUntis/jsonrpc.do",
                                          httpMethod: "POST",
                                          queryItems: [URLQueryItem(name: "school", value: "kopernikus-gym-nk")])
        }
        
        
        init(type: CustomType, params: [URLQueryItem]) {
            configuration = Configuration(scheme: "https",
                                          host: "borys.webuntis.com",
                                          path: "/WebUntis/api/public/timetable/weekly/data",
                                          httpMethod: "GET",
                                          queryItems: params)
        }
        
        let configuration: Configuration
        var httpBody: HttpBody?
        
        enum JsonType: String, Encodable {
            case authenticate = "authenticate"
        }
        
        enum CustomType {
            case getTimetable
        }
        
        struct Configuration {
            let scheme: String
            let host: String
            let path: String
            let httpMethod: String
            let queryItems: [URLQueryItem]
        }
        
        struct HttpBody: Encodable {
            let id: String
            let method: String
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
    }
    
    internal static func request(_ request: Request, completion: @escaping ((Data) -> Void), error completionWithError: ((Error?, ErrorResponse?) -> Void)?) {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = request.configuration.scheme
        urlComponents.host = request.configuration.host
        urlComponents.path = request.configuration.path
        urlComponents.queryItems = request.configuration.queryItems
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = request.configuration.httpMethod
        
        var headers = urlRequest.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "text/plain"
        headers["JSESSIONID"] = sessionId
        urlRequest.allHTTPHeaderFields = headers
        
        urlRequest.httpBody = request.httpBody?.data
        
        //print("jsonData: ", String(data: request.httpBody!, encoding: .utf8) ?? "no body data")
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: urlRequest) { (responseData, response, responseError) in
            //print("jsonData: ", String(data: responseData ?? Data(), encoding: .utf8) ?? "no response data")
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
