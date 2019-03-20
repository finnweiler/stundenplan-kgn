//
//  SettingsController.swift
//  timetable-iphone
//
//  Created by Finn Weiler on 13.02.18.
//  Copyright © 2018 Finn Weiler. All rights reserved.
//

import UIKit
import UntisApi

class SettingsController: UITableViewController {
    
    var selectedElements: Array<Untis.TimetableResponse.Element> = []
    var availableElements: Array<Untis.TimetableResponse.Element> = []
    
    init() {
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelectionDuringEditing = true
        
        navigationItem.title = "Kurse"
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(startEdit)), animated: false)
        navigationController?.navigationBar.tintColor = .black
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(checkUntis), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
            checkUntis()
            tableView.refreshControl?.beginRefreshing()
            let offsetPoint = CGPoint(x: 0, y: -100)
            tableView.setContentOffset(offsetPoint, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Sichtbar (\(selectedElements.count))"
        case 1: return "Verborgen (\(availableElements.count))"
        case 2: return "Einstellungen"
        default: return ""
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableView.isEditing ? 2 : 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return selectedElements.count
        case 1: return availableElements.count
        case 2: return 1
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId = "cellId"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) ?? UITableViewCell(style: .value1, reuseIdentifier: cellId)
        if (indexPath.section == 0) {
            cell.textLabel?.text = selectedElements[indexPath.item].longName
            cell.detailTextLabel?.text = selectedElements[indexPath.item].name
        } else if (indexPath.section == 1) {
            cell.textLabel?.text = availableElements[indexPath.item].longName
            cell.detailTextLabel?.text = availableElements[indexPath.item].name
        } else if (indexPath.section == 2) {
            cell.textLabel?.text = "Zurücksetzen"
            cell.detailTextLabel?.text = ""
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return tableView.isEditing || indexPath.section == 2
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if (indexPath.section == 0) {
            return UITableViewCell.EditingStyle.delete
        } else if (indexPath.section == 1) {
            return UITableViewCell.EditingStyle.insert
        } else {
            return UITableViewCell.EditingStyle.none
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == 0 && tableView.isEditing) {
            let element = self.selectedElements.remove(at: indexPath.item)
            availableElements.append(element)
            Untis.removeElement(id: element.id)
            tableView.performBatchUpdates({
                tableView.insertRows(at: [IndexPath(item: availableElements.count-1, section: 1)], with: .automatic)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }, completion: { _ in
                tableView.reloadSectionIndexTitles()
            })
        } else if (indexPath.section == 1 && tableView.isEditing) {
            let element = self.availableElements.remove(at: indexPath.item)
            selectedElements.append(element)
            Untis.addElement(id: element.id)
            tableView.performBatchUpdates({
                tableView.insertRows(at: [IndexPath(item: selectedElements.count-1, section: 0)], with: .automatic)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }, completion: { _ in
                tableView.reloadSectionIndexTitles()
            })
        } else if (indexPath.section == 2) {
            reset()
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
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
                self.getCourses()
            } else {
                let alert = UIAlertController(title: "Fehler!", message: "Der Login mit deinen Zugansdaten war nicht erfolgreich. Versuche es später erneut oder setze ggf. die App zurück!", preferredStyle: .alert)
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
            }).sorted(by: { (elA, elB) -> Bool in
                return elA.longName < elB.longName
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
            self.selectedElements = []
            self.availableElements = []
            self.tableView.reloadData()
            UserDefaults.standard.set(false, forKey: "configured")
            self.navigationController?.popViewController(animated: false)
            (self.navigationController?.viewControllers.first as? HomeController)?.showWelcome()
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
    
    @objc func startEdit() {
        tableView.setEditing(true, animated: true)
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(endEdit)), animated: true)
        tableView.deleteSections([2], with: .automatic)
    }
    
    @objc func endEdit() {
        tableView.setEditing(false, animated: true)
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(startEdit)), animated: true)
        tableView.insertSections([2], with: .automatic)
    }
}

