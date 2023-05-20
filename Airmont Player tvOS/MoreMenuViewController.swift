//
//  MoreMenuViewController.swift
//  Airmont Player tvOS
//
//  Created by François Goudal on 03/11/2021.
//  Copyright © 2021 Airmont. All rights reserved.
//

import UIKit

class MoreMenuViewController: UIViewController {

    @IBOutlet weak var moreMenu: UITableView!

    var rightVC: UITabBarController?
    
    let menus = ["Sources", "Channels"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        moreMenu.delegate = self
        moreMenu.dataSource = self
        moreMenu.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .top)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "rightVC") {
            rightVC = segue.destination as? UITabBarController
        }
    }
}

extension MoreMenuViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menus.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = menus[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

extension MoreMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        rightVC?.selectedIndex = indexPath.row
        let channelsVC = rightVC?.viewControllers?[indexPath.row] as? ChannelsRootViewController
        if (channelsVC != nil) {
            channelsVC?.channelsNavController?.popToRootViewController(animated: true)
        }
    }
}
