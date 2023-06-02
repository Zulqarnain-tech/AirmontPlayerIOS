import UIKit
import Foundation
import GCDWebServer
import Alamofire
import AlamofireImage
import TVVLCKit
import Network

class ViewController: UIViewController {
    var webServer: GCDWebServer!

    var mediaPlayer: VLCMediaPlayer!
    var currentlyPlaying: String = "null";
    var shouldStream: Bool = false;
    var watchdogCounter: Int = 0;
    
    var playerActivity = false
    @IBOutlet weak var topBackgroundImage: UIImageView!
    var actionActivity = false
    
    @IBOutlet weak var watermark: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var Loading: UIActivityIndicatorView!
    @IBOutlet weak var message: UILabel!
    
    @IBOutlet weak var movieView: UIView!

    @IBOutlet weak var messageBox: UIView!
    @IBOutlet weak var messageBoxLabel: UILabel!
    
    @IBAction func playPauseTapped(_ sender: Any) {
        print("PLAY/PAUSE TAPPED")
        IPTV.sources?.forEach({ source in
            if (IPTV.current_source == source.id) {
                if (source.chromecast) {
                    self.actionActivity = true;
                    self.messageBoxLabel.text = "Pausing/Resuming..."
                    self.updateActivityIndicator()
                    IPTV.castPause {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                            self.actionActivity = false;
                            self.updateActivityIndicator()
                        }
                    }
                }
            }
        })
    }

    func login() {
        print("login()")
        
        if (IPTV.connectionState != .disconnected) {
            return
        }

        IPTV.connectionState = .connecting
        let guest_mode = UserDefaults.standard.bool(forKey: "guest_mode_preference")
        if (guest_mode) {
            self.message.text = "Connecting..."
            User.auth(login: "", password: "", guest: true) { result in
                switch result {
                case .success(_):
                    IPTV.initialize() {
                        self.watermark.text = IPTV.watermark
                        Gateway.notifyConnectedAdmin {
                        }
                        IPTV.connectionState = .connected
                    }
                case .failure(_):
                    DispatchQueue.main.async {
                        self.message.text = "No Guest resource available"
                    }
                    let seconds = 4.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                        IPTV.connectionState = .disconnected
                    }
                    break
                }
            }
        } else {
            guard
                let login = UserDefaults.standard.string(forKey: "login_preference"),
                let password = UserDefaults.standard.string(forKey: "password_preference")
            else {
                return
            }
            if (login != "" && password != "") {
                self.message.text = "Connecting..."
                User.auth(login: login, password: password, guest: false) { result in
                    switch result {
                    case .success(_):
                        IPTV.initialize() {
                            self.watermark.text = IPTV.watermark
                            Gateway.notifyConnectedAdmin {
                            }
                            IPTV.connectionState = .connected
                        }
                    case .failure(_):
                        DispatchQueue.main.async {
                            self.message.text = "Authentication failed"
                        }
                        let seconds = 4.0
                        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                            IPTV.connectionState = .disconnected
                        }
                        break
                    }
                }
            }
        }
    }
    
//
//    var ref: DNSServiceRef? = nil
//
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(tvOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }

        URLSession.shared.configuration.timeoutIntervalForRequest = 500

        let username = UserDefaults.standard.string(forKey: "login_preference") ?? ""
        let password = UserDefaults.standard.string(forKey: "password_preference") ?? ""
        
        let queue = DispatchQueue.global(qos: .background)
        nwmonitor.start(queue: queue)
//
//        var subservices = Set<String>()
//
//        let id = "id=e3e3f5e83cc70eab05a92134747349c9"
//        let cd = "cd=B1D5681302FD0A541FF1B7D4E015751C"
//        let ve = "ve=05"
//        let md = "md=Chromecast Ultra"
//        let ic = "ic=/setup/icon.png"
//        let fn = "fn=Airmont-Cast FAKE CC"
//        let ca = "ca=201221"
//        let bs = "bs=FA8FCA3BE3A2"
//        let nf = "nf=2"
//        var rdata: [UInt8] = []
//        rdata += [UInt8(id.utf8.count)] + Array(id.utf8)
//        rdata += [UInt8(cd.utf8.count)] + Array(cd.utf8)
//        rdata += [UInt8(ve.utf8.count)] + Array(ve.utf8)
//        rdata += [UInt8(md.utf8.count)] + Array(md.utf8)
//        rdata += [UInt8(ic.utf8.count)] + Array(ic.utf8)
//        rdata += [UInt8(fn.utf8.count)] + Array(fn.utf8)
//        rdata += [UInt8(ca.utf8.count)] + Array(ca.utf8)
//        rdata += [UInt8(bs.utf8.count)] + Array(bs.utf8)
//        rdata += [UInt8(nf.utf8.count)] + Array(nf.utf8)
//        DNSServiceRegister(&ref, 0, 0, "Airmont-Cast_FAKE_CC", "_googlecast._tcp", "local", nil, CFSwapInt16HostToBig(8006), UInt16(rdata.count), rdata, nil, nil)
//
//        if #available(tvOS 14.0, *) {
//            guard let multicast = try? NWMulticastGroup(for:
//                                                            [ .hostPort(host: "224.0.0.251", port: 5353) ])
//            else { return }
//            let group = NWConnectionGroup(with: multicast, using: .udp)
//            group.setReceiveHandler(maximumMessageSize: 16384, rejectOversizedMessages: true) { (message, content, isComplete) in
//                //print("Received message from \(String(describing: message.remoteEndpoint))")
//                //print("\(content!.count) \((content! as NSData).debugDescription)")
//                let flags = Int(content![2])
//                let nb_question = Int(content![5]) //FIXME: MSB of questions
//                if (flags == 0 && nb_question != 0) {
//                    print ("Received a query that contains \(nb_question) question(s)")
//                    var pos = 12
//                    for _ in 1...Int(nb_question) {
//                        let name = DNS.getQuestionName(buf: content!, start: pos)
//                        let type = DNS.getQuestionType(buf: content!, start: pos)
//
//                        print("  - \(type): \(name)")
//                        if (type == .PTR && name.contains("._sub._googlecast._tcp.local")) {
//                            let subservice = name.components(separatedBy: ".")[0]
//                            print ("Got a requested subservice: \(subservice)")
//                            if (!subservices.contains(subservice)) {
//                                subservices.insert(subservice)
//                                //Restart publishing
//                                let list = subservices.joined(separator: ",")
//                                print("Known subservices: \(list)")
//                                DNSServiceRefDeallocate(self.ref)
//                                DNSServiceRegister(&self.ref, 0, 0, "Airmont-Cast_FAKE_CC", "_googlecast._tcp,\(list)", "local", nil, CFSwapInt16HostToBig(8006), UInt16(rdata.count), rdata, nil, nil)
//                            }
//                        }
//                        pos = DNS.getQuestionNext(buf: content!, start: pos)
//                    }
//                }
//            }
//            group.stateUpdateHandler = { (newState) in
//                print("Group entered state \(String(describing: newState))")
//            }
//            group.start(queue: .main)
//
//        } else {
//            // Fallback on earlier versions
//        }
//

        //Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(checkService), userInfo: nil, repeats: true)
        
        UIApplication.shared.isIdleTimerDisabled = true
        //mediaPlayer = VLCMediaPlayer(options: ["-vvv", "--ipv4-timeout=2000"])
        mediaPlayer = VLCMediaPlayer(options: ["--ipv4-timeout=2000"])
        mediaPlayer.videoAspectRatio = UnsafeMutablePointer<CChar>(mutating:("16:9" as NSString).utf8String)
        mediaPlayer.libraryInstance.debugLogging = false;
        mediaPlayer.delegate = self
        mediaPlayer.drawable = movieView

        
        /// 
        /*
         NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { (notification) in
             self.currentlyPlaying = "null"
             self.imageView.image = UIImage(named: "MessageBackground")
             self.message.text = ""
             self.checkService()
         }

         NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { (notification) in
             self.mediaPlayer.stop()
             self.mediaPlayer.media = nil
         }
         */
        

        if ((username == "" || password == "") && !UserDefaults.standard.bool(forKey: "guest_mode_preference")) {
            self.message.text = "Please enter login details in settings app"
        }
    }

    var current_username: String = ""
    var current_password: String = ""
    var current_guest: Bool = false
    var nwmonitor = NWPathMonitor()

    @objc func checkService()
    {
        print("NETWORK PATH STATUS: \(nwmonitor.currentPath.status)")
        if (nwmonitor.currentPath.status != .satisfied) {
            self.message.text = "Network unavailable"
            return
        }
        
        print("checkService()")
        let username = UserDefaults.standard.string(forKey: "login_preference") ?? ""
        let password = UserDefaults.standard.string(forKey: "password_preference") ?? ""
        let guest = UserDefaults.standard.bool(forKey: "guest_mode_preference")

        if (UserDefaults.standard.string(forKey: "api_address_preference") ?? "" == "") {
            if (self.watchdogCounter > 2) {
                self.imageView.image = UIImage(named: "MessageBackground")
                self.currentlyPlaying = "null"
                self.message.text = "Detecting Airmont Gateway..."
                Gateway.address = nil
            } else {
                self.watchdogCounter += 1
            }
        }
        
        if (username != current_username || password != current_password || guest != current_guest) {
            current_username = username
            current_password = password
            current_guest = guest
            print("Settings have changed, resetting")
            IPTV.reset()
            User.accessToken = nil
            shouldStream = false
            self.mediaPlayer.stop()
            self.mediaPlayer.media = nil
            self.currentlyPlaying = "null"
        }

        if ((username == "" || password == "") && !UserDefaults.standard.bool(forKey: "guest_mode_preference")) {
            self.message.text = "Please enter login details in settings app"
            return
        }

        if (User.isLogged()) {
            URLSession.shared.getAllTasks { tasks in
                if (tasks.isEmpty && IPTV.connectionState == .connected) {
                    IPTV.checkService(completed: {})
                }
            }

            let current_resolution = IPTV.resolutions?.first(where: { $0.id == IPTV.current_resolution })
            if (current_resolution?.name == "Stream Off") {
                self.imageView.image = UIImage(named: "MessageBackground")
                self.message.text = "Stream Off profile detected\nPlease, select another one to watch video"
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
                        self.mediaPlayer.play()
                    }
                }
            }
        } else {
            self.imageView.image = UIImage(named: "MessageBackground")
            self.message.text = "Connecting..."
            self.login()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        print("VIEW APPEAR")
            GCDWebServer.setLogLevel(4)
            webServer = GCDWebServer()
            webServer.addDefaultHandler(forMethod: "POST", request: GCDWebServerURLEncodedFormRequest.self, processBlock: { request in
                //Check for update
                Gateway.checkUpdate(vc: self) {
                }
                Gateway.address = String(request.remoteAddressString[..<request.remoteAddressString.lastIndex(of: ":")!])
                
                self.watchdogCounter = 0;
                return GCDWebServerDataResponse(html:"200 OK ")
            })
            try? webServer.start(options: [GCDWebServerOption_Port : 8095,
                                           GCDWebServerOption_BonjourName : "Airmont Player tvOS",
                                           GCDWebServerOption_BonjourType : "_airmontplayer._tcp"])
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        print("VIEW DISAPPEAR")
        if (webServer != nil) {
            webServer.stop()
        }
        webServer = nil
        mediaPlayer.stop()
        self.mediaPlayer.media = nil
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        print("Swiped down")
        return (User.isLogged())
    }
    
    func updateActivityIndicator() {
        if (playerActivity && !actionActivity) {
            Loading.startAnimating()
        } else {
            Loading.stopAnimating()
        }
        if (actionActivity) {
            UIView.transition(with: messageBox, duration: 0.5, options: .transitionCrossDissolve) {
                self.messageBox.isHidden = false
            } completion: { _ in
            }

            messageBox.isHidden = false
        } else {
            UIView.transition(with: messageBox, duration: 0.5, options: .transitionCrossDissolve) {
                self.messageBox.isHidden = true
            } completion: { _ in
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? OverlayViewController {
            viewController.delegate = self
        }
    }
}

extension ViewController: OverlayViewControllerDelegate {
    func didSelectProfile(at indexPath: IndexPath) {
        print("Changed profile")
        self.actionActivity = true;
        self.messageBoxLabel.text = "Switching to \(IPTV.resolutions?[indexPath.row].name ?? "unknown") profile..."
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

extension ViewController: VLCMediaPlayerDelegate {
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
            self.imageView.image = nil
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
