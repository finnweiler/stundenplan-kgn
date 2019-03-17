//
//  ViewController.swift
//  timetable-iphone
//
//  Created by Finn Weiler on 13.02.18.
//  Copyright © 2018 Finn Weiler. All rights reserved.
//

import UIKit
import UntisApi

class ViewController: UITableViewController {
    
    var username = Untis.username
    var password = Untis.password
    
    var configured = UserDefaults.standard.bool(forKey: "configured")
    
    var selectedElements: Array<Untis.TimetableResponse.Element> = []
    var availableElements: Array<Untis.TimetableResponse.Element> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Einstellungen"
        
        let button = UIButton(type: .infoLight)
        button.addTarget(self, action: #selector(showHelp), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(checkUntis), for: .valueChanged)
        
        if (!configured) {
            let storyboard = UIStoryboard(name: "main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "welcomeController")
            self.present(vc, animated: false, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (configured) {
            checkUntis()
            tableView.refreshControl?.beginRefreshing()
            let offsetPoint = CGPoint(x: 0, y: -100)
            tableView.setContentOffset(offsetPoint, animated: true)
        }
        
        tableView.setEditing(true, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Untis-Zugangsdaten"
        case 1: return "Ausgewählte Fächer"
        case 2: return "Gefundene Fächer"
        case 3: return "Einstellungen"
        default: return ""
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return !configured ? 1 : 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return selectedElements.count
        case 2: return availableElements.count
        case 3: return 1
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId = "cellId"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) ?? UITableViewCell(style: .value1, reuseIdentifier: cellId)
        if (indexPath.section == 0) {
            if (indexPath.item == 0) {
                cell.textLabel?.text = "Nutzername"
                cell.detailTextLabel?.text = username
            } else {
                cell.textLabel?.text = "Passwort"
                cell.detailTextLabel?.text = String(self.password.map({ (c) -> Character in return "*" }))
            }
        } else if (indexPath.section == 1) {
            cell.textLabel?.text = selectedElements[indexPath.item].longName
            cell.detailTextLabel?.text = selectedElements[indexPath.item].name
        } else if (indexPath.section == 2) {
            cell.textLabel?.text = availableElements[indexPath.item].longName
            cell.detailTextLabel?.text = availableElements[indexPath.item].name
        } else if (indexPath.section == 3) {
            cell.textLabel?.text = "Zurücksetzen"
            cell.detailTextLabel?.text = ""
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if (indexPath.section == 1) {
            return UITableViewCell.EditingStyle.delete
        } else if (indexPath.section == 2) {
            return UITableViewCell.EditingStyle.insert
        } else {
            return UITableViewCell.EditingStyle.none
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == 0 && !configured) {
            if (indexPath.item == 0) {
                setProperty(title: "Nutzername") { (username) in
                    self.username = username
                    self.tableView.reloadRows(at: [IndexPath(item: 0, section: 0)], with: .automatic)
                    Untis.setUserCredentials(username: self.username, password: self.password)
                }
            } else {
                setProperty(title: "Passwort") { (password) in
                    self.password = password
                    self.tableView.reloadRows(at: [IndexPath(item: 1, section: 0)], with: .automatic)
                    Untis.setUserCredentials(username: self.username, password: self.password)
                    if (self.username != "" && self.password != "") {
                        tableView.refreshControl?.beginRefreshing()
                        self.checkUntis()
                        let offsetPoint = CGPoint(x: 0, y: -100)
                        tableView.setContentOffset(offsetPoint, animated: true)
                    }
                }
            }
        } else if (indexPath.section == 1) {
            let element = self.selectedElements.remove(at: indexPath.item)
            Untis.removeElement(id: element.id)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        } else if (indexPath.section == 2) {
            let element = self.availableElements.remove(at: indexPath.item)
            selectedElements.append(element)
            Untis.addElement(id: element.id)
            tableView.performBatchUpdates({
                tableView.insertRows(at: [IndexPath(item: selectedElements.count-1, section: 1)], with: .automatic)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }, completion: nil)
        } else if (indexPath.section == 3) {
            reset()
        }
    }
    
    func setProperty(title: String, finish: @escaping (_ value: String) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { (textfield) in
            textfield.placeholder = title
            textfield.keyboardType = .alphabet
        }
        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Sichern", style: .default, handler: { (action) in
            if let text = alert.textFields?.first?.text { finish(text) }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func checkUntis() {
        Untis.auth { (success) in
            if (success) {
                self.configured = true
                self.getCourses()
                UserDefaults.standard.set(true, forKey: "configured")
            } else {
                let alert = UIAlertController(title: "Fehler!", message: "Der Login mit deinen Zugansdaten war nicht erfolgreich. Versuche es später erneut und überprüfe ggf. deine Zugansdaten!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Verstanden", style: .cancel, handler: { _ in
                    self.refreshControl?.endRefreshing()
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    fileprivate func getCourses() {
        Untis.fetchLessons(date: Date()) { (timetable) in
            guard let timetable = timetable else { return }
            let elements = timetable.userPeriods.map({ (period) -> Untis.TimetableResponse.Element in return period.course! })
            var tempDic: Dictionary<Int, Untis.TimetableResponse.Element> = [:]
            elements.forEach({ (element) in tempDic[element.id] = element })
            self.selectedElements = tempDic.map({ (arg0) -> Untis.TimetableResponse.Element in
                let (_, value) = arg0
                return value
            })
            self.availableElements = timetable.elements.filter({ (element) -> Bool in
                return element.type == 3 && tempDic[element.id] == nil
            }).sorted(by: { (elA, elB) -> Bool in
                return elA.longName < elB.longName
            })
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    fileprivate func reset() {
        let alert = UIAlertController(title: "Zurücksetzen", message: "Deine Untis-Zugansdaten und gespeicherten Kurse werden dauerhaft gelöscht.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Zurücksetzen", style: .destructive, handler: { _ in
            Untis.reset()
            self.username = ""
            self.password = ""
            self.selectedElements = []
            self.availableElements = []
            self.configured = false
            UserDefaults.standard.set(false, forKey: "configured")
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc fileprivate func showHelp() {
        let alert = UIAlertController(title: "Wo sehe ich meinen Stundenplan?", message: "Dein Stundenplan wird in einem Widget in der Ansicht \"Heute\" deines iPhones angezeigt. Du musst das Widget zunächst aktivieren. Falls du nicht weißt wie das funktioniert, klicke bitte \"Ich brauche mehr Hilfe!\".", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Verstanden.", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Ich brauche mehr Hilfe!", style: .default, handler: { _ in
            guard let url = URL(string: "https://support.apple.com/de-de/HT207122") else { return }
            UIApplication.shared.open(url)
        }))
        present(alert, animated: true, completion: nil)
    }
}

