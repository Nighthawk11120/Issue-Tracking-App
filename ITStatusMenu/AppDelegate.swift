//
//  AppDelegate.swift
//  ITStatusMenu
//
//  Created by Scott Bauer on 9/8/21.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem : NSStatusItem!
    var popover : NSPopover!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let statusButton = statusItem?.button {
            statusButton.image = NSImage(systemSymbolName: "tornado", accessibilityDescription: nil)
            statusButton.action = #selector(togglePopover(sender:))
            statusButton.target = self
        }
        
        // Create the popover
        popover = NSPopover()
        let storageProvider = StorageProvider.shared

        let content = NSHostingController(rootView: ContentView()
                                                      .environment(\.managedObjectContext, storageProvider.managedContext)
        )
        popover.contentViewController = content
        popover.contentSize = content.view.intrinsicContentSize
        popover.behavior = .transient
        popover.animates = false
    }
    
    @objc func togglePopover(sender: Any?) {
        guard let statusButton = statusItem.button else { return }
        
        if let popover = popover, popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: statusButton.bounds,
                         of: statusButton,
                         preferredEdge: NSRectEdge.maxY)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
}

