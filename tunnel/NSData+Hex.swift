//
//  NSData+Hex.swift
//  ShadowVPN
//
//  Created by clowwindy on 8/9/15.
//  Copyright © 2015 clowwindy. All rights reserved.
//

import Foundation

extension NSData {
    public class func fromHexString (string: String) -> NSData {
        let data = NSMutableData()
        var temp = ""
        
        for char in string
        {
            temp += String(char)
            if temp.lengthOfBytes(using: .utf8) == 2
            {
                let scanner = Scanner(string: temp)
                var value: CUnsignedLongLong = 0
                scanner.scanHexInt64(&value)
                data.append(&value, length: 1)
                temp = ""
            }
        }        
        return data as NSData
    }
}
