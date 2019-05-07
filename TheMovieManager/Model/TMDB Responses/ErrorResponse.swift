//
//  ErrorResponse.swift
//  TheMovieManager
//
//  Created by 中尾 佳代 on 2019/05/07.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation

struct ErrorResponse: Codable{
    let statusCode: Int
    let statusMessage: String
    
    enum CodingKeys:String, CodingKey{
        case statusCode = "status_code"
        case statusMessage = "status_message"
    }
}
