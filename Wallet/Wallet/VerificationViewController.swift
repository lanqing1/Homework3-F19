//
//  VerificationViewController.swift
//  Wallet
//
//  Created by Weisu Yin on 10/6/19.
//  Copyright © 2019 UCDavis. All rights reserved.
//

import UIKit

class VerificationViewController: UIViewController, PinTexFieldDelegate {
    
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var otpTextField1: UITextField!
    @IBOutlet weak var otpTextField2: UITextField!
    @IBOutlet weak var otpTextField3: UITextField!
    @IBOutlet weak var otpTextField4: UITextField!
    @IBOutlet weak var otpTextField5: UITextField!
    @IBOutlet weak var otpTextField6: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var phoneNumber: String = ""
    var otpTextFields: [UITextField] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        otpTextFields = [otpTextField1, otpTextField2, otpTextField3, otpTextField4, otpTextField5, otpTextField6]
        initUI()
    }
    
    func initUI() {
        phoneNumberLabel.text = "Enter the code sent to \(self.phoneNumber)"
        resendButton.layer.cornerRadius = resendButton.frame.height / 2
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        activityIndicator.isHidden = true
        setInteractable(textfield: otpTextField1)
        for tf in otpTextFields {
            tf.delegate = self
        }
        otpTextField1.becomeFirstResponder()
    }
    
    @IBAction func digitEntered(_ sender: UITextField) {
        let count = sender.text?.count ?? 0
        if count == 1 {
            switch sender {
            case otpTextField1:
                changeKeyboard(textfield: otpTextField2)
            case otpTextField2:
                changeKeyboard(textfield: otpTextField3)
            case otpTextField3:
                changeKeyboard(textfield: otpTextField4)
            case otpTextField4:
                changeKeyboard(textfield: otpTextField5)
            case otpTextField5:
                changeKeyboard(textfield: otpTextField6)
            case otpTextField6:
                let code = otpTextFields.compactMap {$0.text}.joined()
                print(code)
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()
                self.view.isUserInteractionEnabled = false
                Api.verifyCode(phoneNumber: phoneNumber, code: code) { (response, error) in
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                    guard let response = response, error == nil else {
                        self.errorLabel.text = error?.message
                        self.errorLabel.textColor = .red
                        self.errorLabel.isHidden = false
                        return
                    }
                    
                    print("\(String(describing: response))")
                    if let authToken = response["auth_token"] as? String {
                         Storage.authToken = authToken
                     }
                    Storage.phoneNumberInE164 = self.phoneNumber
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let homeVC = storyboard.instantiateViewController(identifier: "home") as! HomeViewController
                    homeVC.sms = true
                    homeVC.modalPresentationStyle = .fullScreen
                    self.present(homeVC, animated: true, completion: nil)
                }
            default:
                break
            }
        } else if count > 1 {
            sender.text = String((sender.text ?? "").prefix(1))
        }
    }
    
    func didPressBackspace(textField: PinTextField) {
        if textField.text?.count == 0 {
            switch textField {
            case otpTextField1:
                break
            case otpTextField2:
                changeKeyboard(textfield: otpTextField1)
                otpTextField1.text = ""
            case otpTextField3:
                changeKeyboard(textfield: otpTextField2)
                otpTextField2.text = ""
            case otpTextField4:
                changeKeyboard(textfield: otpTextField3)
                otpTextField3.text = ""
            case otpTextField5:
                changeKeyboard(textfield: otpTextField4)
                otpTextField4.text = ""
            case otpTextField6:
                changeKeyboard(textfield: otpTextField5)
                otpTextField5.text = ""
            default:
                break
            }
        }
    }
    
    @IBAction func resendCode(_ sender: Any) {
        Api.sendVerificationCode(phoneNumber: phoneNumber) { (response, error) in
            if let error = error {
                print("Error: \(error)")
                self.errorLabel.text = "Something went wrong, please try again later"
                self.errorLabel.textColor = .red
                return
            } else {
                print("Response: \(String(describing: response))")
                self.errorLabel.text = "Verification code has been re-sent to \(self.phoneNumber))"
                self.errorLabel.textColor = .green
            }
        }
    }
    
    func setInteractable(textfield: UITextField) {
        for tf in otpTextFields {
            if textfield == tf {
                tf.isUserInteractionEnabled = true
            } else {
                tf.isUserInteractionEnabled = false
            }
        }
    }
    
    func changeKeyboard(textfield: UITextField) {
        textfield.isUserInteractionEnabled = true
        textfield.becomeFirstResponder()
        for tf in otpTextFields {
            if textfield != tf {
                tf.isUserInteractionEnabled = false
            }
        }
    }
}
