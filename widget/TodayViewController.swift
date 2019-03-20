//
//  TodayViewController.swift
//  widget
//
//  Created by Finn Weiler on 11.03.18.
//  Copyright © 2018 Finn Weiler. All rights reserved.
//

import UIKit
import NotificationCenter
import UntisApi

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var todayTitleLabel: UILabel!
    @IBOutlet weak var tomorrowTitleLabel: UILabel!
    
    @IBOutlet weak var todayContentLabel: UILabel!
    @IBOutlet weak var tomorrowContentLabel: UILabel!
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //updateData { (res) in }
    }
    
    fileprivate func updateData(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        loadingIndicator.startAnimating()
        
        guard let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared") else {
            self.loadingIndicator.stopAnimating()
            completionHandler(.failed)
            return
        }
        
        defaults.set(Date().timeIntervalSince1970, forKey: "lastFetch")
        defaults.synchronize()
        
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        
        Untis.auth { (success) in
            guard success else {
                self.loadingIndicator.stopAnimating()
                completionHandler(.failed)
                return
            }
            
            var date = Date()
            
            let day: TimeInterval =  60 * 60 * 24
            let weekday = Calendar.current.component(.weekday, from: date)
            
            if weekday == 1 {
                date += day
                self.todayTitleLabel.text = "Montag"
                self.tomorrowTitleLabel.text = "Dienstag"
            } else if weekday == 7 {
                date += day + day
                self.todayTitleLabel.text = "Montag"
                self.tomorrowTitleLabel.text = "Dienstag"
            } else {
                self.todayTitleLabel.text = "Heute"
                self.tomorrowTitleLabel.text = "Morgen"
            }
            
            Untis.fetchLessons(date: date, completion: { (timetable) in
                guard timetable != nil else {
                    self.loadingIndicator.stopAnimating()
                    completionHandler(.failed)
                    return
                }
                
                /* // PRINT LESSONS
                 var dic: Dictionary<Int,String> = [:]
                 timetable?.periods.forEach({ (period) in
                 dic[period.course!.id] = period.course?.longName
                 })
                 dic.forEach({ (key, value) in
                 print("\(value) => \(key)")
                 })*/
                
                let todaysPeriods = timetable!.userPeriods.filter({ (per) -> Bool in
                    return "\(per.date)" ==  f.string(from: date)
                }).sorted(by: { (per1, per2) -> Bool in
                    return per1.startTime < per2.startTime
                })
                
                let tomorrowPeriods = timetable!.userPeriods.filter({ (per) -> Bool in
                    return "\(per.date)" ==  f.string(from: date + day)
                }).sorted(by: { (per1, per2) -> Bool in
                    return per1.startTime < per2.startTime
                })
                
                let space = NSAttributedString(string: "  ")
                let todayContent = NSMutableAttributedString()
                todaysPeriods.forEach({ (per) in
                    todayContent.append(space)
                    todayContent.append(per.displayableString())
                    todayContent.append(space)
                })
                
                var tomorrowContent = NSMutableAttributedString()
                tomorrowPeriods.forEach({ (per) in
                    tomorrowContent.append(space)
                    tomorrowContent.append(per.displayableString())
                    tomorrowContent.append(space)
                })
                
                if weekday == 6 {
                    tomorrowContent = NSMutableAttributedString(string: "Schönes Wochenende!")
                }
                
                self.loadingIndicator.stopAnimating()
                self.setLabels(today: todayContent, tomorrow: tomorrowContent)
                
                print("Heute: \(todayContent.string), Morgen: \(tomorrowContent.string)")
                
                completionHandler(.newData)
            })
        }
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        guard let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared") else {
            completionHandler(.failed)
            return
        }
        
        setLabels(today: nil, tomorrow: nil)
        
        if let lastFetch = defaults.value(forKey: "lastFetch") as? TimeInterval {
            if Date().timeIntervalSince1970 - lastFetch < 60 * 5 {
                completionHandler(.noData)
                return
            }
        } else {
            Untis.syncCourses()
        }
        
        updateData { (res) in
            completionHandler(res)
        }
    }
    
    
    func setLabels(today: NSAttributedString?, tomorrow: NSAttributedString?) {
        guard let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared") else { return }
        if let today = today {
            todayContentLabel.attributedText = today
            defaults.set(NSKeyedArchiver.archivedData(withRootObject: today), forKey: "today")
            defaults.synchronize()
        } else if let data = (defaults.value(forKey: "today") as? Data) {
            todayContentLabel.attributedText = NSKeyedUnarchiver.unarchiveObject(with: data) as! NSMutableAttributedString
        } else {
            todayContentLabel.attributedText = NSAttributedString(string: "")
        }
        
        if let tomorrow = tomorrow {
            tomorrowContentLabel.attributedText = tomorrow
            defaults.set(NSKeyedArchiver.archivedData(withRootObject: tomorrow), forKey: "tomorrow")
            defaults.synchronize()
        } else if let data = (defaults.value(forKey: "tomorrow") as? Data) {
            tomorrowContentLabel.attributedText = NSKeyedUnarchiver.unarchiveObject(with: data) as! NSMutableAttributedString
        } else {
            tomorrowContentLabel.attributedText = NSAttributedString(string: "")
        }
    }
    
}
