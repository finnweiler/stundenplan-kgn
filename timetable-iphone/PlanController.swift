//
//  PlanController.swift
//  timetable-iphone
//
//  Created by Finn Weiler on 17.03.19.
//  Copyright © 2019 Finn Weiler. All rights reserved.
//

import UIKit
import UntisApi


class PlanController: UIViewController {
    
    var timetableContainer: UIView?
    let indicator = UIActivityIndicatorView(style: .gray)
    
    var timetable: Untis.TimetableResponse?
    
    let date: Date
    
    var delegate: PlanControllerDelegate?
    private(set) var refreshing = false
    
    init(date: Date) {
        self.date = date
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: "background")
            //UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
        
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        view.addSubview(indicator)
        indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        if let monday = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) {
            let f = DateFormatter()
            f.dateFormat = "dd.MM."
            navigationItem.title = "\(f.string(from: monday)) bis \(f.string(from: monday + 60 * 60 * 24 * 4))"
        }
    }
    
    func createTimetable(t: Untis.TimetableResponse, date: Date) -> UIView {
        let timetableContainer = UIView()
        timetableContainer.translatesAutoresizingMaskIntoConstraints = false
        
        if (t.userPeriods.count == 0) {
            let label = UILabel()
            label.text = "Klicke ••• um Kurse auszuwählen."
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            timetableContainer.addSubview(label)
            label.centerXAnchor.constraint(equalTo: timetableContainer.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: timetableContainer.centerYAnchor).isActive = true
            return timetableContainer
        }
        
        self.timetable = t
        var minY = 60 * 24
        var maxY = 0
        var days: Dictionary<Int, Array<Untis.TimetableResponse.Period>> = [:]
        t.userPeriods.forEach { (period) in
            minY = min(minY, period.startTimeMinutes)
            maxY = max(maxY, period.endTimeMinutes)
            if days[period.date] != nil {
                days[period.date]!.append(period)
            } else {
                days[period.date] = [period]
            }
        }
        
        let monday = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))
        let day: TimeInterval = 60 * 60 * 24
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        
        let keys = [Int(f.string(from: monday!))!, Int(f.string(from: monday! + day))!, Int(f.string(from: monday! + day * 2))!, Int(f.string(from: monday! + day * 3))!, Int(f.string(from: monday! + day * 4))!]
        let constant = 25
        
        f.dateFormat = "dd."
        
        var lastLabel: UILabel?
        for index in 0...4 {
            let label = UILabel()
            label.textAlignment = .center
            label.text = f.string(from: monday! + 60 * 60 * 24 * TimeInterval(index))
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = UIFont.boldSystemFont(ofSize: 18)
            label.textColor = .white
            label.backgroundColor = UIColor(named: "bar") //UIColor(red: 47/255, green: 115/255, blue: 232/255, alpha: 1)
            timetableContainer.addSubview(label)
            
            let height = CGFloat(constant) / CGFloat(maxY - minY + constant)
            
            let leftAnchor = lastLabel?.rightAnchor ?? timetableContainer.leftAnchor
            label.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            label.topAnchor.constraint(equalTo: timetableContainer.topAnchor).isActive = true
            label.widthAnchor.constraint(equalTo: timetableContainer.widthAnchor, multiplier: 1/5).isActive = true
            label.heightAnchor.constraint(equalTo: timetableContainer.heightAnchor, multiplier: height).isActive = true
            
            var lastLessonLabel: UIView = label
            var lastEndTime = 0
            var day = days[keys[index]] ?? []
            day.sort(by: { (per1, per2) -> Bool in
                //return a.startTimeMinutes < b.startTimeMinutes
                if per1.startTime == per2.startTime {
                    return per1.cellState != "EXAM"
                } else {
                    return per1.startTime < per2.startTime
                }
            })
            
            var content: Array<Untis.TimetableResponse.Period> = []
            var lastPeriod: Untis.TimetableResponse.Period?
            day.forEach({ (per) in
                if let last = lastPeriod {
                    if per.cellState == "EXAM" && per.startTime == last.startTime {
                        content.removeLast()
                    }
                }
                content.append(per)
                lastPeriod = per
            })
            
            content.forEach { (period) in
                if (period.startTimeMinutes > lastEndTime) {
                    let gap = UIView()
                    gap.translatesAutoresizingMaskIntoConstraints = false
                    
                    let height = CGFloat(period.startTimeMinutes - lastEndTime - minY) / CGFloat(maxY - minY + constant)
                    
                    timetableContainer.addSubview(gap)
                    gap.topAnchor.constraint(equalTo: lastLessonLabel.bottomAnchor).isActive = true
                    gap.centerXAnchor.constraint(equalTo: label.centerXAnchor).isActive = true
                    gap.widthAnchor.constraint(equalTo: label.widthAnchor).isActive = true
                    gap.heightAnchor.constraint(equalTo: timetableContainer.heightAnchor, multiplier: height).isActive = true
                    
                    lastLessonLabel = gap
                }
                
                let lessonLabel = UILabel()
                lessonLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)
                lessonLabel.textAlignment = .center
                lessonLabel.attributedText = period.displayableString()
                lessonLabel.translatesAutoresizingMaskIntoConstraints = false
                
                let height = CGFloat(period.endTimeMinutes - period.startTimeMinutes) / CGFloat(maxY - minY + constant)
                
                timetableContainer.addSubview(lessonLabel)
                lessonLabel.topAnchor.constraint(equalTo: lastLessonLabel.bottomAnchor).isActive = true
                lessonLabel.centerXAnchor.constraint(equalTo: label.centerXAnchor).isActive = true
                lessonLabel.widthAnchor.constraint(equalTo: label.widthAnchor).isActive = true
                lessonLabel.heightAnchor.constraint(equalTo: timetableContainer.heightAnchor, multiplier: height).isActive = true
                
                lastLessonLabel = lessonLabel
                lastEndTime = period.endTimeMinutes - minY
            }
            
            lastLabel = label
        }
        return timetableContainer
    }
    
    func fetchTimetable() {
        indicator.startAnimating()
        refreshing = true
        delegate?.didStartRefreshing()
        Untis.auth { (success) in
            if (success) {
                Untis.fetchLessons(date: self.date, completion: { (timetable) in
                    guard let timetable = timetable else {
                        self.refreshing = false
                        self.delegate?.didEndRefreshing(success: false)
                        return
                    }
                    
                    self.indicator.stopAnimating()
                    
                    self.timetableContainer?.removeFromSuperview()
                    self.timetableContainer = self.createTimetable(t: timetable, date: self.date)
                    
                    self.timetableContainer!.backgroundColor = UIColor(named: "page")
                    self.updateColors()
                    
                    
                    self.timetableContainer?.layer.cornerRadius = 5
                    self.timetableContainer?.layer.masksToBounds = true
                    
                    self.view.addSubview(self.timetableContainer!)
                    self.timetableContainer!.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: 13).isActive = true
                    self.timetableContainer!.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -13).isActive = true
                    self.timetableContainer!.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -13).isActive = true
                    self.timetableContainer!.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 13).isActive = true
                    
                    self.refreshing = false
                    self.delegate?.didEndRefreshing(success: true)
                })
            } else {
                self.indicator.tintColor = .red
                self.refreshing = false
                self.delegate?.didEndRefreshing(success: false)
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard UIApplication.shared.applicationState == .inactive else {
            return
        }

        updateColors()
    }
    
    func updateColors() {
        if #available(iOS 13.0, *) {
            let defaults = UserDefaults(suiteName: "group.com.finnweiler.shared")
            let useBgInApp = defaults?.bool(forKey: "useBgInApp")
            
            if useBgInApp == true  {
                let colorLightBg = UIColor(rgb: (defaults?.integer(forKey: "colorLightBg")) ?? 0xFFFFFF)
                let colorDarkBg = UIColor(rgb: (defaults?.integer(forKey: "colorDarkBg")) ?? 0x000000)
                if self.traitCollection.userInterfaceStyle == .dark {
                    self.timetableContainer!.backgroundColor = colorDarkBg
                } else {
                    self.timetableContainer!.backgroundColor = colorLightBg
                }
            }
        }
    }
}


protocol PlanControllerDelegate {
    func didStartRefreshing() -> Void
    func didEndRefreshing(success: Bool) -> Void
}

extension UIColor {
    private convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}
