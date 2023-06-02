import UIKit
import Foundation
import GCDWebServer

import Alamofire
import AlamofireImage
import Network

class ViewController: UIViewController{
    

    // MARK: - Outlets
    
    @IBOutlet var gifImageView: UIImageView!
    @IBOutlet weak var topBGImage: UIImageView!
    @IBOutlet weak var connectView: UIControl!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextFIeld: UITextField!
    @IBOutlet weak var loginPasswordView: UIControl!
    @IBOutlet weak var clickGuestView: UIControl!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var watermark: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var Loading: UIActivityIndicatorView!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var messageBox: UIView!
    @IBOutlet weak var messageBoxLabel: UILabel!
    
    @IBOutlet var playPauseTapped: UITapGestureRecognizer!
    
    
    // MARK: - Custom Properties
    var webServer: GCDWebServer!
    var currentlyPlaying: String = "null";
    var shouldStream: Bool = false;
    var watchdogCounter: Int = 0;
    
    var playerActivity = false
    var actionActivity = false
    
    var current_username: String = ""
    var current_password: String = ""
    var current_guest: Bool = false
    var nwmonitor = NWPathMonitor()
   
    
    // MARK: - View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        #if DEBUG
        //sebastien.leroy@airmont.com
        // Azerty123
        callingGif()
    self.emailTextFIeld.text = "sebastien.leroy@airmont.com"//"test1@airmont.tv"
    self.passwordTextField.text = "Azerty123"//"Qwerty123"
        #endif
        setNeedsStatusBarAppearanceUpdate()

        overrideUserInterfaceStyle = .dark

        URLSession.shared.configuration.timeoutIntervalForRequest = 500

        let username = UserDefaults.standard.string(forKey: "login_preference") ?? ""
        let password = UserDefaults.standard.string(forKey: "password_preference") ?? ""
        

        if ((username == "" || password == "") && !UserDefaults.standard.bool(forKey: "guest_mode_preference")) {
            self.message.text = ""//"Please enter login details in settings app"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        print("VIEW DISAPPEAR")
        if (webServer != nil) {
            webServer.stop()
        }
        webServer = nil
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

    
    // MARK: - Custom Methods
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
                User.auth(login: login, password: password, guest: false) {result in
                    switch result {
                    case .success(_):
                        IPTV.initialize() {
                            //TODO: watermark
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

    
    // MARK: - Action Methods
    
    @IBAction func connectViewPressed(_ sender: UIControl) {
        if (User.isLogged()) {
            IPTV.initialize() {
                //TODO: watermark
                Gateway.notifyConnectedAdmin {
                }
                IPTV.connectionState = .connected
                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: "MainMenu", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "MainMenuViewController")
                    if let window = (UIApplication.shared.windows.first(where: { $0.isKeyWindow })){
                        window.rootViewController = vc
                        window.makeKeyAndVisible()
                    }
                }
            }
            return
            }
            
        
    
         guard let email = self.emailTextFIeld.text else {return}
         guard let password = self.passwordTextField.text else {return}
         
         if (email != "" && password != "") {
             self.topBGImage.alpha = 0.1
             self.message.text = "Connecting..."
             User.auth(login: email, password: password, guest: false) {result in
                 switch result {
                 case .success(_):
                     UserDefaults.standard.set(email, forKey: "login_preference")
                     UserDefaults.standard.set(password, forKey: "password_preference")
                     IPTV.initialize() {
                         //TODO: watermark
                         Gateway.notifyConnectedAdmin {
                         }
                         self.topBGImage.alpha = 1
                         IPTV.connectionState = .connected
                         DispatchQueue.main.async {
                             let storyboard = UIStoryboard(name: "MainMenu", bundle: nil)
                             let vc = storyboard.instantiateViewController(withIdentifier: "MainMenuViewController")
                             if let window = (UIApplication.shared.windows.first(where: { $0.isKeyWindow })){
                                 window.rootViewController = vc
                                 window.makeKeyAndVisible()
                             }
                         }
                     }
                 case .failure(_):
                     DispatchQueue.main.async {
                         self.message.text = "Authentication failed"
                     }
                     let seconds = 4.0
                     DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                         self.topBGImage.alpha = 1
                         self.message.text = ""
                         IPTV.connectionState = .disconnected
                     }
                     break
                 }
             }
         }
    }
    
    @IBAction func guestViewPressed(_ sender: UIControl) {
        UserDefaults.standard.set(true, forKey: "guest_mode_preference")
        debugPrint("guestView: \(UserDefaults.standard.bool(forKey: "guest_mode_preference"))")
        self.clickGuestView.isHidden = true
        self.loginPasswordView.isHidden = true
//        checkService()
    }
    
    
    @IBAction func loginViewPressed(_ sender: UIControl) {
        UIView.transition(with: self.view, duration: 1, options: .transitionCrossDissolve, animations: {
            self.emailView.isHidden = false
            self.passwordView.isHidden = false
            self.clickGuestView.isHidden = true
            self.loginPasswordView.isHidden = true
            self.connectView.isHidden = false
        }, completion: {
            
            _ in
        })
    }
    
    
    
}

extension ViewController{
    private func callingGif(){
        let imageData = try? Data(contentsOf: Bundle.main.url(forResource: "airmont", withExtension: "gif")!)
        let advTimeGif = UIImage.gifImageWithData(imageData!)
        self.gifImageView.image = advTimeGif//UIImageView(image: advTimeGif)
        gifImageView.contentMode = .scaleAspectFill
        gifImageView.layer.opacity = 0.5
    }
}
