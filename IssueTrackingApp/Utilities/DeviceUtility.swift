////
////  DeviceUtility.swift
////  IssueTrackingApp
////
////  Created by Scott Bauer on 8/24/21.
////
//
//import Foundation
//import UIKit
//
//struct DeviceUtility {
//    
//    static var isMac : Bool {
//        #if targetEnvironment(macCatalyst)
//            return true
//        #else
////            _isMac = false
//            return false
//        #endif
//    }
//    
//    static var isIPad : Bool {
//        return self.platformType == .iPadOS
//    }
//    
//    static var isIPhone : Bool {
//        return self.platformType == .iOS
//    }
//    
//    static var platformType : PlatformType {
//        #if targetEnvironment(macCatalyst)
//            return .macCatalyst
//        #else
//        if UIDevice.current.userInterfaceIdiom == .pad {
//            return .iPadOS
//        } else if UIDevice.current.userInterfaceIdiom == .phone {
//            return .iOS
//        } else {
//            return .unsupported
//        }
//        #endif
//    }
//    
//    enum PlatformType {
//        case unsupported
//        case iPadOS
//        case iOS
//        case macCatalyst
//    }
//}
