//
//  SelfSizedTableView.swift
//  Airmont Player tvOS
//
//  Created by François Goudal on 23/11/2020.
//  Copyright © 2020 Airmont. All rights reserved.
//

import UIKit

class SelfSizedTableView: UITableView {
    var maxHeight: CGFloat = UIScreen.main.bounds.size.height
     
     override func reloadData() {
       super.reloadData()
       self.invalidateIntrinsicContentSize()
       self.layoutIfNeeded()
     }
     
     override var intrinsicContentSize: CGSize {
       let height = min(contentSize.height + 60, maxHeight)
        print("Resizing tableView height to \(height)")
       return CGSize(width: contentSize.width, height: height)
     }

}
