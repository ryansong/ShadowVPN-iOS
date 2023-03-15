//
//  PacketTunnelProvider.swift
//  tunnel
//
//  Created by clowwindy on 7/18/15.
//  Copyright © 2015 clowwindy. All rights reserved.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    var session: NWUDPSession? = nil
    var conf = [String: Any]()
    var pendingStartCompletion: ((NSError?) -> Void)?
    var userToken: NSData?
    var chinaDNS: ChinaDNSRunner?
    var routeManager: RouteManager?
//    var wifi = ChinaDNSRunner.checkWiFiNetwork()
    
    var queue: DispatchQueue?
    
    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
//        queue = dispatch_queue_create("shadowvpn.queue", DISPATCH_QUEUE_SERIAL)
        queue = DispatchQueue(label: "shadowvpn.queue", attributes: .concurrent)
        
        conf = (self.protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration!
        self.pendingStartCompletion = completionHandler
         chinaDNS = ChinaDNSRunner(dns: conf["dns"] as? String)
        if let userTokenString = conf["usertoken"] as? String {
            if userTokenString.count == 16 {
                userToken = NSData.fromHexString(string: userTokenString)
            }
        }
        print("setPassword")
         SVCrypto.setPassword(conf["password"] as? String)
        self.recreateUDP()
        let keyPath = "defaultPath"
         let options = NSKeyValueObservingOptions([.new, .old])
        self.addObserver(self, forKeyPath: keyPath, options: options, context: nil)
        print("readPacketsFromTUN")
        self.readPacketsFromTUN()
    }
    
    func recreateUDP() {
        if self.session != nil {
            self.reasserting = true
            self.session = nil
        }
        queue!.async() { () -> Void in
            if let serverAddress = self.protocolConfiguration.serverAddress {
                if let port = self.conf["port"] as? String {
                    self.reasserting = false
                    self.setTunnelNetworkSettings(nil) { error in
                        if let error = error {
                            print("%@", error)
                            // simply kill the extension process since it does no harm and ShadowVPN is expected to be always on
//                            exit(1)
                        }
                        self.queue!.async() { () -> Void in
                            print("recreateUDP")
                            self.session = self.createUDPSession(to: NWHostEndpoint(hostname: serverAddress, port: port), from: nil)
                            self.updateNetwork()
                        }
                    }
                }
            }
        }
    }
    
    func updateNetwork() {
        print("updateNetwork")
        let newSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: self.protocolConfiguration.serverAddress!)
        newSettings.ipv4Settings = NEIPv4Settings(addresses: [conf["ip"] as! String], subnetMasks: [conf["subnet"] as! String])
        routeManager = RouteManager(route: conf["route"] as? String, IPv4Settings: newSettings.ipv4Settings!)
        if conf["mtu"] != nil {
            newSettings.mtu = Int(conf["mtu"] as! String) as NSNumber?
        } else {
            newSettings.mtu = 1432
        }
        if "chnroutes" == (conf["route"] as? String) {
            print("using ChinaDNS")
            newSettings.dnsSettings = NEDNSSettings(servers: ["127.0.0.1"])
        } else {
            print("using DNS")
            let rows = (conf["dns"] as! String).split(separator: ",")
            let realStrings = rows.map { subString -> String in
                return String(subString)
            }
            newSettings.dnsSettings = NEDNSSettings(servers: realStrings)
        }
        print("setTunnelNetworkSettings")
        self.setTunnelNetworkSettings(newSettings) { error in
            self.readPacketsFromUDP()
            print("readPacketsFromUDP")
            if let completionHandler = self.pendingStartCompletion {
                // send an packet
                //        self.log("completion")
                print("%@", error as Any )
                print("VPN started")
                completionHandler(error as NSError?)
                if error != nil {
                    // simply kill the extension process since it does no harm and ShadowVPN is expected to be always on
                    exit(1)
                }
            }
        }
    }
    
    func readPacketsFromTUN() {
        self.packetFlow.readPackets {
            packets, protocols in
            for packet in packets {
//                print("TUN: %d", packet.length)
                self.session?.writeDatagram(SVCrypto.encrypt(with: packet, userToken: self.userToken as Data?), completionHandler: { error in
                    if let error = error {
                        print("%@", error)
                    }
                })
            }
            self.readPacketsFromTUN()
        }
        
    }
    
    func readPacketsFromUDP() {
        session?.setReadHandler({ newPackets, error in
            guard let packets = newPackets else { return }
            var protocols = [NSNumber]()
            var decryptedPackets = [Data]()
            for packet in packets {
//                print("UDP: %d", packet.length)
                // currently IPv4 only
                let decrypted = SVCrypto.decrypt(with: packet, userToken: self.userToken as Data?)
//                print("write to TUN: %d", decrypted.length)
                decryptedPackets.append(decrypted ?? Data())
                protocols.append(2)
            }
            self.packetFlow.writePackets(decryptedPackets, withProtocols: protocols)
        }, maxDatagrams: NSIntegerMax)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let object = object {
            if object as! NSObject == self {
                if let keyPath = keyPath {
                    if keyPath == "defaultPath" {
                        // commented out since when switching from 4G to Wi-Fi, this will be called multiple times, only the last time works
//                        let wifi = ChinaDNSRunner.checkWiFiNetwork()
//                        if wifi != self.wifi {
                            print("Wi-Fi status changed")
//                            self.wifi = wifi
                            self.recreateUDP()
//                            return
//                        }

                    }
                }
            }
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Add code here to start the process of stopping the tunnel
        print("stopTunnelWithReason")
        session?.cancel()
        completionHandler()
        super.stopTunnel(with: reason, completionHandler: completionHandler)
        // simply kill the extension process since it does no harm and ShadowVPN is expected to be always on
        exit(0)
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        // Add code here to handle the message
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep
        completionHandler()
    }
    
    override func wake() {
        // Add code here to wake up
    }
}
