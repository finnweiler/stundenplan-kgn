//
//  UserController.swift
//  timetable-iphone
//
//  Created by Finn Weiler on 28.02.19.
//  Copyright © 2019 Finn Weiler. All rights reserved.
//

import UIKit


class WelcomeController: UIViewController {
    
    @IBOutlet weak var submitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        submitButton.layer.cornerRadius = 7
        submitButton.layer.masksToBounds = true
    }
    
    @IBAction func submitAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
