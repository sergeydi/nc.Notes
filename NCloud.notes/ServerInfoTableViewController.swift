//
//  ServerInfoTableViewController.swift
//  NCloud.notes
//
//  Created by Sergey Didanov on 30.12.16.
//  Copyright © 2016 Sergey Didanov. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class ServerInfoTableViewController: UITableViewController {
    @IBOutlet weak var connectionActivityIndecator: UIActivityIndicatorView!
    @IBOutlet weak var serverNameTextField: UITextField!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var connectionStatusButton: UILabel!
    @IBOutlet weak var allowSelfSignCertSwitch: UISwitch!
    var isLoggedIn = false {
        didSet {
            if isLoggedIn {
                guard let serverName = KeychainWrapper.standard.string(forKey: "server"),
                    let userName = KeychainWrapper.standard.string(forKey: "username"),
                    let password = KeychainWrapper.standard.string(forKey: "password") else { return }
                serverNameTextField.text = serverName; userNameTextField.text = userName; passwordTextField.text = password
                connectionStatusButton.text = "Disconnect"
            } else {
                removeServerCredentials()
                UserDefaults.standard.removeObject(forKey: "loggedIn")
                UserDefaults.standard.removeObject(forKey: "syncOnStart")
                serverNameTextField.text = ""; userNameTextField.text = ""; passwordTextField.text = ""
                CloudNotesModel.instance.deleteLocalNotes()
                connectionStatusButton.text = "Connect"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Server information"
        connectionActivityIndecator.isHidden = true
        if UserDefaults.standard.object(forKey: "loggedIn") as? Bool != nil {
            isLoggedIn = true
        }
        // Detect if user want to use Self Signed Certificate
        allowSelfSignCertSwitch.addTarget(self, action: #selector(ServerInfoTableViewController.switchChanged(_:)), for: UIControlEvents.valueChanged)
    }
    
    // If user want to use Self Signed Certificate, show alert and disable switch
    func switchChanged(_ mySwitch: UISwitch) {
        guard mySwitch.isOn else { return }
        showAlert(withMessage: "Self Signed Certificates disabled in iOS from January 2017.")
        allowSelfSignCertSwitch.setOn(false, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 4 : 1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Click "Connect/Disconnect" button
        guard indexPath.section == 1 else { return }
        if !isLoggedIn {
            // Click "Connect" button
            if (serverNameTextField.text?.characters.count)! > 0 && (userNameTextField.text?.characters.count)! > 0 && (passwordTextField.text?.characters.count)! > 0 && !connectionActivityIndecator.isAnimating {
                connectionActivityIndecator.isHidden = false; self.connectionActivityIndecator.startAnimating()
                self.saveServerCredentials()
                CloudNotesHTTP.instance.getRemoteNotes() { response, result in
                    if result {
                        CloudNotesModel.instance.saveRemoteNotes(notesArray: response!)
                        UserDefaults.standard.set(true, forKey: "loggedIn")
                        self.isLoggedIn = true
                        self.showAlert(withMessage: "Connection successfull")
                    } else {
                        self.removeServerCredentials()
                        self.showAlert(withMessage: "Server information is incorrect or server is not available!")
                    }
                    self.connectionActivityIndecator.stopAnimating(); self.connectionActivityIndecator.isHidden = true
                }
            } else {
                // One of the fields is empty
                showAlert(withMessage: "Server information is incorrect!")
            }
        } else {
            // Click "Disconnect" button
            isLoggedIn = false
        }
    }
    
    // Show alert using message as argument
    func showAlert(withMessage message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // Click "Connect" button with successfull connection
    func saveServerCredentials() {
        KeychainWrapper.standard.set(serverNameTextField.text!, forKey: "server")
        KeychainWrapper.standard.set(userNameTextField.text!, forKey: "username")
        KeychainWrapper.standard.set(passwordTextField.text!, forKey: "password")
    }
    
    // Click "Disconnect" button
    func removeServerCredentials() {
        KeychainWrapper.standard.removeObject(forKey: "server")
        KeychainWrapper.standard.removeObject(forKey: "username")
        KeychainWrapper.standard.removeObject(forKey: "password")
    }
    
    deinit {
        print("ServerInfoTableViewController deinited")
    }
}
