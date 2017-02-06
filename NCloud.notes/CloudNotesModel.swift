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

class CloudNotesModel {
    static let instance = CloudNotesModel()
    
//    func syncLocalNotesToServer(remoteNotes: [AnyObject], completeHandler:@escaping (Bool) -> Void) {
//        let localNotes = getNotesFromCoreData()
//        for localNote in localNotes {
//            
//        }
//    }
    
    func getLocalNotes() -> [Note] {
        var sortedNotes = [Note]()
        let fetchRequest = NSFetchRequest<Note>(entityName: "Note")
        let sortDescriptor = NSSortDescriptor(key: "modified", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        do {
            sortedNotes = try CoreDataManager.instance.managedObjectContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return sortedNotes
    }
    
    func syncRemoteNotesToLocal(remoteNotes: [AnyObject]) {
        var newNotes = [AnyObject]()
        var updatedNotes = [AnyObject]()
        var notesToDelete = [Note]()
        let localNotesDict = convertLocalNotesToDictionaryByID(notes: getLocalNotes())
        let remoteNotesDict = convertRemoteNotesToDictionaryByID(notes: remoteNotes)
        // Remove notes deleted on server
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
                if Int(localNote.modified) < remoteNote["modified"] as! Int {
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
            saveRemoteNotes(notesArray: newNotes)
        }
        if updatedNotes.count > 0 {
            updateLocalNotes(updatedNotes: updatedNotes)
        }
        if notesToDelete.count > 0 {
            CoreDataManager.instance.deleteObjects(objects: notesToDelete)
        }
    }
    
    func updateLocalNotes(updatedNotes: [AnyObject]) {
        let localNotes = getLocalNotes()
        let localNotesDictionary = convertLocalNotesToDictionaryByID(notes: localNotes)
        // Remove old notes from CoreData
        for case let updatedNote as [String:AnyObject] in updatedNotes {
            CoreDataManager.instance.managedObjectContext.delete(localNotesDictionary[(updatedNote["id"] as! Int)]!)
        }
        CoreDataManager.instance.saveContext()
        // Save updated notes to CoreData
        saveRemoteNotes(notesArray: updatedNotes)
    }
    
    // Convert [NSManagedObject] array to [note_id:NSManagedObject] dictionary
    private func convertLocalNotesToDictionaryByID(notes: [Note]) -> [Int:Note] {
        var dictionary = [Int:Note]()
        for note in notes {
            dictionary[Int(note.id)] = note
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
    
    func saveRemoteNotes(notesArray: [AnyObject]) {
        // Save all received notes to managedContext
        for case let note as [String:AnyObject] in notesArray {
            // Insert new empty noteManagedObject(row) into Notes Entity(table)
            let newNote = Note()
            // Add note attributes to empty ManagedObject
            newNote.title = note["title"] as? String
            newNote.content = note["content"] as? String
            newNote.modified = Int64(note["modified"] as! Int)
            newNote.id = Int64(note["id"] as! Int)
            newNote.favorite = note["favorite"] as! Bool
        }
        // Try to save all notes to CoreData
        CoreDataManager.instance.saveContext()
    }
    
    // Delete all local notes
    func deleteLocalNotes() {
        let localNotes = getLocalNotes()
        CoreDataManager.instance.deleteObjects(objects: localNotes)
    }
}


