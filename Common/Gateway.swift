//
//  Gateway.swift
//  Airmont Player
//
//  Created by François Goudal on 01/02/2021.
//  Copyright © 2021 Airmont. All rights reserved.
//

import UIKit

class Gateway {
    static var lastTimeResponded: Date? = nil
    static var address:String? = nil

    static func getCredentials(completed: @escaping (Result<Dictionary<String, AnyObject>, APError>)->()) {
        var request = URLRequest(url: URL(string: "http://\(self.address ?? "airmont-gw.local"):8080/ag?user=guest")!, timeoutInterval: 5)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                guard
                    let rawdata = data
                else {
                    print("ERROR fetchApp() : response data is empty")
                    completed(.failure(.generalError))
                    return
                }
                let json = try JSONSerialization.jsonObject(with: rawdata) as! Dictionary<String, AnyObject>

                DispatchQueue.main.async {
                    completed(.success(json))
                }
            } catch {
                completed(.failure(.generalError))
            }
        }).resume()
    }

    static func notifyConnectedAdmin(completed: @escaping ()->()) {
        var request = URLRequest(url: URL(string: "http://\(self.address ?? "airmont-gw.local"):8080/ag?user=admin&action=connect")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            DispatchQueue.main.async {
                completed()
            }
        }).resume()
    }

    static func notifyConnectedGuest(completed: @escaping ()->()) {
        var request = URLRequest(url: URL(string: "http://\(self.address ?? "airmont-gw.local"):8080/ag?user=guest&action=connect")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            DispatchQueue.main.async {
                completed()
            }
        }).resume()
    }
    
    static func performUpdate(completed: @escaping ()->()) {
        var request = URLRequest(url: URL(string: "http://\(self.address ?? "airmont-gw.local")/api/update")!)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            DispatchQueue.main.async {
                completed()
            }
        }).resume()
    }
    
    static func checkUpdate(vc: UIViewController, completed: @escaping ()->()) {
        if let lastresponse = lastTimeResponded {
            if (lastresponse.addingTimeInterval(60 * 60 * 24) > Date()) {
                //Only ask again after 24 hours
                return
            }
        }

        var request = URLRequest(url: URL(string: "http://\(self.address ?? "airmont-gw.local")/api/version")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                guard
                    let rawdata = data
                else {
                    print("ERROR checkUpdate() : response data is empty")
                    return
                }
                let json = try JSONSerialization.jsonObject(with: rawdata) as? Dictionary<String, AnyObject>
                if (json?["update_available"] as? Bool ?? false) {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Software update", message: "A software update is available for your Airmont Gateway", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Update now", style: UIAlertAction.Style.default, handler: { alertAction in
                            performUpdate {
                                let alert2 = UIAlertController(title: "Software update", message: "Your Gateway updating process has been started. It will be unavailable for a few minutes.", preferredStyle: UIAlertController.Style.alert)
                                alert2.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { alertAction in
                                    alert2.dismiss(animated: true, completion: nil)
                                }))
                                DispatchQueue.main.async {
                                    vc.present(alert2, animated: true, completion: nil)
                                }
                            }
                            lastTimeResponded = Date()
                            alert.dismiss(animated: true, completion: nil)
                        }))
                        alert.addAction(UIAlertAction(title: "Later", style: UIAlertAction.Style.default, handler: { alertAction in
                            lastTimeResponded = Date()
                            alert.dismiss(animated: true, completion: nil)
                        }))
                        DispatchQueue.main.async {
                            vc.present(alert, animated: true, completion: nil)
                        }
                    }
                } else {
                    lastTimeResponded = Date()
                }

                DispatchQueue.main.async {
                    completed()
                }

            } catch {
                print("ERROR checkUpdate(): failed to deserialize response")
            }
        }).resume()
    }
}
