//
//  HTTPClient.swift
//  NCloud.notes
//
//  Created by Sergey Didanov on 01.01.17.
//  Copyright © 2017 Sergey Didanov. All rights reserved.
//

import Foundation
import Alamofire



class HTTPClient {
    let noteApiBaseURL = "/index.php/apps/notes/api/v0.2/notes"
    
    // Check connection to remote server using credentials as arguments
    func checkServerConnUsing(server: String, username: String, password: String, checkConnectionHandler:@escaping (Bool) -> Void) {
        var headers: HTTPHeaders = [:]
        if let authorizationHeader = Request.authorizationHeader(user: username, password: password) {
            headers[authorizationHeader.key] = authorizationHeader.value }
        let requestURL = "https://" + server + noteApiBaseURL
        print(requestURL)
        Alamofire.request(requestURL, headers: headers).validate().responseJSON { response in
            switch response.result {
            case .success:
                checkConnectionHandler(true)
            case .failure:
                checkConnectionHandler(false)
            }
        }
    }
    
    
    func makeHttpRequest(url: String) {
        
    }
}


