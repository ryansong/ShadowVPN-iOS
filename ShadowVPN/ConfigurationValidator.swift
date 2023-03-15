//
//  ConfigurationValidator.swift
//  ShadowVPN
//
//  Created by clowwindy on 8/10/15.
//  Copyright © 2015 clowwindy. All rights reserved.
//

import UIKit

class ConfigurationValidator: NSObject {
    
    // return nil if there's no error
    class func validateIP(ip: String) -> String?
    {
        let parts = ip.components(separatedBy: ".")
        if parts.count != 4 {
            return "Invalid IP: " + ip
        }
        for part in parts
        {
            if let n = Int(part)
            {
                if n < 0 || n > 255
                {
                    return "Invalid IP: " + ip
                }
            }
        }
        return nil
    }
    
    // return nil if there's no error
    class func validate(configuration: [String: Any]) -> String?
    {
        // 1. server must be not empty
        guard configuration["server"] != nil else
        {
            return "Server must not be empty"
        }
        
        if let server = configuration["server"] as? String, server.lengthOfBytes(using: .utf8) == 0
        {
            return "Server must not be empty"
        }
         
        // 2. port must be int 1, 65535
        guard configuration["port"] != nil else
        {
            return "Port must not be empty"
        }
        
        if let port = Int(configuration["port"] as! String)
        {
            if port < 1 || port > 65535 {
                return "Port is invalid"
            }
        }
        
        // 3. password must be not empty
        guard configuration["password"] != nil else
        {
            return "Password must not be empty"
        }
        
        if let password = configuration["password"] as? String, password.lengthOfBytes(using: .utf8) == 0
        {
            return "Password must not be empty"
        }
        
        // 4. usertoken must be empty or hex of 8 bytes
        guard configuration["usertoken"] != nil else
        {
            return "Usertoken must not be empty"
        }
        
        if let usertoken = configuration["usertoken"] as? String, NSData.fromHexString(string: usertoken).length != 8,  NSData.fromHexString(string: usertoken).length != 0
        {
            return "Usertoken must be HEX of 8 bytes (example: 7e335d67f1dc2c01)"
        }
        
        // 5. ip must be valid IP
        guard configuration["ip"] != nil else
        {
            return "IP must not be empty"
        }
        
        
        if let ip = configuration["ip"] as? String
        {
            if ip.lengthOfBytes(using: .utf8) == 0
            {
                return "IP must not be empty"
            }
            
           if let r = validateIP(ip: ip)
            {
               return r;
           }
        }
        
        // 6. subnet must be valid subnet
        guard configuration["subnet"] != nil else
        {
            return "Subnet must not be empty"
        }
        
        
        if let subnet = configuration["subnet"] as? String
        {
            if subnet.lengthOfBytes(using: .utf8) == 0
            {
                return "Subnet must not be empty"
            }
            
           if let r = validateIP(ip: subnet)
            {
               return r;
           }
        }

        // 7. dns must be comma separated ip addresses
        guard configuration["dns"] != nil else
        {
            return "DNS must not be empty"
        }
        
        if let dns = configuration["dns"] as? String
        {
            if dns.lengthOfBytes(using: .utf8) == 0
            {
                return "DNS must not be empty"
            }
            
            let ips = dns.components(separatedBy:",")
            if ips.count == 0 {
                return "DNS must not be empty"
            }
            for ip in ips {
                let r = validateIP(ip: ip)
                if r != nil {
                    return r
                }
            }
        }
        
        // 8. mtu must be int
        guard configuration["mtu"] != nil else
        {
            return "MTU must not be empty"
        }
        
        if let mtu = configuration["mtu"] as? String
        {
            if mtu.lengthOfBytes(using: .utf8) == 0
            {
                return "MTU must not be empty"
            }
            
            let mtu = Int(configuration["mtu"] as! String)
            if mtu ?? 0 < 100 || mtu ?? 0 > 9000 {
                return "MTU is invalid"
            }
        }
        
        // 9. routes must be empty or chnroutes
        return nil
    }
}
