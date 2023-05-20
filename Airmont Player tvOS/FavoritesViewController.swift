//
//  FavoritesViewController.swift
//  Airmont Player tvOS
//
//  Created by François Goudal on 12/03/2021.
//  Copyright © 2021 Airmont. All rights reserved.
//

import UIKit

class FavoritesViewController: UIViewController {

    struct Favorite {
        var channel: IPTV.Channel
        var source_name: String
        var source_id: String
    }
    
    var favorites:[String:[Favorite]] = [:]

    @IBOutlet weak var favoriteTableView: SelfSizedTableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        favoriteTableView.delegate = self
        favoriteTableView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.favorites = [:]
        IPTV.channels?.forEach({ (source_id: String, categories: IPTV.Categories) in
            categories.forEach { (category_name: String, channels: IPTV.Channels) in
                channels.forEach { channel in
                    if (channel.favorite) {
                        var source_name = ""
                        IPTV.sources?.forEach({ source in
                            if ("\(source.id)" == source_id) {
                                source_name = source.name
                            }
                        })
                        print("FOUND FAVORITE \(channel.name)")
                        if (self.favorites[category_name] == nil) {
                            self.favorites[category_name] = []
                        }
                        self.favorites[category_name]?.append(Favorite(channel: channel, source_name: source_name, source_id: source_id))
                        print ("FAVORITES \(category_name) \(self.favorites)")
                    }
                }
            }
        })
        print ("FAVORITES \(self.favorites)")
        self.favoriteTableView.reloadData()
    }
}

extension FavoritesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (IPTV.hasChromecast() && section == 0) {
            return 1
        }
        return Array(favorites.values)[IPTV.hasChromecast() ? section - 1 : section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (IPTV.hasChromecast() && section == 0) {
            return "CHROMECAST"
        }
        return Array(favorites.keys)[IPTV.hasChromecast() ? section - 1 : section]
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return favorites.count + (IPTV.hasChromecast() ? 1 : 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value2, reuseIdentifier: nil)
        if (IPTV.hasChromecast()) {
            if (indexPath.section == 0 && indexPath.row == 0) {
                cell.textLabel?.text = "Chromecast"
                IPTV.sources?.forEach({ source in
                    if (source.chromecast) {
                        cell.detailTextLabel?.text = source.name
                    }
                })
            } else {
                let favorites = Array(self.favorites.values)[indexPath.section - 1]
                let favorite = favorites[indexPath.row]
                cell.textLabel?.text = favorite.channel.name
                var source_name = ""
                IPTV.sources?.forEach({ source in
                    if ("\(source.id)" == favorite.source_id) {
                        source_name = source.name
                    }
                })
                cell.detailTextLabel?.text = source_name
            }
        } else {
            let favorites = Array(self.favorites.values)[indexPath.section]
            let favorite = favorites[indexPath.row]
            cell.textLabel?.text = favorite.channel.name
            var source_name = ""
            IPTV.sources?.forEach({ source in
                if ("\(source.id)" == favorite.source_id) {
                    source_name = source.name
                }
            })
            cell.detailTextLabel?.text = source_name
        }
        cell.textLabel?.textAlignment = .center
        return cell
    }
}

extension FavoritesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
        let offset = IPTV.hasChromecast() ? 1 : 0
        if (indexPath.section == 0 && IPTV.hasChromecast()) {
            print("Chromecast")
            let viewController = UIApplication.shared.windows.first!.rootViewController as! ViewController
            var source_id = 0
            var source_name = "unknown"
            IPTV.sources?.forEach({ source in
                if (source.chromecast) {
                    source_id = source.id
                    source_name = source.name
                }
            })
            print("Setting source to \(source_name)")
            viewController.actionActivity = true
            viewController.messageBoxLabel.text = "Switching source to \(source_name)..."
            viewController.updateActivityIndicator()
            IPTV.setSource(id: source_id) {
                IPTV.castStop {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                        viewController.actionActivity = false
                        viewController.updateActivityIndicator()
                    }
                }
            }
        } else {
            let channels = Array(favorites.values)[indexPath.section - offset]
            print("\(channels[indexPath.row].channel.name)")
            let viewController = UIApplication.shared.windows.first!.rootViewController as! ViewController
            viewController.actionActivity = true
            viewController.messageBoxLabel.text = "Tuning to \(channels[indexPath.row].channel.name)..."
            viewController.updateActivityIndicator()
            IPTV.setChannel(id: channels[indexPath.row].channel.id) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    viewController.actionActivity = false
                    viewController.updateActivityIndicator()
                }
            }
        }
    }
}
