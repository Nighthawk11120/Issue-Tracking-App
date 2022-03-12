////
////  TestApplicationConfiguration.swift
////  IssueTrackingAppTests
////
////  Created by Scott Bauer on 10/21/21.
////
//
//import XCTest
//@testable import IssueTrackingApp
//
//class TestApplicationConfiguration: WindowBackedTestCase {
//    func testCoreDataStackObeysLaunchArguments() {
//        let appDelegate = AppDelegate.sharedAppDelegate
//        XCTAssertTrue(appDelegate.testingEnabled, "Should have launched with testing enabled so the test cases don't use the customer store.")
//        XCTAssertFalse(appDelegate.allowCloudKitSync, "Should have launched with CloudKit disabled so cloud sync doesn't impact the test dataset.")
//        let container = appDelegate.coreDataStack.persistentContainer
//        for storeDescription in container.persistentStoreDescriptions {
//            XCTAssertNil(storeDescription.cloudKitContainerOptions, "Shouldn't be using CloudKit during unit / UI tests.")
//        }
//    }
//}
