//
//  VideoPlayerViewController.swift
//  Airmont Player iOS
//
//  Created by Zulqarnain Naveed on 13/05/2023.
//  Copyright © 2023 Airmont. All rights reserved.
//

import UIKit
import MobileVLCKit
import Network
import GCDWebServer

class VideoPlayerViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var subMenuYaxisConstraint: NSLayoutConstraint!
    @IBOutlet weak var movieViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var innerSubMenuViewWidth: NSLayoutConstraint!
    @IBOutlet weak var innerSubMenuView: UIView!
    @IBOutlet weak var subMenuView: UIView!
    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var movieView: UIView!
    @IBOutlet weak var backButton: UIView!
    
    
    // MARK: - Custom Properties
    var webServer: GCDWebServer!
    private var mediaPlayer: VLCMediaPlayer!
    var currentlyPlaying: String = "null";
    var shouldStream: Bool = false;
    var watchdogCounter: Int = 0;
    var playerActivity = false
    var actionActivity = false
    var current_username: String = ""
    var current_password: String = ""
    var current_guest: Bool = false
    var nwmonitor = NWPathMonitor()
    var timer: Timer?
    
    
    // MARK: - View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        //
        if UIDevice.current.userInterfaceIdiom == .phone{
            subMenuYaxisConstraint.constant = 55
            //movieViewBottomConstraint.constant = 150
            let newConstraint = innerSubMenuViewWidth.constraintWithMultiplier(0.87)
            view.removeConstraint(innerSubMenuViewWidth)
            view.addConstraint(newConstraint)
            view.layoutIfNeeded()
            innerSubMenuViewWidth = newConstraint
        }
        //
        setOutViewGesture()
        setNeedsStatusBarAppearanceUpdate()

        overrideUserInterfaceStyle = .dark

        URLSession.shared.configuration.timeoutIntervalForRequest = 500

        let queue = DispatchQueue.global(qos: .background)
        nwmonitor.start(queue: queue)
        
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(checkService), userInfo: nil, repeats: true)

        UIApplication.shared.isIdleTimerDisabled = true
        
        movieView.contentMode = .scaleToFill
        movieView.clipsToBounds = false
        
        mediaPlayer = VLCMediaPlayer(options: ["--ipv4-timeout=2000"])
        //
        let orientation = UIDevice.current.orientation
        
        //mediaPlayer.videoAspectRatio = UnsafeMutablePointer<CChar>(mutating:(orientation.isPortrait == true ? "3:4" : "4:3" as NSString).utf8String)
        mediaPlayer.videoAspectRatio = UnsafeMutablePointer<CChar>(mutating:(orientation.isPortrait == true ? "16:9" : "4:3" as NSString).utf8String)
        mediaPlayer.libraryInstance.debugLogging = false;
        mediaPlayer.delegate = self
        mediaPlayer.drawable = movieView
            self.currentlyPlaying = "null"
            self.message.text = ""
            self.checkService()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.backButton.isHidden = self.subMenuView.isHidden == true
        print("VIEW APPEAR")
            GCDWebServer.setLogLevel(4)
            webServer = GCDWebServer()
            webServer.addDefaultHandler(forMethod: "POST", request: GCDWebServerURLEncodedFormRequest.self, processBlock: {
                request in
                //Check for update
                Gateway.checkUpdate(vc: self) {
                }
                Gateway.address = String(request.remoteAddressString[..<request.remoteAddressString.lastIndex(of: ":")!])

                self.watchdogCounter = 0;
                return GCDWebServerDataResponse(html:"200 OK ")
        })
        try? webServer.start(options: [GCDWebServerOption_Port : 8095,
                                       GCDWebServerOption_BonjourName : "Airmont Player iOS",
                                       GCDWebServerOption_BonjourType : "_airmontplayer._tcp"])
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            // Handle orientation change
            self.handleOrientationChange()
        }, completion: nil)
    }
    func handleOrientationChange() {
        let currentOrientation = UIDevice.current.orientation
        switch currentOrientation {
        case .portrait, .portraitUpsideDown:
            debugPrint(".portrait, .portraitUpsideDown")
            mediaPlayer.videoAspectRatio = UnsafeMutablePointer<CChar>(mutating:("16:9" as NSString).utf8String)
            mediaPlayer.libraryInstance.debugLogging = false;
            mediaPlayer.delegate = self
            mediaPlayer.drawable = movieView
            movieView.layoutIfNeeded()
        case .landscapeLeft, .landscapeRight:
            debugPrint(".landscapeLeft, .landscapeRight")
            mediaPlayer.videoAspectRatio = UnsafeMutablePointer<CChar>(mutating:("4:3" as NSString).utf8String)
            mediaPlayer.libraryInstance.debugLogging = false;
            mediaPlayer.delegate = self
            mediaPlayer.drawable = movieView
            movieView.layoutIfNeeded()
        default:
            // Ignore other orientations
            break
        }
    }



    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
        timer = nil
        print("VIEW DISAPPEAR")
        if (webServer != nil) {
            webServer.stop()
        }
        webServer = nil
        mediaPlayer.stop()
        self.mediaPlayer.media = nil
    }
    deinit {
        debugPrint("Deinit VideoPlayerViewCOntroller ")
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
    // MARK: - Overrided Methods
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        print("Swiped down")
        return (User.isLogged())
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? OverlayViewController {
            viewController.delegate = self
        }
    }
    
    
    // MARK: - Action Methods
    @IBAction func searchViewPressed(_ sender: UIControl) {
        self.backButton.isHidden = true
        proceedToOverlayWithTab(number: 3)
    }
    @IBAction func moreViewPressed(_ sender: UIControl) {
        self.backButton.isHidden = true
        proceedToOverlayWithTab(number: 2)
    }
    @IBAction func settingOptionViewPressed(_ sender: UIControl) {
        self.backButton.isHidden = true
        proceedToOverlayWithTab(number: 0)
    }
    
    
    @IBAction func backButtonPressed(_ sender: UIControl) {
        self.dismiss(animated: false)
    }
        
    @IBAction func favouriteViewPressed(_ sender: UIControl) {
        self.backButton.isHidden = true
        proceedToOverlayWithTab(number: 1)
    }
    
    
    // MARK: - Custom Methods
    private func proceedToOverlayWithTab(number: Int){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "OverlayViewController") as! OverlayViewController
        vc.delegate = self
        vc.selectedIndexByUser = number
        self.present(vc, animated: false)
    }
    
    private func setOutViewGesture(){
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeDownGesture))
            swipeDown.direction = .down
            self.outerView.addGestureRecognizer(swipeDown)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOuterViewTap(_:)))
        outerView.addGestureRecognizer(tapGesture)

    }
    
    @objc func handleOuterViewTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if self.backButton.isHidden{
            self.backButton.isHidden = false
        }else{
            self.backButton.isHidden = true
        }
       
        if self.subMenuView.isHidden{
            self.subMenuView.isHidden = false
        }else{
            self.subMenuView.isHidden = true
        }
        
        // Add your custom code here
    }

    @objc func respondToSwipeDownGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case .down:
                self.backButton.isHidden = true
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "OverlayViewController") as! OverlayViewController
                vc.delegate = self
                self.present(vc, animated: false)
            default:
                break
            }
        }
    }
    
    @objc func   checkService()
    {
        print("NETWORK PATH STATUS: \(nwmonitor.currentPath.status)")
        if (nwmonitor.currentPath.status != .satisfied) {
            self.message.text = "Network unavailable"
            return
        }
        
        print("checkService()")
        
        if (UserDefaults.standard.string(forKey: "api_address_preference") ?? "" == "") {
            if (self.watchdogCounter > 2) {
               // self.imageView.image = UIImage(named: "MessageBackground")
                self.currentlyPlaying = "null"
                self.message.text = "Detecting Airmont Gateway..."
                Gateway.address = nil
            } else {
                self.watchdogCounter += 1
            }
        }


        
        if (User.isLogged()) {
            URLSession.shared.getAllTasks { tasks in
                if (tasks.isEmpty && IPTV.connectionState == .connected) {
                    IPTV.checkService(completed: {})
                }
            }

            let current_resolution = IPTV.resolutions?.first(where: { $0.id == IPTV.current_resolution })
            if (current_resolution?.name == "Stream Off") {
            
                self.shouldStream = false
                self.mediaPlayer.stop()
                self.mediaPlayer.media = nil
            } else {
                if (current_resolution != nil) {
                    if (self.currentlyPlaying != IPTV.stream_url) {
                        self.shouldStream = true
                        self.currentlyPlaying = IPTV.stream_url ?? "nil"

                        self.mediaPlayer.media = VLCMedia(url: URL(string:  self.currentlyPlaying)!)
                        print("PLAYING \(self.currentlyPlaying)")
                        if !self.mediaPlayer.isPlaying{
                            self.mediaPlayer.play()
                        }
                        
                    }
                }
            }
        }
    }

    func updateActivityIndicator() {
        if (playerActivity && !actionActivity) {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
}

extension VideoPlayerViewController: OverlayViewControllerDelegate {

    func didSelectProfile(at indexPath: IndexPath) {
        print("Changed profile")
        self.actionActivity = true;
        //self.messageBoxLabel.text = "Switching to \(IPTV.resolutions?[indexPath.row].name ?? "unknown") profile..."
        self.updateActivityIndicator()
        IPTV.setResolution(id: IPTV.resolutions?[indexPath.row].id ?? 0) {
            if (User.isLogged()) {
                IPTV.checkService(completed: {})
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                self.actionActivity = false;
                self.updateActivityIndicator()
            }
        }
    }
}

extension VideoPlayerViewController: VLCMediaPlayerDelegate {
    func dismissedOverlay() {
        self.backButton.isHidden = self.subMenuView.isHidden
    }
    func mediaPlayerStateChanged(_ aNotification: Notification) {
    //print("STATE CHANGED TO: \(VLCMediaPlayerStateToString(mediaPlayer.state) ?? "nil")")
    if (mediaPlayer.state == .stopped) {
        if (self.shouldStream == false) {
            self.mediaPlayer.stop()
            self.mediaPlayer.media = nil
            currentlyPlaying = "null"
        } else {
            self.mediaPlayer.stop()
            self.mediaPlayer.play()
        }
    }
    if (mediaPlayer.state == .buffering) {
        //self.imageView.image = nil
        self.message.text = ""
        playerActivity = true
        updateActivityIndicator()
    } else {
        playerActivity = false
        updateActivityIndicator()
    }
}
    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        playerActivity = false
        updateActivityIndicator()
    }
}


extension NSLayoutConstraint {
    func constraintWithMultiplier(_ multiplier: CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: self.firstItem!, attribute: self.firstAttribute, relatedBy: self.relation, toItem: self.secondItem, attribute: self.secondAttribute, multiplier: multiplier, constant: self.constant)
    }
}
