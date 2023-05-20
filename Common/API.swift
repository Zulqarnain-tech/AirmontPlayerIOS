//
//  API.swift
//  Airmont Player tvOS
//
//  Created by François Goudal on 23/11/2020.
//  Copyright © 2020 Airmont. All rights reserved.
//

import Foundation

class API {
    static var api_ip:String? = "195.25.222.131:8888"//nil

    static func getApiURL() -> String {
        guard let api_address_preference = UserDefaults.standard.string(forKey: "api_address_preference") else {
            print("API \(api_ip ?? "airmont-gw.local")")
            return "http://\(api_ip ?? "airmont-gw.local")/api"
        }
        if (api_address_preference != "") {
            print("API \(api_address_preference)")
            return "http://\(api_address_preference)/api"
        }
        print("API \(api_ip ?? "airmont-gw.local")")
        return "http://\(api_ip ?? "airmont-gw.local")/api"
    }
}
