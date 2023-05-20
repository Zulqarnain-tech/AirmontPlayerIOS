//
//  SearchViewController.swift
//  Airmont Player iOS
//
//  Created by François Goudal on 28/06/2022.
//  Copyright © 2022 Airmont. All rights reserved.
//

import UIKit


var results:[SearchViewController.Result]? = nil

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    struct Result {
        var channel: IPTV.Channel
        var source_name: String
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.text = results?[indexPath.row].channel.name ?? ""
        cell.detailTextLabel?.text = results?[indexPath.row].source_name
        cell.textLabel?.textAlignment = .center
        cell.layer.cornerRadius = 5
        cell.clipsToBounds = true
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        return cell

    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
        print("\(results?[indexPath.row].channel.name ?? "")")
        
        //let viewController = UIApplication.shared.windows.first!.rootViewController as! ViewController
        let storyboard = UIStoryboard(name: "VideoPlayer", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "VideoPlayerViewController") as! VideoPlayerViewController
        viewController.actionActivity = true
        //viewController.messageBoxLabel.text = "Tuning to \(results?[indexPath.row].channel.name ?? "unknown")..."
        //viewController.updateActivityIndicator()
        IPTV.setChannel(id: results?[indexPath.row].channel.id ?? 0) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                viewController.actionActivity = false;
                //viewController.updateActivityIndicator()
            }
        }
        dismiss(animated: true)
    }
    
    @IBOutlet weak var tableView: SelfSizedTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self

        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Type something here to search"
        navigationItem.searchController = search
    }
}

extension SearchViewController: UISearchResultsUpdating {

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
}
