//
//  OverlayViewController.swift
//  Airmont Player tvOS
//
//  Created by François Goudal on 08/02/2022.
//  Copyright © 2022 Airmont. All rights reserved.
//

import UIKit

protocol OverlayViewControllerDelegate: AnyObject {
    func didSelectProfile(at indexPath: IndexPath)
}

func generateQRCode(from string: String) -> UIImage? {
    let data = string.data(using: String.Encoding.ascii)

    if let filter = CIFilter(name: "CIQRCodeGenerator") {
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 3, y: 3)

        if let output = filter.outputImage?.transformed(by: transform) {
            return UIImage(ciImage: output)
        }
    }

    return nil
}

class OverlayViewController: UIViewController {

    @IBOutlet weak var QRCodeImage: UIImageView!
    @IBOutlet weak var containerView: UIView!
    
    weak var delegate: OverlayViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        IPTV.sources?.forEach({ source in
            if (source.chromecast) {
                var urlComponents = URLComponents()
                urlComponents.scheme = "http"
                urlComponents.host = "airmont-gw.local"
                urlComponents.path = "/api/iptv/chromecast/\(source.name)"

                if let url = urlComponents.url {
                    print(url)
                    QRCodeImage.image = generateQRCode(from: url.absoluteString)
                }

            }
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? TabBarViewController {
            if let profilesViewController = viewController.viewControllers?[0] as? ProfilesViewController {
                profilesViewController.delegate = self
            }
        }
    }

}

extension OverlayViewController: ProfilesViewControllerDelegate {
    func didSelectProfile(at indexPath: IndexPath) {
        self.delegate?.didSelectProfile(at: indexPath)
    }
}
