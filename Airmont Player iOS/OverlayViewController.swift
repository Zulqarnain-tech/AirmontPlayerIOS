//
//  OverlayViewController.swift
//  Airmont Player iOS
//
//  Created by François Goudal on 11/03/2021.
//  Copyright © 2021 Airmont. All rights reserved.
//

import UIKit

protocol OverlayViewControllerDelegate: AnyObject {
    func didSelectProfile(at indexPath: IndexPath)
    func dismissedOverlay()
}
extension OverlayViewControllerDelegate{
    func dismissedOverlay(){}
}
class OverlayViewController: UIViewController {
    
    @IBOutlet weak var dimmingView: UIView!
    var selectedIndexByUser = -1000
    
    weak var delegate: OverlayViewControllerDelegate?

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? TabBarViewController {
            if self.selectedIndexByUser != -1000{
                viewController.selectedIndexByUser = self.selectedIndexByUser
            }
            
            if let profilesViewController = viewController.viewControllers?[0] as? ProfilesViewController {
                profilesViewController.delegate = self
            }
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setNeedsStatusBarAppearanceUpdate()

        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(self.dimmingViewTapped(sender:)))
        dimmingView.addGestureRecognizer(tapgesture)
    }

    @objc func dimmingViewTapped(sender:UITapGestureRecognizer) {
        self.delegate?.dismissedOverlay()
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension OverlayViewController: ProfilesViewControllerDelegate {
    func didSelectProfile(at indexPath: IndexPath) {
        self.delegate?.didSelectProfile(at: indexPath)
    }
}
