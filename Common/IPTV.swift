//
//  IPTV.swift
//  Airmont Player tvOS
//
//  Created by François Goudal on 20/11/2020.
//  Copyright © 2020 Airmont. All rights reserved.
//

import UIKit






class IPTV {

    typealias Channels = [Channel]
    typealias Categories = [String:Channels]
    typealias Sources = [String:Categories]

    
    struct CustomChannel: Codable {
        var channel: [Channel]?
        var parent_channel_id: String
        var category_Name: String
    }
    
    
    struct Channel: Codable {
        var id: Int
        var name: String
        var favorite: Bool
        var lang: String
        var logo_url: String?
    }
    struct ChannelsResponse: Codable {
        var success: Bool
        var message: String
        var channels: Sources
    }

    struct Source: Codable {
        var id: Int
        var name: String
        var chromecast: Bool
    }
    struct SourcesResponse: Codable {
        var success: Bool
        var message: String
        var sources: [Source]
    }

    struct Resolution: Codable {
        var id: Int
        var name: String
        var speed: String
    }
    struct ResolutionsResponse: Codable {
        var success: Bool
        var message: String
        var resolutions: [Resolution]
    }
    
    // Sources list
    static var sources: [Source]? = nil

    // Current box
    static var current_source:Int? = nil
    
    //Current resolution
    static var current_resolution:Int? = nil

    //All resolution for this parc
    static var resolutions: [Resolution]? = nil
    
    // Channels list
    static var channels:Sources? = nil
    static var customChannelsList:[CustomChannel]? = []

    static var stream_url:String? = nil
    
    static var watermark:String? = nil

    enum connectionState_e {
        case disconnected
        case connecting
        case connected
    }
    static var connectionState:connectionState_e = .disconnected
    
    /*
    * Reset all property when user disconnect
    */
    static func resetData() {
        IPTV.sources = nil;
        IPTV.current_source = nil;
        IPTV.resolutions = nil;
        IPTV.current_resolution = nil;
        IPTV.channels = nil;
        IPTV.stream_url = nil;
        IPTV.watermark = nil;
    }

    /*
    *     Init
    */
    static func initialize(completed: @escaping ()->()) {
        print("IPTV.initialize()")
        IPTV.apiConnect {
            IPTV.checkService {
                IPTV.fetchSources {
                    IPTV.fetchResolutions {
                        IPTV.fetchChannels {
                            completed();
                        }
                    }
                }
            }
        }
    }
        
    static func apiConnect(completed: @escaping ()->()) {
        print("IPTV.apiConnect()")
        guard let token = User.accessToken else {
            print("ERROR apiConnect() failed: no auth token")
            return;
        }
            
        var request = URLRequest(url: URL(string: "\(API.getApiURL())/iptv/connect")!)
        request.timeoutInterval = 500
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                guard
                    let rawdata = data
                else {
                    print("ERROR apiConnect() : response data is empty")
                    return
                }
                let json = try JSONSerialization.jsonObject(with: rawdata) as? Dictionary<String, AnyObject>
                if (json?["success"] as? Bool == true) {
                    DispatchQueue.main.async {
                        completed()
                    }
                } else {
                    print("ERROR apiConnect(): connection didn't succeed")
                }

            } catch {
                print("ERROR apiConnect(): failed to deserialize response")
            }
        }).resume()
    }

    static func hasChromecast() -> Bool {
        var result = false
        IPTV.sources?.forEach({ source in
            if (source.chromecast) {
                result = true
            }
        })
        return result
    }

    /*
    *    Check if Encoder is OK for current user
    */
    static func checkService(completed: @escaping ()->()) {
        print("IPTV.checkService()")
        guard let token = User.accessToken else {
            print("ERROR checkService() failed: no auth token")
            return
        }

        var request = URLRequest(url: URL(string: "\(API.getApiURL())/iptv/status")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                guard
                    let rawdata = data
                else {
                    print("ERROR checkService() : response data is empty")
                    return
                }
                let json = try JSONSerialization.jsonObject(with: rawdata) as? Dictionary<String, AnyObject>
                DispatchQueue.main.async {
                    completed()
                }
                IPTV.current_resolution = json?["resolution"] as? Int
                IPTV.current_source = json?["source"] as? Int
                IPTV.stream_url = json?["url"] as? String
                IPTV.watermark = json?["watermark"] as? String
                
                
                if let response = response as? HTTPURLResponse, response.statusCode == 401 {
                    print("Token is invalid")
                    User.resetUserData()
                    DispatchQueue.main.async {
                        (UIApplication.shared.windows.first!.rootViewController! as! ViewController).dismiss(animated: true, completion: nil)
                    }
                }
                   
                if (json?["success"] as? Bool != true && json?["message"] as? String == "ERROR_NOT_CONNECTED") {
                    print("You have been disconnected")
                    User.disconnect {
                    }
                    DispatchQueue.main.async {
                        (UIApplication.shared.windows.first!.rootViewController! as! ViewController).dismiss(animated: true, completion: nil)
                    }
                }
            } catch {
                print("ERROR checkService(): failed to deserialize response")
            }
        }).resume()
    }

    /*
    *    Reset global
    */
    static func reset() {
        print("IPTV.reset()")
        guard let token = User.accessToken else {
            print("ERROR reset() failed: no auth token")
            return;
        }

        var request = URLRequest(url: URL(string: "\(API.getApiURL())/iptv/disconnect")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            print("ResetEncoderSuccess")
        }).resume()
    }

    /*
    *    List sources
    */
    static func fetchSources(completed: @escaping ()->()) {
        print("IPTV.fetchSources()")
        guard let token = User.accessToken else {
            print("ERROR fetchSources() failed: no auth token")
            return
        }
        
        var request = URLRequest(url: URL(string: "\(API.getApiURL())/iptv/source")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            guard
                let rawdata = data
            else {
                print("ERROR fetchSources() : response data is empty")
                return
            }
            let decoder = JSONDecoder()
            if let response = try? decoder.decode(SourcesResponse.self, from: rawdata) {
                if (response.success) {
                    self.sources = response.sources
                    print("Sources \(self.sources!)")
                    DispatchQueue.main.async {
                        completed()
                    }
                } else {
                    print("ERROR fetchSources(): failed to retreive sources")
                }
            } else {
                print("ERROR fetchSources(): failed to deserialize response")
            }
        }).resume()
    }

    /*
    *    Set source from IDx
    */
    static func setSource(id: Int, completed: @escaping ()->()) {
        print("IPTV.setSource()")
        guard let token = User.accessToken else {
            print("ERROR setSource() failed: no auth token")
            return
        }
        
        let query = ["id": id]
        var request = URLRequest(url: URL(string: "\(API.getApiURL())/iptv/source")!)
        request.httpMethod = "PUT"
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: query, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
                do {
                    guard
                        let rawdata = data
                    else {
                        print("ERROR setSource() : response data is empty")
                        return
                    }
                    let json = try JSONSerialization.jsonObject(with: rawdata) as? Dictionary<String, AnyObject>
                    IPTV.current_source = json?["source"] as? Int
                    DispatchQueue.main.async {
                        completed()
                    }
                } catch {
                    print("ERROR setSource(): failed to deserialize response")
                }
            }).resume()
        } catch {
            print("ERROR setResolution(): failed to serialize")
        }
    }

    static func addFavorite(id: Int, completed: @escaping ()->()) {
        guard let token = User.accessToken else {
            print("ERROR addFavorite() failed: no auth token")
            return;
        }
        let query = ["id": id]
        var request = URLRequest(url: URL(string: "\(API.getApiURL())/iptv/favorite")!)
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: query, options: [])
            request.httpMethod = "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
                print("ADD FAVORITE COMPLETE")
                DispatchQueue.main.async {
                    completed()
                }
            }).resume()
        } catch {
            print("ERROR addFavorite(): failed to serialize")
        }
    }

    static func delFavorite(id: Int, completed: @escaping ()->()) {
        guard let token = User.accessToken else {
            print("ERROR delFavorite() failed: no auth token")
            return;
        }
        let query = ["id": id]
        var request = URLRequest(url: URL(string: "\(API.getApiURL())/iptv/favorite")!)
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: query, options: [])
            request.httpMethod = "DELETE"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
                DispatchQueue.main.async {
                    completed()
                }
            }).resume()
        } catch {
            print("ERROR delFavorite(): failed to serialize")
        }
    }

    // Fetch all resolutions
    static func fetchResolutions(completed: @escaping ()->()) {
        print("IPTV.fetchResolutions()")
        guard let token = User.accessToken else {
            print("ERROR fetchResolutions() failed: no auth token")
            return
        }

        var request = URLRequest(url: URL(string: "\(API.getApiURL())/iptv/resolution")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            guard
                let rawdata = data
            else {
                print("ERROR fetchResolutions() : response data is empty")
                return
            }
            let decoder = JSONDecoder()
            if let response = try? decoder.decode(ResolutionsResponse.self, from: rawdata) {
                if (response.success) {
                    self.resolutions = response.resolutions
                    print("Resolutions \(self.resolutions!)")
                    DispatchQueue.main.async {
                        completed()
                    }
                } else {
                    print("ERROR fetchResolutions(): failed to retreive sources")
                }
            } else {
                print("ERROR fetchResolutions(): failed to deserialize response")
            }
        }).resume()
    }
    
    /*
    *    Set resolution from ID
    */
    static func setResolution(id: Int, completed: @escaping ()->()) {
        print("IPTV.setResolution()")
        guard let token = User.accessToken else {
            print("ERROR setResolution() failed: no auth token")
            return
        }
        let query = ["id": id]
        var request = URLRequest(url: URL(string: "\(API.getApiURL())/iptv/resolution")!)
        request.httpMethod = "PUT"
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: query, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                guard
                    let rawdata = data
                else {
                    print("ERROR setResolution() : response data is empty")
                    return
                }
                let json = try JSONSerialization.jsonObject(with: rawdata) as? Dictionary<String, AnyObject>
                IPTV.current_resolution = json?["resolution"] as? Int
                DispatchQueue.main.async {
                    completed()
                }
            } catch {
                print("ERROR setResolution(): failed to deserialize response")
            }
            }).resume()
        } catch {
            print("ERROR setResolution(): failed to serialize")
        }
    }

    // Fetch all channels
    static func fetchChannels(completed: @escaping ()->()) {
        print("IPTV.fetchChannels()")
        guard let token = User.accessToken else {
            print("ERROR fetchChannels() failed: no auth token")
            return
        }

        var request = URLRequest(url: URL(string: "\(API.getApiURL())/iptv/channel")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            guard
                let rawdata = data
            else {
                print("ERROR fetchChannels() : response data is empty")
                return
            }
            let decoder = JSONDecoder()
            if let response = try? decoder.decode(ChannelsResponse.self, from: rawdata) {
                if (response.success) {
                    self.channels = response.channels
                    //print("Channels \(self.channels!)")
                    
                    for (channelId, categories) in response.channels {
                        print("Categories for channel \(channelId):")
                        for categoryName in categories.keys {
                            
                            for childChannel in categories.values{
                                childChannel.forEach({debugPrint("LNG: \($0.lang)")})
                                                            let newCustomChannelObject = CustomChannel(channel: childChannel, parent_channel_id: channelId, category_Name: categoryName)
                                customChannelsList?.append(newCustomChannelObject)
                            }
                            print(categoryName)

                        }
                        
                    }
                    debugPrint("customChannelsList?.count \(customChannelsList?.count)")

                    
                    
                    DispatchQueue.main.async {
                        completed()
                    }
                } else {
                    print("ERROR fetchChannels(): failed to retreive sources")
                }
            } else {
                print("ERROR fetchChannels(): failed to deserialize response")
            }
        }).resume()
    }

    /*
    *    Set channel from ID
    */
    static func setChannel(id: Int, completed: @escaping ()->()) {
        print("IPTV.setChannel()")
        guard let token = User.accessToken else {
            print("ERROR setChannel() failed: no auth token")
            return
        }
        let query = ["id": id]
        var request = URLRequest(url: URL(string: "\(API.getApiURL())/iptv/channel")!)
        request.httpMethod = "PUT"
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: query, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
                DispatchQueue.main.async {
                    completed()
                }
            }).resume()
        } catch {
            print("ERROR setChannel(): failed to serialize")
        }
    }

    /*
    *     Cast Stop Method call
    */
    static func castStop(completed: @escaping ()->()) {
        print("IPTV.castStop()")

        guard let token = User.accessToken else {
            print("ERROR castStop() failed: no auth token")
            return
        }
        var request = URLRequest(url: URL(string: "\(API.getApiURL())/iptv/chromecast/stop")!)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            print("SET CAST STOP COMPLETE")
            DispatchQueue.main.async {
                completed()
            }
        }).resume()
    }

    /*
    *     Cast Stop Method call
    */
    static func castPause(completed: @escaping ()->()) {
        print("IPTV.castPause()")

        guard let token = User.accessToken else {
            print("ERROR castPause() failed: no auth token")
            return
        }
        var request = URLRequest(url: URL(string: "\(API.getApiURL())/iptv/chromecast/playpause")!)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            print("SET CAST PAUSE COMPLETE")
            DispatchQueue.main.async {
                completed()
            }
        }).resume()
    }
}
