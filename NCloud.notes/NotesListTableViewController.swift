//
//  NotesListTableViewController.swift
//  NCloud.notes
//
//  Created by Sergey Didanov on 29.12.16.
//  Copyright © 2016 Sergey Didanov. All rights reserved.
//

import UIKit
import CoreData

class NotesListTableViewController: UITableViewController {
    let userDefaults = UserDefaults.standard
    let cloudNotesModel = CloudNotesModel()
    @IBAction func addNoteButton(_ sender: Any) {
        print("Add new note action")
    }
    var notes: [Note] = []
    let coreDataManager = CoreDataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        tableView.addSubview(self.refreshControl!)
        refreshControl?.addTarget(self, action: #selector(NotesListTableViewController.syncNotes), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard UserDefaults.standard.object(forKey: "loggedIn") as? Bool != nil else { return }
        self.refreshControl?.beginRefreshing()
        self.tableView?.setContentOffset(CGPoint(x: 0, y: CGFloat(0)-self.refreshControl!.frame.size.height*2), animated: true)
        if UserDefaults.standard.object(forKey: "syncOnStart") != nil {
            syncNotes()
        } else {
            refreshNotesTable()
        }
    }
    
    // Try to sync local <---> remote notes
    func syncNotes() {
        print("Sync notes")
        CloudNotesHTTP.instance.getRemoteNotes() { notesFromServer in
            if notesFromServer != nil {
                // If got notes from server, sync them to local and show
                self.cloudNotesModel.syncRemoteNotesToLocal(remoteNotes: notesFromServer!)
                //                self.cloudNotesModel.syncLocalNotesToRemote(remoteNotes: notesFromServer!) { complete in
                //                    if !complete {
                //                        self.showAlert(withMessage: "Could not sync notes to server. Check connection!")
                //                    }
                //                    self.refreshNotesTable()
                //                }
                self.refreshNotesTable()
            } else {
                // If server unavailable get notes from CoreData and show alert
                self.showAlert(withMessage: "Could not receive notes from server. Check connection!")
                self.refreshNotesTable()
            }
        }
    }
    
    // Get notes from CoreData and refresh tableview
    func refreshNotesTable() {
        self.notes = self.cloudNotesModel.getLocalNotes()
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return notes.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        let note = notes[indexPath.row]
        cell.textLabel?.text = note.title
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editNoteSegue" {
            guard let indexPath = self.tableView.indexPathForSelectedRow else { return }
            let destinationController = segue.destination as! EditNoteViewController
            destinationController.noteID = self.notes[indexPath.row].objectID
            let backItem = UIBarButtonItem()
            backItem.title = "Notes"
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    // Show alert using message as argument
    func showAlert(withMessage message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
