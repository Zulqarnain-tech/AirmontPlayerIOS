//
//  DNS.swift
//  Airmont Player
//
//  Created by François Goudal on 11/10/2021.
//  Copyright © 2021 Airmont. All rights reserved.
//

import Foundation

class DNS{
    enum QTYPE: Int {
        case None = 0,
             A = 1,
             NS = 2,
             MD = 3,
             MF = 4,
             CNAME = 5,
             SOA = 6,
             MB = 7,
             MG = 8,
             MR = 9,
             NULL = 10,
             WKS = 11,
             PTR = 12,
             HINFO = 13,
             MINFO = 14,
             MX = 15,
             TXT = 16,
             AXFR = 252,
             MAILB = 253,
             MAILA = 254,
             ALL = 255
    }
    
    static func getQuestionName(buf: Data, start: Int) -> String {
        var res = ""
        var pos = start
        while (buf[pos] != 0) {
            if (buf[pos] & 0b11000000 == 0) {
                //This is a label
                let size = Int(buf[pos])
                let label = String(decoding: buf.subdata(in: (pos + 1)..<(pos + 1 + size)), as: UTF8.self)
                if (res == "") {
                    res = label
                } else {
                    res += "." + label
                }
                pos += 1 + size
            } else {
                //This is a pointer
                pos = Int(buf[pos + 1])//FIXME: MSB of pointer
            }
        }
        return res
    }
    
    static func getQuestionType(buf: Data, start: Int) -> QTYPE {
        var pos = start
        while (buf[pos] != 0 && (buf[pos] & 0b11000000) == 0) {
            pos += 1 + Int(buf[pos])
        }
        if (buf[pos] & 0b11000000 == 0) {
            return QTYPE(rawValue: Int(buf[pos + 2])) ?? QTYPE.None //FIXME: MSB of type
        } else {
            return QTYPE(rawValue: Int(buf[pos + 3])) ?? QTYPE.None //FIXME: MSB of type
        }
    }
    
    static func getQuestionNext(buf: Data, start: Int) -> Int {
        var pos = start
        while (buf[pos] != 0 && (buf[pos] & 0b11000000) == 0) {
            pos += 1 + Int(buf[pos])
        }
        if (buf[pos] & 0b11000000 == 0) {
            //Skip null byte, type and class
            return pos + 1 + 2 + 2
        } else {
            //Skip pointer, type and class
            return pos + 2 + 2 + 2
        }
    }
}
