//
//  SplashScreenVC.swift
//  Airmont Player iOS
//
//  Created by Zulqarnain Naveed on 24/05/2023.
//  Copyright © 2023 Airmont. All rights reserved.
//

import UIKit

class SplashScreenVC: UIViewController {

    @IBOutlet weak var gifImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.callingGif()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0){ [weak self] in
            self?.setRootViewController()
        }
        
        
       
        
    }
    
    private func callingGif(){
                let imageData = try? Data(contentsOf: Bundle.main.url(forResource: "airmont", withExtension: "gif")!)
                let advTimeGif = UIImage.gifImageWithData(imageData!)
                let imageView2 = UIImageView(image: advTimeGif)
                imageView2.contentMode = .scaleAspectFit
                imageView2.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                view.addSubview(imageView2)
    }
    
    private func setRootViewController(){
        if let window = (UIApplication.shared.windows.first(where: { $0.isKeyWindow })){
            let vc:ViewController =  UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as! ViewController
            window.rootViewController = vc
            window.makeKeyAndVisible()
             
        }
    }
}


