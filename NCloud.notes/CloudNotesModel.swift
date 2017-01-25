//
//  HTTPClient.swift
//  NCloud.notes
//
//  Created by Sergey Didanov on 01.01.17.
//  Copyright © 2017 Sergey Didanov. All rights reserved.
//

import Foundation
import Alamofire
import CoreData
import SwiftKeychainWrapper

class CloudNotesModel {
    
    // Check connection to remote server using credentials as arguments
    func connectToServerUsing(server: String, username: String, password: String, checkConnectionHandler:@escaping (Bool) -> Void) {
        guard let httpRequest = prepareHttpRequest() else { checkConnectionHandler(false); return }
        Alamofire.request(httpRequest).validate().responseJSON { response in
            if response.result.isSuccess {
                // if Success save notes to CoreData
                self.addNotesToCoreData(notesArray: response.result.value as! [AnyObject])
                checkConnectionHandler(true)
            } else {
                checkConnectionHandler(false)
            }
        }
    }
    
    // Get all notes from server
    func getNotesFromServer(completeHandler:@escaping ([AnyObject]?) -> Void) {
        guard let httpRequest = prepareHttpRequest() else { completeHandler(nil); return }
        Alamofire.request(httpRequest).validate().responseJSON { response in
            if response.result.isSuccess {
                completeHandler(response.result.value as? [AnyObject])
            } else {
                completeHandler(nil)
            }
        }
    }
    
    func prepareHttpRequest() -> URLRequest? {
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
    
//    func syncLocalNotesToRemote(remoteNotes: [AnyObject], completeHandler:@escaping (Bool) -> Void) {
//        let localNotes = getNotesFromCoreData()
//        for localNote in localNotes {
//            
//        }
//    }
    
    func getNotesFromCoreData() -> [NSManagedObject] {
        var unsortedNotes = [NSManagedObject]()
        // Get access to CoreData managedContext
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return unsortedNotes }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Notes")
        // Get notes from CoreData, sort by modofication time and store to notes
        do {
            unsortedNotes = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return unsortedNotes.count > 0 ? sortNotesByTimestamp(notes: unsortedNotes) : unsortedNotes
    }
    
    func syncRemoteNotesToLocal(remoteNotes: [AnyObject]) {
        var newNotes = [AnyObject]()
        var updatedNotes = [AnyObject]()
        var notesToDelete = [NSManagedObject]()
        let localNotesDict = convertLocalNotesToDictionaryByID(notes: getNotesFromCoreData())
        let remoteNotesDict = convertRemoteNotesToDictionaryByID(notes: remoteNotes)
        // Remove deleted notes
        for (key, value) in localNotesDict {
            if remoteNotesDict[key] == nil {
               notesToDelete.append(value)
            }
        }
        // Updated current or add new notes
        for case let remoteNote as [String:AnyObject] in remoteNotes {
            // If exist local note for remote note
            if let localNote = localNotesDict[remoteNote["id"] as! Int] {
                // If remote note newer then local
                if (localNote.value(forKeyPath: "modified") as? Int)! < remoteNote["modified"] as! Int {
                    // Update it to CoreData
                    print("Find note with new version")
                    updatedNotes.append(remoteNote as AnyObject)
                }
            } else {
                // Add new note to CoreData
                newNotes.append(remoteNote as AnyObject)
            }
        }
        if newNotes.count > 0 {
            addNotesToCoreData(notesArray: newNotes)
        }
        if updatedNotes.count > 0 {
            updateCoreDataNotes(newNotes: updatedNotes)
        }
        if notesToDelete.count > 0 {
            deleteNotes(notes: notesToDelete)
        }
    }
    
    func deleteNotes(notes: [NSManagedObject]) {
        // Get access to CoreData managedContext
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        // Delete notes from context
        for oldNote in notes {
            print("delete note")
            managedContext.delete(oldNote)
        }
        // Try save to CoreData
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Error While Deleting Note: \(error.userInfo)")
        }
    }
    
    func updateCoreDataNotes(newNotes: [AnyObject]) {
        print("Update notes")
        var localNotes = [NSManagedObject]()
        // Get access to CoreData managedContext
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Notes")
        // Get notes from CoreData to localNotes and convert to dictionary [ID:Note]
        do {
            localNotes = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        let localNotesDictionary = convertLocalNotesToDictionaryByID(notes: localNotes)
        // Remove old notes from CoreData
        for case let updatedNote as [String:AnyObject] in newNotes {
            managedContext.delete(localNotesDictionary[(updatedNote["id"] as! Int)]!)
        }
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Error While Deleting Note: \(error.userInfo)")
        }
        // Save updated notes to CoreData
        addNotesToCoreData(notesArray: newNotes)
    }
    
    
    // Convert [NSManagedObject] array to [note_id:NSManagedObject] dictionary
    private func convertLocalNotesToDictionaryByID(notes: [NSManagedObject]) -> [Int:NSManagedObject] {
        var dictionary = [Int:NSManagedObject]()
        for note in notes {
            dictionary[(note.value(forKeyPath: "id") as? Int)!] = note
        }
        return dictionary
    }
    
    // Convert [AnyObject] to [id:AnyObject]
    private func convertRemoteNotesToDictionaryByID(notes: [AnyObject]) -> [Int:AnyObject] {
        var dictionary = [Int:AnyObject]()
        for case let note as [String:AnyObject] in notes {
            dictionary[note["id"] as! Int] = note as AnyObject?
        }
        return dictionary
    }
    
    private func sortNotesByTimestamp(notes: [NSManagedObject]) -> [NSManagedObject]{
        var unsortedNotes = [Int:NSManagedObject]()
        var sortedNotes = [NSManagedObject]()
        for note in notes {
            unsortedNotes[(note.value(forKeyPath: "modified") as? Int)!] = note
        }
        for (_, value) in unsortedNotes.sorted(by: { $0.0 > $1.0 }) {
            sortedNotes.append(value)
        }
        return sortedNotes
    }
    
    private func addNotesToCoreData(notesArray: [AnyObject]) {
        // Declare access to Managed Object Context(Database) and notesEntity(Table) for using Core Data
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let notesEntity = NSEntityDescription.entity(forEntityName: "Notes", in: managedContext)!
        // Save all received notes to managedContext
        for case let note as [String:AnyObject] in notesArray {
            // Insert new empty noteManagedObject(row) into Notes Entity(table)
            let noteManagedObject = NSManagedObject(entity: notesEntity, insertInto: managedContext)
            // Add note attributes to empty ManagedObject
            noteManagedObject.setValue(note["title"] as! String, forKeyPath: "title")
            noteManagedObject.setValue(note["content"] as! String, forKeyPath: "content")
            noteManagedObject.setValue(note["modified"] as! Int, forKeyPath: "modified")
            noteManagedObject.setValue(note["id"] as! Int, forKeyPath: "id")
            noteManagedObject.setValue(note["favorite"] as! Bool, forKeyPath: "favorite")
        }
        // Try to save all notes in Managed Object Context to CoreData
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    // Delete all notes ONLY!!! from CoreData
    func deleteAllNotes() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Notes")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        do {
            try managedContext.execute(deleteRequest)
        } catch let error as NSError {
            print(error)
        }
    }
}


