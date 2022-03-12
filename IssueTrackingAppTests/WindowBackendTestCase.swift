////
////  WindowBackendTestCase.swift
////  IssueTrackingAppTests
////
////  Created by Scott Bauer on 10/21/21.
////
//
//import XCTest
//
//class WindowBackedTestCase: BaseTestCase {
//    private var _testWindow: UIWindow?
//    var testWindow: UIWindow {
//        return _testWindow!
//    }
//    
//    override func setUpWithError() throws {
//        try super.setUpWithError()
//        _testWindow = UIWindow(frame: UIScreen.main.bounds)
//        testWindow.makeKeyAndVisible()
//    }
//    
//    override func tearDownWithError() throws {
//        if let window = _testWindow {
//            window.rootViewController = nil
//        }
//        try super.tearDownWithError()
//    }
//}
