//
//  OverlayViewController.swift
//  Airmont Player tvOS
//
//  Created by François Goudal on 11/03/2021.
//  Copyright © 2021 Airmont. All rights reserved.
//

import UIKit

protocol ProfilesViewControllerDelegate: AnyObject {
    func didSelectProfile(at indexPath: IndexPath)
}

class ProfilesViewController: UIViewController {

    @IBOutlet weak var profileTableView: SelfSizedTableView!
    
    weak var delegate: ProfilesViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        profileTableView.delegate = self
        profileTableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        IPTV.fetchResolutions() {
            self.profileTableView.reloadData()
        }
    }
}

extension ProfilesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return IPTV.resolutions?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value2, reuseIdentifier: nil)
        cell.textLabel?.text = "\(IPTV.resolutions?[indexPath.row].name ?? "nil")"
        cell.detailTextLabel?.text = "\(IPTV.resolutions?[indexPath.row].speed ?? "nil")"
        if ((IPTV.resolutions?[indexPath.row].id) == IPTV.current_resolution) {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
        return cell
    }
}

extension ProfilesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        print("\(IPTV.resolutions?[indexPath.row].name ?? "")")
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }

        delegate?.didSelectProfile(at: indexPath)
    }
}
