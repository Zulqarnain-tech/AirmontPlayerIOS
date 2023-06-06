//
//  User.swift
//  Airmont Player tvOS
//
//  Created by François Goudal on 23/11/2020.
//  Copyright © 2020 Airmont. All rights reserved.
//

import Foundation

class User {
    static var isDisconnecting:Bool = false

    static var accessToken = UserDefaults.standard.string(forKey: "accessToken")
    //static var accessToken:String? = nil

    static func isLogged() -> Bool {
        if (accessToken == nil) {
            IPTV.connectionState = .disconnected
            return false
        }
        if (self.isDisconnecting) {
            IPTV.connectionState = .disconnected
            return false
        }
        return true
    }
    
    static func auth(login: String, password: String, guest: Bool, completed: @escaping (Result<String, APError>)->()) {
        print("User.auth() ")
        debugPrint("Email: \(login)")
        debugPrint("Password: \(password)")
        debugPrint("url: \(API.getApiURL())/iptv/login")
        //http://195.25.222.131:8888/api/iptv/login
        let params = ["login": login,
                      "password": password,
                      "guest": guest] as Dictionary<String, AnyObject>
// http://airmont-gw.local/api/iptv/login
        var request = URLRequest(url: URL(string: "\(API.getApiURL())/iptv/login")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                guard
                    let rawdata = data
                else {
                    print("ERROR auth() : response data is empty")
                    completed(.failure(.generalError))
                    return
                }
                let json = try JSONSerialization.jsonObject(with: rawdata) as? Dictionary<String, AnyObject>
                if (json?["success"] as? Bool == true) {
                    print("LOGIN SUCCESS")
                    let accessToken = json?["token"] as? String
                    User.accessToken = accessToken
                    //API.api_ip = json?["api_ip"] as? String
                    UserDefaults.standard.set(accessToken, forKey: "accessToken")
                    completed(.success("OK"))
                } else {
                    User.accessToken = nil
                    UserDefaults.standard.set(nil, forKey: "accessToken")
                    print ("LOGIN FAILED")
                    completed(.failure(.authFailed))
                }
            } catch {
                print("ERROR auth(): failed to deserialize response")
            }
        })
        task.resume()
    }
    
    static func disconnect(completed: @escaping ()->()) {
        print("User.disconnect()")
        guard let token = User.accessToken else {
            print("ERROR disconnect() failed: no auth token")
            return
        }
        
        self.isDisconnecting = true
        var request = URLRequest(url: URL(string: "\(API.getApiURL())/iptv/reset")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(token, forHTTPHeaderField: "X-BS-Auth-Token")
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            self.resetUserData()
            self.isDisconnecting = false
            DispatchQueue.main.async {
                completed()
            }
        }).resume()
    }
    
    static func resetUserData() {
        print("User.resetUserData()")
        API.api_ip = nil
        self.accessToken = nil
    }
}
