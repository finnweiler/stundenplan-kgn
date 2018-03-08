//
//  ViewController.swift
//  timetable-iphone
//
//  Created by Finn Weiler on 13.02.18.
//  Copyright © 2018 Finn Weiler. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .lightGray
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        Untis.auth { (success) in
            Untis.fetchLessons(completion: { (lessons) in
                
            })
        }
    }
}

