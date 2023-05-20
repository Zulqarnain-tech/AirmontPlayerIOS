//
//  SourcesViewController.swift
//  Airmont Player tvOS
//
//  Created by François Goudal on 16/08/2021.
//  Copyright © 2021 Airmont. All rights reserved.
//

import UIKit

class SourcesViewController: UIViewController {

    @IBOutlet weak var sourceTableView: SelfSizedTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sourceTableView.delegate = self
        sourceTableView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        IPTV.fetchSources {
            self.sourceTableView.reloadData()
        }
    }
}

extension SourcesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (IPTV.sources?.count ?? 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = IPTV.sources?[indexPath.row].name
        cell.textLabel?.textAlignment = .center
        if ((IPTV.sources?[indexPath.row].id) == IPTV.current_source) {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
        cell.layer.cornerRadius = 5
        cell.clipsToBounds = true
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        return cell
    }
}

extension SourcesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
        
        let boxID = IPTV.sources?[indexPath.row].id ?? 0

       // let viewController = UIApplication.shared.windows.first!.rootViewController as! ViewController
        let storyboard = UIStoryboard(name: "VideoPlayer", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "VideoPlayerViewController") as! VideoPlayerViewController
        
        viewController.actionActivity = true;
        //viewController.messageBoxLabel.text = "Switching source to \(IPTV.sources?[indexPath.row].name ?? "unknown")..."
        //viewController.updateActivityIndicator()

        if (IPTV.sources != nil) {
            print("Setting source to \(boxID)")
            IPTV.setSource(id: boxID) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    //viewController.actionActivity = false;
                    //viewController.updateActivityIndicator()
                }
            }
        }
    }
}
