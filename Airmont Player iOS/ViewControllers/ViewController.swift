import UIKit
import Foundation
//import GCDWebServer

import Alamofire
import AlamofireImage
import Network
import DropDown

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
    private var emailListDropDown:DropDown = DropDown()
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
        setDataSourceForLanguageDropDown()
        emailTextFIeld.delegate = self
        #if DEBUG
        callingGif()
//    self.emailTextFIeld.text = "test1@airmont.tv"
//    self.passwordTextField.text = "Qwerty123"
        self.emailTextFIeld.text = "sebastien.leroy@airmont.com"
        self.passwordTextField.text = "Azerty123"
        #endif
        if let _ = self.emailTextFIeld.placeholder{
            self.emailTextFIeld.attributedPlaceholder = NSAttributedString(string:self.emailTextFIeld.placeholder!,
                                                                           attributes:[NSAttributedString.Key.foregroundColor: UIColor.darkGray])
          }
        if let _ = self.passwordTextField.placeholder{
            self.passwordTextField.attributedPlaceholder = NSAttributedString(string:self.passwordTextField.placeholder!,
                                                                           attributes:[NSAttributedString.Key.foregroundColor: UIColor.darkGray])
          }
        setNeedsStatusBarAppearanceUpdate()

        overrideUserInterfaceStyle = .dark

        URLSession.shared.configuration.timeoutIntervalForRequest = 500

        let username = UserDefaults.standard.string(forKey: "login_preference")
        let password = UserDefaults.standard.string(forKey: "password_preference")
//        if let savedEmail = UserDefaults.standard.string(forKey: "login_preference"){
//            self.emailTextFIeld.text = savedEmail
//        }
//        if let savedPassword = UserDefaults.standard.string(forKey: "password_preference"){
//            self.passwordTextField.text = savedPassword
//        }

        if ((username == "" || password == "") && !UserDefaults.standard.bool(forKey: "guest_mode_preference")) {
            self.message.text = ""//"Please enter login details in settings app"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        print("VIEW APPEAR")
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        print("VIEW DISAPPEAR")
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
                     let defaults = UserDefaults.standard
                     
                     if var savedArray = UserDefaults.standard.stringArray(forKey: "saved_emails_List") {
                         var savedPasswordsArray = UserDefaults.standard.stringArray(forKey: "saved_passwords_List")
                         // Modify the array by appending a new element
                    
                         if let index = savedArray.firstIndex(of: email) {
                             savedArray.remove(at: index)
                             savedPasswordsArray?.remove(at: index)
                         }
                         savedArray.append(email)
                         savedPasswordsArray?.append(password)
                         defaults.set(savedArray, forKey: "saved_emails_List")
                         defaults.set(savedPasswordsArray, forKey: "saved_passwords_List")
                     }else{ 
                         var savedEmails: [String] = []
                         var savedPassword: [String] = []
                         savedEmails.append(email)
                         savedPassword.append(password)
                         defaults.set(savedEmails, forKey: "saved_emails_List")
                         defaults.set(savedPassword, forKey: "saved_passwords_List")
                     }
                     
                     if let savedArray = defaults.stringArray(forKey: "saved_emails_List") {
                         // Print all the array elements
                         for (index, element) in savedArray.enumerated() {
                             print("\(element) at index : \(index)")
                         }
                     }
                     if let savedArray = defaults.stringArray(forKey: "saved_passwords_List") {
                        
                         for (index, element) in savedArray.enumerated() {
                             print("\(element) at index : \(index)")
                         }
                     }
                     
                     
                     UserDefaults.standard.set(email, forKey: "login_preference")
                     UserDefaults.standard.set(password, forKey: "password_preference")
                     defaults.synchronize()
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

extension ViewController: UITextFieldDelegate{
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if textField == self.emailTextFIeld{
            displaySavedEmailsList()
        }
    }
    
    func displaySavedEmailsList(){
        debugPrint("displaySavedEmailsList")
        DropDown.appearance().setupCornerRadius(5)
        emailListDropDown.anchorView = self.emailTextFIeld
        emailListDropDown.direction = .bottom
        if let avenierMediumFont = UIFont(name: "Avenir-Medium",size: 12){
            emailListDropDown.textFont = avenierMediumFont
        }
        emailListDropDown.backgroundColor = .white
        emailListDropDown.separatorColor = .lightGray
        emailListDropDown.selectedTextColor = .white
        
        emailListDropDown.selectionBackgroundColor = .black.withAlphaComponent(0.5)
        
        emailListDropDown.bottomOffset = CGPoint(x: 0, y:(self.emailTextFIeld.frame.size.height - 3))
        emailListDropDown.topOffset = CGPoint(x: 0, y:-(self.emailTextFIeld.bounds.height) )
        emailListDropDown.selectionAction = { [weak self] (index: Int, item: String) in
            guard let strongSelf = self else {return}
            
            
            strongSelf.emailTextFIeld.text = item
            if let emailsArray = UserDefaults.standard.stringArray(forKey: "saved_emails_List"){
                if let indexEmail = emailsArray.firstIndex(of: item) {
                    let passwordsArray = UserDefaults.standard.stringArray(forKey: "saved_passwords_List")
                    if let password = passwordsArray?[indexEmail]{
                        self?.passwordTextField.text = password
                        debugPrint("Selected password \(password)")
                    }
                    
                    
                }
                
                /// Call function upon selecting an item here
            }
            
            /// Call function upon selecting an item here
        }
        emailListDropDown.width = self.emailTextFIeld.frame.width
        emailListDropDown.show()
    }
    func setDataSourceForLanguageDropDown(){
        if let savedArray = UserDefaults.standard.stringArray(forKey: "saved_emails_List") {
            self.emailListDropDown.dataSource = savedArray
        }
        
    }

}
