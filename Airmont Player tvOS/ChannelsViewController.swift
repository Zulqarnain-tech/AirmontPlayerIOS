//
//  ChannelsViewController.swift
//  Airmont Player tvOS
//
//  Created by François Goudal on 16/08/2021.
//  Copyright © 2021 Airmont. All rights reserved.
//

import UIKit

class ChannelsViewController: UIViewController {
        
    @IBOutlet weak var channelTableView: SelfSizedTableView!
    
    var category_name = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        channelTableView.delegate = self
        channelTableView.dataSource = self
        let shortPress = UITapGestureRecognizer(target: self, action: #selector(shortpress))
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longpress))
        channelTableView.addGestureRecognizer(longPress)
        channelTableView.addGestureRecognizer(shortPress)
    }
    
    @objc func shortpress(sender: UITapGestureRecognizer) {
        let channels = IPTV.channels?["\(IPTV.current_source ?? 0)"]?[category_name]
        if sender.state == UIGestureRecognizer.State.ended {
            let tapLocation = sender.location(in: self.channelTableView)
            if let tapIndexPath = self.channelTableView.indexPathForRow(at: tapLocation) {
                let viewController = UIApplication.shared.windows.first!.rootViewController as! ViewController
                viewController.actionActivity = true
                viewController.messageBoxLabel.text = "Tuning to \(channels?[tapIndexPath.row].name ?? "unknown")..."
                viewController.updateActivityIndicator()
                IPTV.setChannel(id: channels?[tapIndexPath.row].id ?? 0) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                        viewController.actionActivity = false;
                        viewController.updateActivityIndicator()
                    }
                }
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @objc func longpress(sender: UILongPressGestureRecognizer) {
        let channels = IPTV.channels?["\(IPTV.current_source ?? 0)"]?[category_name]
        if sender.state == UIGestureRecognizer.State.began {
            let tapLocation = sender.location(in: self.channelTableView)
            if let tapIndexPath = self.channelTableView.indexPathForRow(at: tapLocation) {
                if (channels?[tapIndexPath.row].favorite ?? false == false) {
                    IPTV.channels?["\(IPTV.current_source ?? 0)"]?[self.category_name]?[tapIndexPath.row].favorite = true;
                    if #available(tvOS 13.0, *) {
                        let favicon = UIImage(systemName: "star.fill")
                        self.channelTableView.cellForRow(at: tapIndexPath)?.accessoryView = UIImageView(image: favicon)
                        self.channelTableView.cellForRow(at: tapIndexPath)?.accessoryView?.tintColor = .darkGray
                    }
                    IPTV.addFavorite(id: channels?[tapIndexPath.row].id ?? 0) {
                        IPTV.fetchChannels {
                        }
                    }
                } else {
                    IPTV.channels?["\(IPTV.current_source ?? 0)"]?[self.category_name]?[tapIndexPath.row].favorite = false;
                    self.channelTableView.cellForRow(at: tapIndexPath)?.accessoryView = .none
                    IPTV.delFavorite(id: channels?[tapIndexPath.row].id ?? 0) {
                        IPTV.fetchChannels {
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.channelTableView.reloadData()
    }
}

extension ChannelsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let channels = IPTV.channels?["\(IPTV.current_source ?? 0)"]?[category_name]
        return channels?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let channels = IPTV.channels?["\(IPTV.current_source ?? 0)"]?[category_name]

        let cell = tableView.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath)
        cell.textLabel?.text = channels?[indexPath.row].name ?? ""
        cell.textLabel?.textAlignment = .center

        cell.accessoryView = nil
        if (channels?[indexPath.row].favorite ?? false) {
            if #available(tvOS 13.0, *) {
                let favicon = UIImage(systemName: "star.fill")
                cell.accessoryView = UIImageView(image: favicon)
                cell.accessoryView?.tintColor = .darkGray
            }

        }
        return cell
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(category_name)"
    }
}

extension ChannelsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textAlignment = .center
        }
    }
}
