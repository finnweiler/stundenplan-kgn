//
//  UserController.swift
//  timetable-iphone
//
//  Created by Finn Weiler on 28.02.19.
//  Copyright © 2019 Finn Weiler. All rights reserved.
//

import UIKit
import UntisApi


class WelcomeController: UIViewController {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        submitButton.layer.cornerRadius = 7
        submitButton.layer.masksToBounds = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction func submitAction(_ sender: UIButton) {
        submitButton.isEnabled = false
        loadingIndicator.startAnimating()
        submitButton.setTitle("", for: .disabled)
        usernameField.endEditing(true)
        passwordField.endEditing(true)
        usernameField.isUserInteractionEnabled = false
        passwordField.isUserInteractionEnabled = false
        errorLabel.isHidden = true
        Untis.setUserCredentials(username: usernameField.text ?? "", password: passwordField.text ?? "")
        Untis.auth { (success) in
            if (success) {
                UserDefaults.standard.set(true, forKey: "configured")
                self.dismiss(animated: true, completion: nil)
            } else {
                self.errorLabel.isHidden = false
                self.usernameField.isUserInteractionEnabled = true
                self.passwordField.isUserInteractionEnabled = true
                self.loadingIndicator.stopAnimating()
                self.submitButton.isEnabled = true
            }
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
}
