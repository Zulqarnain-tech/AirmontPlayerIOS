//
//  SearchViewController.swift
//  Airmont Player tvOS
//
//  Created by François Goudal on 24/08/2021.
//  Copyright © 2021 Airmont. All rights reserved.
//

import UIKit


class SearchViewController: UIViewController, UISearchResultsUpdating  {
    @IBOutlet weak var tableView: SelfSizedTableView!
    
    func updateSearchResults(for searchController: UISearchController) {
    }
    
    var searchController: UISearchController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let searchResultsViewController = SearchResultsViewController()
        searchController = UISearchController(searchResultsController: searchResultsViewController)
        searchController.searchResultsUpdater = searchResultsViewController
        searchController.hidesNavigationBarDuringPresentation = false
        let searchContainerViewController = UISearchContainerViewController(searchController: searchController)
        searchContainerViewController.tabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: 0)
        let navigationController = UINavigationController(rootViewController: searchContainerViewController)
        view.addSubview(navigationController.view)
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
