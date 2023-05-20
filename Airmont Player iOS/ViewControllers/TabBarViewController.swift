//
//  TabBarViewController.swift
//  Airmont Player iOS
//
//  Created by François Goudal on 22/03/2021.
//  Copyright © 2021 Airmont. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    var selectedIndexByUser = -1000
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("OVERLAY")

        if (UserDefaults.standard.bool(forKey: "guest_mode_preference")) {
            self.viewControllers = self.viewControllers?.filter() {$0.tabBarItem.title == "Profiles"}
        }
        if (UserDefaults.standard.bool(forKey: "hide_profiles_preference")) {
            self.viewControllers = self.viewControllers?.filter() {$0.tabBarItem.title != "Profiles"}
            print("HIDE PROFILES")
        }
        if (UserDefaults.standard.bool(forKey: "hide_more_preference")) {
            self.viewControllers = self.viewControllers?.filter() {$0.tabBarItem.title != "More"}
            print("HIDE MORE")
        }
        if (UserDefaults.standard.bool(forKey: "hide_search_preference")) {
            self.viewControllers = self.viewControllers?.filter() {$0.tabBarItem.tag != 42}
            print("HIDE SEARCH")
        }
        let current_resolution = IPTV.resolutions?.first(where: { $0.id == IPTV.current_resolution })
        var hasFavorites = IPTV.hasChromecast()
        IPTV.channels?.forEach({ (box: String, category: IPTV.Categories) in
            category.forEach { (name: String, channels: IPTV.Channels) in
                channels.forEach { channel in
                    if (channel.favorite) {
                        hasFavorites = true
                    }
                }
            }
        })
        if (current_resolution?.name != "Stream_Off" &&
            hasFavorites &&
            !UserDefaults.standard.bool(forKey: "guest_mode_preference")) {
            if selectedIndexByUser == -1000{
                self.selectedIndex = self.viewControllers?.firstIndex() {$0.tabBarItem.title == "Favorites"} ?? 0
            }else{
                self.selectedIndex = selectedIndexByUser
            }
            
        }

        self.tabBar.unselectedItemTintColor = .darkGray
        self.tabBar.tintColor = .white
    }
}
