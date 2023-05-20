//
//  APError.swift
//  Airmont Player
//
//  Created by François Goudal on 15/02/2021.
//  Copyright © 2021 Airmont. All rights reserved.
//

import Foundation

enum APError: String, Error {
    case generalError   = "Error"
    case authFailed     = "Authentication failed"
}
