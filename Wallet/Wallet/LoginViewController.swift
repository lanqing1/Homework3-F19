//
//  ViewController.swift
//  Wallet
//
//  Created by Weisu Yin on 9/29/19.
//  Copyright © 2019 UCDavis. All rights reserved.
//

import UIKit
import PhoneNumberKit

class LoginViewController: UIViewController {

    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var numberTextField: PhoneNumberTextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var tapGesture = UITapGestureRecognizer()
    let phoneNumberKit = PhoneNumberKit()
    
    var phoneNumber: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        // Do any additional setup after loading the view.
    }
    
    func initUI() {
        countryTextField.isUserInteractionEnabled = false
        sendButton.layer.cornerRadius = sendButton.frame.height / 2
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        activityIndicator.isHidden = true
        let storedPhoneNumber = Storage.phoneNumberInE164 ?? ""
        if storedPhoneNumber != "" {
            let index = storedPhoneNumber.index(storedPhoneNumber.startIndex, offsetBy: 2)
            numberTextField.text = String(storedPhoneNumber[index...])
        }
    }
    
    @IBAction func sendTapped(_ sender: Any) {
        dismissKeyboard()
        let phoneNumber = numberTextField.text?.filter { $0 >= "0" && $0 <= "9" } ?? ""
        if phoneNumber.count == 0 {
            errorLabel.text = "Please enter your phone number."
            errorLabel.textColor = .red
        } else if phoneNumber.count != 10 {
            errorLabel.text = "The phone number should be 10 digits."
            errorLabel.textColor = .red
        } else {
            do {
                let parsedPhoneNumber = try phoneNumberKit.parse(numberTextField.text ?? "")
                self.phoneNumber = phoneNumberKit.format(parsedPhoneNumber, toType: .e164)
                
                if Storage.authToken != nil, Storage.phoneNumberInE164 == self.phoneNumber {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let homeVC = storyboard.instantiateViewController(identifier: "home") as! HomeViewController
                    homeVC.modalPresentationStyle = .fullScreen
                    self.present(homeVC, animated: true, completion: nil)
                } else {
                    verify()
                }
            }
            catch {
                errorLabel.text = "Please enter a valid phone number"
                errorLabel.textColor = .red
            }
        }
        errorLabel.isHidden = false
    }
    
    func verify() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        self.view.isUserInteractionEnabled = false
        Api.sendVerificationCode(phoneNumber: self.phoneNumber) { response, error in
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            self.view.isUserInteractionEnabled = true
            if let error = error {
                print("Error: \(error)")
                self.errorLabel.text = error.message
                self.errorLabel.textColor = .red
                return
            } else {
                print("Response: \(String(describing: response))")
                self.errorLabel.text = "Verification code has been sent to \(self.phoneNumber))"
                self.errorLabel.textColor = .green
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let verificationVC = storyboard.instantiateViewController(identifier: "verification") as! VerificationViewController
                verificationVC.phoneNumber = self.phoneNumber
                self.navigationController?.pushViewController(verificationVC, animated: true)
            }
        }
    }
    
    @objc func dismissKeyboard() {
        numberTextField.resignFirstResponder()
    }
    
}

