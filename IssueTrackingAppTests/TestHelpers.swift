//
//  TestHelpers.swift
//  IssueTrackingAppTests
//
//  Created by Scott Bauer on 10/21/21.
//

import XCTest
import UIKit

func putInViewHierarchy(_ vc: UIViewController) {
    let window = UIWindow()
    window.addSubview(vc.view)
}

