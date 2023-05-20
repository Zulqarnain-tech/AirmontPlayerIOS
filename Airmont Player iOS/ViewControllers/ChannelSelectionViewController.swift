//
//  ChannelSelectionViewController.swift
//  Airmont Player iOS
//
//  Created by Zulqarnain Naveed on 13/05/2023.
//  Copyright © 2023 Airmont. All rights reserved.
//

import UIKit
import ScrollableSegmentedControl
import AlamofireImage

class ChannelSelectionViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var customSegmentView: ScrollableSegmentedControl!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    
    
    // MARK: - Custom Properties
    var categoriesNames: [String] = []
    var parentChannelIDs: [String] = []
    var channels: [IPTV.CustomChannel] = []
    var selectedChannel: [IPTV.Channel] = []
    var channelLanguage: String = "N/A"
    
    
    // MARK: - View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loader.isHidden = true
        // Do any additional setup after loading the view.
        let customCollectionViewLayout = CustomCollectionViewFlowLayout()
        self.collectionView.collectionViewLayout = customCollectionViewLayout
        SetUpCustomSegmentView()
    }
    
    
    // MARK: - Action Methods
    
    @IBAction func backButtonPressed(_ sender: UIControl) {
        self.dismiss(animated: false)
    }
    
    
    // MARK: - Custom Methods
    private func SetUpCustomSegmentView(){
        customSegmentView.segmentStyle = .textOnly
       
        //
        guard let channels = IPTV.customChannelsList else {return}
        channels.forEach({
            if !categoriesNames.contains($0.category_Name){
                categoriesNames.append($0.category_Name)
                parentChannelIDs.append($0.parent_channel_id)
            }
        })
        
        categoriesNames.enumerated().forEach { index, categoryName in
            customSegmentView.insertSegment(withTitle: categoryName, at: index)
            
        }
        //
        
        customSegmentView.underlineSelected = true
        customSegmentView.addTarget(self, action: #selector(segmentSelected(sender:)), for: .valueChanged)
        // change some colors
        customSegmentView.segmentContentColor = .gray
        customSegmentView.selectedSegmentContentColor = .white//UIColor(named: "PrimaryGreenColor")
        customSegmentView.backgroundColor = .clear
        customSegmentView.tintColor = .white//UIColor(named: "PrimaryGreenColor")
            
        // Turn off all segments been fixed/equal width.
        // The width of each segment would be based on the text length and font size.
        customSegmentView.fixedSegmentWidth = false
        
        // MARK :- Setting Font
        let largerRedTextAttributes = [NSAttributedString.Key.font: UIFont(name: "Avenir-Heavy", size: 15)]

        customSegmentView.setTitleTextAttributes(largerRedTextAttributes as [NSAttributedString.Key : Any], for: .normal)
        customSegmentView.selectedSegmentIndex = 0
    
        collectionView.reloadData()
    }
    
    @objc func segmentSelected(sender:ScrollableSegmentedControl) {
        print("Segment at index \(sender.selectedSegmentIndex)  selected")
        let selectedCategory = categoriesNames[sender.selectedSegmentIndex]
        let selectedParentChannelID = parentChannelIDs[sender.selectedSegmentIndex]
        
        guard let channels = IPTV.customChannelsList else {return}
        
        let filteredChannels = channels.filter { channel in
            return channel.category_Name == selectedCategory && channel.parent_channel_id == selectedParentChannelID
        }
        self.channels = filteredChannels
        if let selectedChannelArray = filteredChannels[sender.selectedSegmentIndex].channel{
            if channelLanguage == "N/A"{
                self.selectedChannel = selectedChannelArray
            }else{
                print("applying channel language")
                self.selectedChannel = selectedChannelArray.filter({$0.lang == channelLanguage})
            }
            
        }
        collectionView.reloadData()
    }

}

extension ChannelSelectionViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectedChannel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectChannelCollectionCell", for: indexPath) as! SelectChannelCollectionCell
        let channelsArray = self.selectedChannel[indexPath.row]
        cell.channelNameLabel.text = channelsArray.name
        debugPrint("LANGUAGE : \(channelsArray.lang)")
        if let logoUrl = channelsArray.logo_url{
            if let url = URL(string: logoUrl) {
                cell.channelImage.af_setImage(withURL: url)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        loader.isHidden = false
        loader.startAnimating()
        IPTV.setChannel(id: self.selectedChannel[indexPath.row].id ) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                self.loader.isHidden = true
                let storyboard = UIStoryboard(name: "VideoPlayer", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "VideoPlayerViewController")
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: false)
            }
        }
    }
    
    
}

// CustomCollectionViewFlowLayout Managing Cell Size
class CustomCollectionViewFlowLayout: UICollectionViewFlowLayout{
    override func prepare() {
            super.prepare()
        let cellWidth = collectionView!.frame.width / 3 - minimumInteritemSpacing
        let cellHeight = cellWidth / 1
        itemSize = CGSize(width: cellWidth, height: cellHeight)
    }
    override var minimumInteritemSpacing: CGFloat{
        get{
            10
        }
        set{

        }
    }
    override var minimumLineSpacing: CGFloat{
        get{
            10
        }
        set{

        }
    }
}


