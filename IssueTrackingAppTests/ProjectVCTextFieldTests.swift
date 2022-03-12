//
//  ProjectVCTextFieldTests.swift
//  IssueTrackingAppTests
//
//  Created by Scott Bauer on 10/21/21.
//

import XCTest
import CoreData
@testable import IssueTrackingApp

class ProjectVCTextFieldTests: XCTestCase {
    private var projectViewController: ProjectViewController!

    override func setUp() {
        super.setUp()
        let storageProvider = StorageProvider(inMemory: true)
        projectViewController = ProjectViewController(storageProvider: storageProvider)
        projectViewController.loadViewIfNeeded()
    }

    override func tearDown() {
        projectViewController = nil
        super.tearDown()
    }
    
    func test_textFieldDelegates_shouldBeConnected() {
        XCTAssertNotNil(projectViewController.projectEditTextField.delegate, "projectTextField")
    }

    func test_projectTextField_isRemovedFromSuperviewOnReturn() {
        putInViewHierarchy(projectViewController)

        XCTAssertEqual(projectViewController.projectEditTextField.superview, nil)
    }
}








