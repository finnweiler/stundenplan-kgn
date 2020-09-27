//
//  HomeController.swift
//  timetable-iphone
//
//  Created by Finn Weiler on 17.03.19.
//  Copyright © 2019 Finn Weiler. All rights reserved.
//

import UIKit
import SwiftUI


class HomeController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, PlanControllerDelegate {
    
    var configured = UserDefaults.standard.bool(forKey: "configured")
    
    var refreshingCount = 0
    
    let indicator = UIActivityIndicatorView(style: .gray)
    var vcs: Array<UIViewController> = [PlanController(date: Date()), PlanController(date: Date() + 60 * 60 * 24 * 7)]
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Stundenplan"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: #selector(showSettings))
        
        if #available(iOS 14.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "paint-palette"), style: .plain, target: self, action: #selector(showCustomize))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: indicator)
            indicator.startAnimating()
        }
        
        if #available(iOS 13.0, *) {
            navigationItem.leftBarButtonItem?.tintColor = UIColor.label
            navigationItem.rightBarButtonItem?.tintColor = UIColor.label
        } else {
            navigationItem.leftBarButtonItem?.tintColor = .black
            navigationItem.rightBarButtonItem?.tintColor = .black
        }
        
        view.backgroundColor = UIColor(named: "background")
            //UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
        
        self.dataSource = self
        self.delegate = self
        
        setViewControllers([vcs[0]], direction: .forward, animated: true, completion: nil)
        
        vcs.forEach { (vc) in
            guard let vc = vc as? PlanController else { return }
            vc.delegate = self
            if (vc.refreshing) { refreshingCount += 1 }
        }
        
        if (!configured) { showWelcome() }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        configured = UserDefaults.standard.bool(forKey: "configured")
        if (configured) {
            refreshPlans()
        } else {
            showWelcome()
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = vcs.firstIndex(of: viewController)! - 1
        if index < 0 { return nil }
        return vcs[index]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = vcs.firstIndex(of: viewController)! + 1
        if index > vcs.count - 1 { return nil }
        return vcs[index]
    }
    
    @objc func showSettings(editing: Bool = false) {
        let settings = SettingsController()
        if (editing) { settings.startEdit() }
        navigationController?.pushViewController(settings, animated: true)
    }
    
    
    @available(iOS 14.0, *)
    @objc func showCustomize() {
        let controller = UIHostingController(rootView: CustomizeView())
        navigationController?.navigationBar.tintColor = UIColor.label
        controller.navigationItem.title = "Farbeinstellungen"
        controller.view.backgroundColor = UIColor(named: "background")
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func showWelcome() {
        let storyboard = UIStoryboard(name: "main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "welcomeController")
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: false, completion: nil)
    }
    
    func refreshPlans() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastFetchBG")
        vcs.forEach { (vc) in
            guard let vc = vc as? PlanController else { return }
            vc.fetchTimetable()
        }
    }
    
    func didStartRefreshing() {
        refreshingCount += 1
        if (refreshingCount != 0) {
            indicator.startAnimating()
        }
    }
    
    func didEndRefreshing(success: Bool) {
        refreshingCount -= 1
        if (refreshingCount == 0) {
            indicator.stopAnimating()
        }
    }
}
