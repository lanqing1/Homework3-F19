//
//  HomeViewController.swift
//  Wallet
//
//  Created by Weisu Yin on 10/13/19.
//  Copyright © 2019 UCDavis. All rights reserved.
//

import UIKit
import PhoneNumberKit

class HomeViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var welcomeMessage: UILabel!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var accountsTable: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let phoneNumberKit = PhoneNumberKit()
    var tapGesture = UITapGestureRecognizer()
    var wallet = Wallet()
    var sms = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        welcomeMessage.alpha = 1
        welcomeMessage.text = sms ? "Welcome" : "Welcome Back"
        dataInit()
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    func dataInit() {
        Api.user(){ response, error in
            guard let response = response, error == nil else {
                print("Failed to get user info from API")
                return
            }
            self.wallet = Wallet.init(data: response, ifGenerateAccounts: true)
            self.initUI()
        }
    }
    
    func initUI() {
        activityIndicator.isHidden = true
        userNameTextField.text = wallet.userName != "" ? wallet.userName : wallet.phoneNumber
        userNameTextField.delegate = self
        totalAmountLabel.text = "Your Total Amount: $ \(String.init(format: "%.2f",wallet.totalAmount))"
        accountsTable.reloadData()
        UIView.animate(withDuration: 1, delay: 0.5, options: .beginFromCurrentState, animations: {
            self.welcomeMessage.alpha = 0
        }, completion: nil)
        accountsTable.dataSource = self
    }
    
    @IBAction func logoutPressed(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(identifier: "login") as! UINavigationController
        loginVC.modalPresentationStyle = .fullScreen
        self.present(loginVC, animated: true, completion: nil)
    }
    
    @IBAction func nameUpdated(_ sender: Any) {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        
        guard let input = userNameTextField.text, input != "" else {
            userNameTextField.text = wallet.phoneNumber
            Api.setName(name: "") { (response, error) in
                self.activityIndicator.isHidden = true
                self.activityIndicator.stopAnimating()
                self.view.isUserInteractionEnabled = true
                guard error == nil else {
                    print("setting user name failed.")
                    return
                }
            }
            return
        }
        userNameTextField.text = input
        if input != wallet.userName {
            Api.setName(name: input) { (response, error) in
                self.activityIndicator.isHidden = true
                self.activityIndicator.stopAnimating()
                self.view.isUserInteractionEnabled = true
                guard error == nil else {
                    print("setting user name failed.")
                    return
                }
            }
        } else {
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wallet.accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath)
        cell.textLabel?.text = wallet.accounts[indexPath.row].name
        cell.detailTextLabel?.text = "$" + String.init(format: "%.2f", wallet.accounts[indexPath.row].amount)
        return cell
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
    
    @objc func dismissKeyboard() {
        userNameTextField.resignFirstResponder()
    }
}
