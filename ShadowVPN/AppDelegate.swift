//
//  AppDelegate.swift
//  ShadowVPN
//
//  Created by clowwindy on 7/18/15.
//  Copyright © 2015 clowwindy. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool
    {
        self.window = UIWindow.init(frame: UIScreen.main.bounds)
        if let window = self.window
        {
            let viewController = UINavigationController(rootViewController: MainViewController(style: .grouped))
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            
        }
        
        return true
    }
}

