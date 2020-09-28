//
//  UserController.swift
//  timetable-iphone
//
//  Created by Finn Weiler on 28.02.19.
//  Copyright © 2019 Finn Weiler. All rights reserved.
//

import UIKit
import UntisApi
import FirebaseAnalytics

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
                Analytics.logEvent(AnalyticsEventLogin, parameters: nil)
                if let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared") {
                    defaults.setValue("2.0", forKey: "appVersion")
                    defaults.setValue(0x080808, forKey: "colorDarkBg")
                    defaults.setValue(0xFEFEFE, forKey: "colorLightBg")
                    defaults.setValue(16660268, forKey: "colorCancel")
                    defaults.setValue(7387961, forKey: "colorExam")
                    defaults.synchronize()
                }
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
    
    @IBAction func openPrivacy(_ sender: UIButton) {
        if let url = URL(string: "https://finnweiler.com/apps/privacy/stundenplankgn.html") {
            Analytics.logEvent("open_privacy", parameters: nil)
            UIApplication.shared.open(url)
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
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        usernameField.endEditing(true)
        passwordField.endEditing(true)
    }
}
