//
//  AppDelegate.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 6/11/21.
//

import UIKit
import CoreData
import CloudKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    lazy var coreDataStack: StorageProvider = { return StorageProvider.shared }()
    
    static let sharedAppDelegate: AppDelegate = {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Unexpected app delegate type, did it change? \(String(describing: UIApplication.shared.delegate))")
        }
        return delegate
    }()
    
    static var sectionToOpenInNewWindow: HeaderSection? = nil
    
    lazy var allowCloudKitSync: Bool = {
        let arguments = ProcessInfo.processInfo.arguments
        var allow = true
        for index in 0..<arguments.count - 1 where arguments[index] == "-CDCKDAllowCloudKitSync" {
            allow = arguments.count >= (index + 1) ? arguments[index + 1] == "1" : true
            break
        }
        return allow
    }()
    
    lazy var testingEnabled: Bool = {
        let arguments = ProcessInfo.processInfo.arguments
        var enabled = false
        for index in 0..<arguments.count - 1 where arguments[index] == "-CDCKDTesting" {
            enabled = arguments.count >= (index + 1) ? arguments[index + 1] == "1" : false
            break
        }
        return enabled
    }()
    
    lazy var catalystAppView = {
        CatalystAppView()
    }()
}


