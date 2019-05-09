//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.


import Foundation

class TMDBClient {
    
    static let apiKey = "API_KEY"
    
    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        static let getRequest = "/authentication/token/new"
        
        
        case getWatchlist
        case getRequestToken
        case login
        case createSeesionId
        case webAuth
        case logout
        case getFavorites
        case search(String)
        
        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            
            case .getRequestToken: return Endpoints.base + Endpoints.getRequest + Endpoints.apiKeyParam
                
            case .login: return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
                
            case .createSeesionId: return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
                
            case .webAuth: return "https://www.themoviedb.org/authenticate/" + Auth.requestToken + "?redirect_to=themoviemanager:authenticate"
                
            case .logout: return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
                
            case .getFavorites: return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
                
            case .search(let query): return Endpoints.base + "/search/movie" + Endpoints.apiKeyParam + "&query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func taskForGetRequest<ResponseType: Decodable>(url: URL, response: ResponseType.Type, completion: @escaping(ResponseType?, Error?)-> Void){
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
//                let json = try! JSONSerialization.jsonObject(with: data, options: [])
//                print(json)
                
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do {
                    let responseObject = try decoder.decode(ErrorResponse.self, from: data)
                    print(responseObject.statusMessage)
                }catch{
                    
                }
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
    
    class func taskForPostRequest<RequestType: Encodable, ResponseType: Decodable>(url: URL, response:ResponseType.Type, body:RequestType, completion:@escaping(ResponseType?, Error?)->Void){
        var request = URLRequest(url:url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONEncoder().encode(body)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            do{
                let decoder = JSONDecoder()
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            }catch{
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
    
    class func getRequestToken(completion: @escaping (Bool, Error?)->Void) {
        taskForGetRequest(url: Endpoints.getRequestToken.url, response: RequestTokenResponse.self) { (response, error) in
            if let response = response {
                Auth.requestToken = response.requestToken
                completion(true, nil)
            }else {
                completion(false, error)
            }
        }
    }
    
    
    class func login(username:String, password:String, completion: @escaping(Bool, Error?)-> Void){
        let body = LoginRequest(username: username, password:password, requestToken: Auth.requestToken)
        
        taskForPostRequest(url: Endpoints.login.url, response: RequestTokenResponse.self, body: body) { (response, error) in
            if let response = response {
                Auth.requestToken = response.requestToken
                    completion(true, nil)
            }else {
                    completion(false, error)
            }
        }
    }
    
    class func createSessionId(completion: @escaping (Bool, Error?)-> Void){
        
        let body = PostSession(requestToken: Auth.requestToken)

        taskForPostRequest(url: Endpoints.createSeesionId.url, response: SessionResponse.self, body: body) { (response, error) in
            if let response = response {
                Auth.sessionId = response.sessionId
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            }else {
                DispatchQueue.main.async {
                    completion(false, error)
                }
            }
        }
    }
    
    class func logout(complition:@escaping ()->Void){
        var request = URLRequest(url: Endpoints.logout.url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            Auth.requestToken = ""
            Auth.sessionId = ""
            complition()
        }
        task.resume()
    }
    
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        taskForGetRequest(url: Endpoints.getWatchlist.url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            }else {
                completion([], error)
            }
        }
     }
    
    class func getFavorites(completion:@escaping ([Movie], Error?)->Void){
        taskForGetRequest(url: Endpoints.getFavorites.url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            }else {
                completion([], error)
            }
        }
    }
    
    class func search(query:String, completion: @escaping([Movie], Error?)->Void){
        taskForGetRequest(url: Endpoints.search(query).url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            }else {
                completion([], error)
            }
        }
    }
}
