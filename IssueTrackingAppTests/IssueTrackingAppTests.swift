//
//  IssueTrackingAppTests.swift
//  IssueTrackingAppTests
//
//  Created by Scott Bauer on 6/11/21.
//

import XCTest
@testable import IssueTrackingApp

class IssueTrackingAppTests: XCTestCase {
    
    func testCollectionViewDataSourceExists() {
        let sut = ProjectViewController(storageProvider: StorageProvider(inMemory: true))
        
        sut.loadViewIfNeeded()
        
        XCTAssertNotNil(sut.collectionView.dataSource)
    }
    
    func testCollectionViewExists() {
        let sut = ProjectViewController(storageProvider: StorageProvider(inMemory: true))
        
        sut.loadViewIfNeeded()
        
        XCTAssertNotNil(sut.collectionView)
    }

}



