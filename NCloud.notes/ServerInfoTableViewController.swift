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
    let userDefaults = UserDefaults.standard
    let cloudNotesModel = CloudNotesModel()
    var isLoggedIn = false {
        didSet {
            if isLoggedIn {
                guard let serverName = KeychainWrapper.standard.string(forKey: "server"), let userName = KeychainWrapper.standard.string(forKey: "username"), let password = KeychainWrapper.standard.string(forKey: "password") else { return }
                serverNameTextField.text = serverName; userNameTextField.text = userName; passwordTextField.text = password
                connectionStatusButton.text = "Disconnect"
            } else {
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
                cloudNotesModel.connectToServerUsing(server: serverNameTextField.text!, username: userNameTextField.text!, password: passwordTextField.text!) { connectionStatus in
                    if connectionStatus {
                        self.saveServerCredentials()
                        self.showAlert(withMessage: "Connection successfull")
                    } else {
                        self.showAlert(withMessage: "Server information is incorrect!")
                    }
                    self.connectionActivityIndecator.stopAnimating(); self.connectionActivityIndecator.isHidden = true
                }
            } else {
                // One of the fields is empty
                showAlert(withMessage: "Server information is incorrect!")
            }
        } else {
            // Click "Disconnect" button
            removeServerCredentials()
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
        KeychainWrapper.standard.set(serverNameTextField.text!, forKey: "server"); KeychainWrapper.standard.set(userNameTextField.text!, forKey: "username"); KeychainWrapper.standard.set(passwordTextField.text!, forKey: "password")
        userDefaults.set(true, forKey: "firstRefreshNotesList"); userDefaults.set(true, forKey: "loggedIn")
        isLoggedIn = true
    }
    
    // Click "Disconnect" button
    func removeServerCredentials() {
        userDefaults.removeObject(forKey: "loggedIn"); userDefaults.removeObject(forKey: "syncOnStart")
        KeychainWrapper.standard.removeObject(forKey: "server"); KeychainWrapper.standard.removeObject(forKey: "username"); KeychainWrapper.standard.removeObject(forKey: "password")
        serverNameTextField.text = ""; userNameTextField.text = ""; passwordTextField.text = ""
        isLoggedIn = false
    }
    
    deinit {
        print("ServerInfoTableViewController deinited")
    }
}
