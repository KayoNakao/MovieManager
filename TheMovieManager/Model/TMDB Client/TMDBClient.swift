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
        case markWatchlist
        case markFavorite
        case posterImageUrl(String)
        
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
            
            case .markWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
                
            case .markFavorite: return Endpoints.base + "/account/\(Auth.accountId)/favorite" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
                
            case .posterImageUrl(let posterPath): return "https://image.tmdb.org/t/p/w500/\(posterPath)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    @discardableResult class func taskForGetRequest<ResponseType: Decodable>(url: URL, response: ResponseType.Type, completion: @escaping(ResponseType?, Error?)-> Void) -> URLSessionTask{
        
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
                    let errorResponse = try decoder.decode(TMDBResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                }catch{
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
        
        return task
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
            let decoder = JSONDecoder()
            do{
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            }catch{
                do{
                    let errorObject = try decoder.decode(TMDBResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil, errorObject)
                    }
                }catch{
                    DispatchQueue.main.async {
                        completion(nil,error)
                    }
                    
                }

                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
        
    }
    
    class func getRequestToken(completion: @escaping (Bool, Error?)->Void){
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
    
    class func search(query:String, completion: @escaping([Movie], Error?)->Void)-> URLSessionTask{
        let task = taskForGetRequest(url: Endpoints.search(query).url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            }else {
                completion([], error)
            }
        }
        return task
    }
    
    class func markWatchlist(movieId:Int, watchlist:Bool, completion: @escaping(Bool, Error?)->Void){
        let body = MarkWatchlist(mediaType:"movie", mediaId: movieId, watchlist: watchlist)
        taskForPostRequest(url: Endpoints.markWatchlist.url, response: TMDBResponse.self, body: body) { (response, error) in
            if let response = response {
                completion(response.statusCode ==
                             1 || response.statusCode ==
                            12 || response.statusCode ==
                            13, nil)
            }else {
                print(response?.statusMessage ?? "Fail adding to watchlist")
                completion(false, error)
            }
        }
    }
    
    class func markFavorite(mediaId:Int, favorite:Bool, completion:@escaping(Bool, Error?)->Void){
        let body = MarkFavorite(mediaType:"movie", mediaId: mediaId, favorite: favorite)
        taskForPostRequest(url: Endpoints.markFavorite.url, response: TMDBResponse.self, body: body) { (response, error) in
            if let response = response {
                completion(response.statusCode ==
                             1 || response.statusCode ==
                            12 || response.statusCode ==
                            13, nil)
            }else {
                print(response?.statusMessage ?? "Fail marking as favorite")
                completion(false, error)
            }
        }
    }
    
    class func downloadImage(posterPath:String, completion:@escaping(Data?, Error?)->Void){
        let task = URLSession.shared.dataTask(with: Endpoints.posterImageUrl(posterPath).url) { (data, response, error) in
            DispatchQueue.main.async {
                completion(data, nil)
            }
        }
        task.resume()
    }
    
}
