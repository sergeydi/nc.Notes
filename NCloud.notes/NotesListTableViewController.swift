//
//  NotesListTableViewController.swift
//  NCloud.notes
//
//  Created by Sergey Didanov on 29.12.16.
//  Copyright © 2016 Sergey Didanov. All rights reserved.
//

import UIKit

class NotesListTableViewController: UITableViewController {
    let userDefaults = UserDefaults.standard
    var httpClient: HTTPClient!
    @IBAction func addNoteButton(_ sender: Any) {
        print("Add new note action")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Used for the first refreshNotesList() after configure server
        if UserDefaults.standard.object(forKey: "loggedIn") as? Bool != nil && UserDefaults.standard.object(forKey: "firstRefreshNotesList") as? Bool != nil {
            initTableView()
            userDefaults.removeObject(forKey: "firstRefreshNotesList")
        }
    }
    
    func initTableView() {
        guard UserDefaults.standard.object(forKey: "loggedIn") as? Bool != nil else { return }
        refreshControl = UIRefreshControl()
        tableView.addSubview(self.refreshControl!)
        refreshControl?.addTarget(self, action: #selector(NotesListTableViewController.refreshNotesList), for: .valueChanged)
        guard UserDefaults.standard.object(forKey: "syncOnStart") != nil || UserDefaults.standard.object(forKey: "firstRefreshNotesList") as? Bool != nil  else { return }
        self.refreshControl?.beginRefreshing()
        self.tableView?.setContentOffset(CGPoint(x: 0, y: CGFloat(0)-self.refreshControl!.frame.size.height*2), animated: true)
        refreshNotesList()
    }
    
    func refreshNotesList() {
        print("Refresh notes list begin")
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
        return 0
    }
    
    /*
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
     
     // Configure the cell...
     
     return cell
     }
     */
    
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
