//
//  LoadingSpinnerViewController.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 7/21/21.
//

import UIKit

class SpinnerViewController: UITableViewController {
    
    lazy var spinner: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .gray
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard spinner.superview == nil, let superView = tableView.superview else { return }
        
        superView.addSubview(spinner)
        superView.bringSubviewToFront(spinner)
        spinner.center = CGPoint(x: superView.frame.size.width / 2, y: superView.frame.size.height / 2)
    }
}

