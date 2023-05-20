//
//  SearchNavController.swift
//  Airmont Player tvOS
//
//  Created by François Goudal on 26/08/2021.
//  Copyright © 2021 Airmont. All rights reserved.
//

import UIKit

class SearchResultsViewController: UITableViewController, UISearchResultsUpdating {
    
    struct Result {
        var channel: IPTV.Channel
        var source_name: String
    }
    
    var results:[Result]? = nil
    
    func updateSearchResults(for searchController: UISearchController) {
        print("SEARCH REQUEST FOR \(searchController.searchBar.text ?? "")")

        guard let channels = IPTV.channels else {
            results = []
            return
        }
        
        results = []
        channels.forEach { (source_id: String, categories: IPTV.Categories) in
            categories.forEach { (category_name: String, channels: IPTV.Channels) in
                channels.forEach { channel in
                    if (channel.name.lowercased().contains(searchController.searchBar.text?.lowercased() ?? "")) {
                        var source_name = ""
                        IPTV.sources?.forEach({ source in
                            if ("\(source.id)" == source_id) {
                                source_name = source.name
                            }
                        })
                        results?.append(Result(channel: channel, source_name: source_name))
                    }
                }
            }
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.text = results?[indexPath.row].channel.name ?? ""
        cell.detailTextLabel?.text = results?[indexPath.row].source_name
        cell.textLabel?.textAlignment = .center
        return cell
    }
        
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
        print("\(results?[indexPath.row].channel.name ?? "")")

        let viewController = UIApplication.shared.windows.first!.rootViewController as! ViewController
        viewController.actionActivity = true
        viewController.messageBoxLabel.text = "Tuning to \(results?[indexPath.row].channel.name ?? "unknown")..."
        viewController.updateActivityIndicator()
        IPTV.setChannel(id: results?[indexPath.row].channel.id ?? 0) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                viewController.actionActivity = false;
                viewController.updateActivityIndicator()
            }
        }
    }
}

class SearchNavController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let searchResultsViewController = SearchResultsViewController()
        
        // setup UISearchController and hook up to search results UIViewController
        let searchController = UISearchController(searchResultsController: searchResultsViewController)
        searchController.searchResultsUpdater = searchResultsViewController
        searchController.hidesNavigationBarDuringPresentation = false
        
        // create a search container that will hold the UISearchController
        let searchContainerViewController = UISearchContainerViewController(searchController: searchController)
        searchContainerViewController.tabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: 0)

        setViewControllers([searchContainerViewController], animated: true)
    }

}
