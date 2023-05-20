//
//  ChannelsRootViewController.swift
//  Airmont Player tvOS
//
//  Created by François Goudal on 23/06/2022.
//  Copyright © 2022 Airmont. All rights reserved.
//

import UIKit

class ChannelsRootViewController: UIViewController {

    var channelsNavController: UINavigationController?
    @IBOutlet weak var currentSourceLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        IPTV.sources?.forEach({ source in
            if (source.id == IPTV.current_source) {
                currentSourceLabel.text = source.name
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "channelsNavController") {
            channelsNavController = segue.destination as? UINavigationController
        }
    }
}
