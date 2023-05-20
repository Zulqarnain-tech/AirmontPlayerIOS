//
//  CategoriesViewController.swift
//  Airmont Player tvOS
//
//  Created by François Goudal on 16/08/2021.
//  Copyright © 2021 Airmont. All rights reserved.
//

import UIKit

class CategoriesViewController: UIViewController {
    
    @IBOutlet weak var categoryTableView: SelfSizedTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        categoryTableView.delegate = self
        categoryTableView.dataSource = self
        self.title = "CATEGORIES"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.categoryTableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let channelsVC = segue.destination as? ChannelsViewController
        let this_box = IPTV.channels?["\(IPTV.current_source ?? 0)"] ?? [:]
        let name = Array(this_box.keys)[categoryTableView.indexPathForSelectedRow?.row ?? -1]

        channelsVC?.category_name = name
    }
}

extension CategoriesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let this_box = IPTV.channels?["\(IPTV.current_source ?? 0)"]
        return this_box?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let this_box = IPTV.channels?["\(IPTV.current_source ?? 0)"] ?? [:]
        let name = Array(this_box.keys)[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        cell.textLabel?.text = name
        cell.textLabel?.textAlignment = .center
        cell.layer.cornerRadius = 5
        cell.clipsToBounds = true
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        return cell
    }
}

extension CategoriesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textAlignment = .center
        }
    }
}
