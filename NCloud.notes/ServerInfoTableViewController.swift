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
    let connectionStatus = UserDefaults.standard
    var httpClient: HTTPClient!
    var isLoggedIn = false {
        didSet {
            if isLoggedIn {
                connectionStatusButton.text = "Disconnect"
                if let serverName = KeychainWrapper.standard.string(forKey: "server"), let userName = KeychainWrapper.standard.string(forKey: "username"), let password = KeychainWrapper.standard.string(forKey: "password") {
                    serverNameTextField.text = serverName
                    userNameTextField.text = userName
                    passwordTextField.text = password
                }
            } else {
                connectionStatusButton.text = "Connect"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Server information"
        connectionActivityIndecator.isHidden = true
        // Check if app is logged in
        if UserDefaults.standard.object(forKey: "loggedIn") as? Bool != nil {
            isLoggedIn = true
        }
        // Detect if user want to use Self Signed Certificate
        allowSelfSignCertSwitch.addTarget(self, action: #selector(ServerInfoTableViewController.switchChanged(_:)), for: UIControlEvents.valueChanged)
    }
    
    // If user want to use Self Signed Certificate, show alert and disable switch
    func switchChanged(_ mySwitch: UISwitch) {
        if mySwitch.isOn {
            showAlert(withMessage: "Self Signed Certificates disabled in iOS from January 2017.")
            allowSelfSignCertSwitch.setOn(false, animated: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0: return 4
        case 1: return 1
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Click "Connect/Disconnect" button
        if indexPath.section == 1 {
            if !isLoggedIn {
                // Click "Connect" button
                if (serverNameTextField.text?.characters.count)! > 0 && (userNameTextField.text?.characters.count)! > 0 && (passwordTextField.text?.characters.count)! > 0 {
                    // Start and show connectionActivityIndecator
                    self.connectionActivityIndecator.startAnimating(); connectionActivityIndecator.isHidden = false; connectionActivityIndecator.startAnimating()
                    httpClient = HTTPClient()
                    httpClient.checkServerConnUsing(server: serverNameTextField.text!, username: userNameTextField.text!, password: passwordTextField.text!) { connectionStatus in
                        switch connectionStatus {
                        case true:
                            self.showAlert(withMessage: "Connection successfull")
                            self.saveServerCredentials()
                        case false:
                            self.showAlert(withMessage: "Server information is incorrect!")
                        }
                    }
                } else {
                    // One of the fields is empty
                    showAlert(withMessage: "Server information is incorrect!")
                }
            } else {
                // Click "Disconnect" button
                removeServerCredentials()
            }
            // Stop and hide connectionActivityIndecator
            self.connectionActivityIndecator.stopAnimating(); connectionActivityIndecator.isHidden = true; connectionActivityIndecator.stopAnimating()
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
        connectionStatus.set(true, forKey: "loggedIn")
        isLoggedIn = true
    }
    
    // Click "Disconnect" button
    func removeServerCredentials() {
        connectionStatus.removeObject(forKey: "loggedIn")
        KeychainWrapper.standard.removeObject(forKey: "server")
        KeychainWrapper.standard.removeObject(forKey: "username")
        KeychainWrapper.standard.removeObject(forKey: "password")
        serverNameTextField.text = ""
        userNameTextField.text = ""
        passwordTextField.text = ""
        isLoggedIn = false
    }
    
    deinit {
        print("ServerInfoTableViewController deinited")
    }
}
