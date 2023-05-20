//
//  MainMenuViewController.swift
//  Airmont Player iOS
//
//  Created by Zulqarnain Naveed on 13/05/2023.
//  Copyright © 2023 Airmont. All rights reserved.
//

import UIKit
import DropDown

class MainMenuViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var languageTextLabel: UILabel!
    @IBOutlet weak var tvChannelView: UIControl!
    @IBOutlet weak var chromeCasteView: UIControl!
    @IBOutlet weak var chromeCasteIcon: UIImageView!
    
    
    // MARK: - Custom Properties
    private var languageDropDown:DropDown = DropDown()
    private let languageCodes = ["N/A", "ENG", "FRA", "ARA", "DEU", "TUR", "AZE", "CHI"]
    var languageTitlesArray = ["All", "English","Français", "Arabic", "German", "Turkish", "Azerbaijani", "Chinese"]
    private static var currentLanguageIndex = 0
    private static var currentLanguageCode = "N/A"
    
    
    // MARK: - View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        languageTextLabel.text = languageTitlesArray[MainMenuViewController.currentLanguageIndex]
        self.setDataSourceForLanguageDropDown()
        self.manageChromCasteTVSource()
    }
    
    
    // MARK: - Action Methods
    @IBAction func chromeCastButtonPressed(_ sender: UIControl) {
        let storyboard = UIStoryboard(name: "VideoPlayer", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "VideoPlayerViewController")
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: false)
    }
   
    @IBAction func tvChannelsButtonPressed(_ sender: UIControl) {
        let storyboard = UIStoryboard(name: "ChannelSelection", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ChannelSelectionViewController") as! ChannelSelectionViewController
        vc.channelLanguage = MainMenuViewController.currentLanguageCode
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: false)
    }
    
    
    @IBAction func languageViewPressed(_ sender: UIControl) {
        DropDown.appearance().setupCornerRadius(5)
        languageDropDown.anchorView = sender
        languageDropDown.direction = .bottom
        if let avenierMediumFont = UIFont(name: "Avenir-Medium",size: 12){
            languageDropDown.textFont = avenierMediumFont
        }
        languageDropDown.backgroundColor = .white
        languageDropDown.separatorColor = .lightGray
        languageDropDown.selectedTextColor = .white
        
        languageDropDown.selectionBackgroundColor = .black.withAlphaComponent(0.5)
        
        languageDropDown.bottomOffset = CGPoint(x: 0, y:(sender.frame.size.height - 3))
        languageDropDown.topOffset = CGPoint(x: 0, y:-(sender.bounds.height) )
        languageDropDown.selectionAction = { [weak self] (index: Int, item: String) in
            guard let strongSelf = self else {return}
            
            strongSelf.languageTextLabel.text = item
            MainMenuViewController.currentLanguageCode = strongSelf.languageCodes[index]
            MainMenuViewController.currentLanguageIndex = index
            
            /// Call function upon selecting an item here
        }
        languageDropDown.width = sender.frame.width
        languageDropDown.show()
    }
    
    @IBAction func powerButtonPressed(_ sender: UIButton) {
        debugPrint("powerButtonPressed")
        User.accessToken = nil
        UserDefaults.standard.set(nil, forKey: "accessToken")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ViewController")
        if let window = (UIApplication.shared.windows.first(where: { $0.isKeyWindow })){
            window.rootViewController = vc
            window.makeKeyAndVisible()
        }

    }
    
    
    // MARK: - Custom Methods
    func manageChromCasteTVSource(){
        IPTV.sources?.forEach({
            if $0.chromecast == true{
                self.chromeCasteView.isHidden = false
                
                //ChromeCastIcon
                let image = UIImage(named: "ChromeCastIcon")?.withTintColor(.systemPink, renderingMode: .alwaysOriginal)
                let imageView = UIImageView(image: image)
                imageView.tintColor = .systemPink
                chromeCasteIcon = imageView
            }
            if $0.chromecast == false{
                self.tvChannelView.isHidden = false
            }
        })
    }
    
    private func setDataSourceForLanguageDropDown(){
        self.languageDropDown.dataSource = languageTitlesArray
    } 
    
}
