//
//  CloudNotesHTTP.swift
//  NCloud.notes
//
//  Created by Sergey Didanov on 25.01.17.
//  Copyright © 2017 Sergey Didanov. All rights reserved.
//

import Foundation
import Alamofire
import SwiftKeychainWrapper
import CoreData

class CloudNotesHTTP {
    static let instance = CloudNotesHTTP()
    
    // Check connection to remote server using credentials as arguments
    func connectToServerUsing(server: String, username: String, password: String, checkConnectionHandler:@escaping (Bool) -> Void) {
        guard let httpRequest = prepareHttpRequest() else { checkConnectionHandler(false); return }
        Alamofire.request(httpRequest).validate().responseJSON { response in
            if response.result.isSuccess {
                // if Success save notes to CoreData
                CloudNotesModel.instance.saveRemoteNotes(notesArray: response.result.value as! [AnyObject])
                checkConnectionHandler(true)
            } else {
                checkConnectionHandler(false)
            }
        }
    }
    
    // Get all notes from server
    func getRemoteNotes(completeHandler:@escaping ([AnyObject]?) -> Void) {
        guard let httpRequest = prepareHttpRequest() else { completeHandler(nil); return }
        Alamofire.request(httpRequest).validate().responseJSON { response in
            if response.result.isSuccess {
                // If Success return JSON response from the server
                completeHandler(response.result.value as? [AnyObject])
            } else {
                completeHandler(nil)
            }
        }
    }
    
    func updateRemoteNotes(fromLocal: [NSManagedObjectID], updateRemoteNotesHandler:@escaping (Bool) -> Void) {
        
    }
    
    private func prepareHttpRequest() -> URLRequest? {
        let noteApiBaseURL = "/index.php/apps/notes/api/v0.2/notes"
        // Get credentials from Keychain
        guard let serverName = KeychainWrapper.standard.string(forKey: "server"),
            let userName = KeychainWrapper.standard.string(forKey: "username"),
            let password = KeychainWrapper.standard.string(forKey: "password") else { return nil }
        // Init URLRequest
        let url = "https://" + serverName + noteApiBaseURL
        var request = URLRequest(url: URL(string: url)!)
        // Setup base URLRequest atributes
        request.timeoutInterval = 10
        request.httpMethod = "GET"
        // Add HTTP Basic Authentication
        let userPasswordString = "\(userName):\(password)"
        let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)
        let base64EncodedCredential = userPasswordData!.base64EncodedString()
        let authString = "Basic \(base64EncodedCredential)"
        request.setValue(authString, forHTTPHeaderField: "Authorization")
        
        return request
    }
}
