//
//  StatusMenuHelper.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 11/8/21.
//

#if targetEnvironment(macCatalyst)
import SwiftUI
import ServiceManagement

class StatusMenuHelper: ObservableObject {
    
    private func setStatusMenuEnabled(_ isEnabled: Bool) -> Bool {
        let bundleId = "net.gobauer.ITStatusMenu" as CFString
        return SMLoginItemSetEnabled(bundleId, isEnabled)

    }
    
    @AppStorage("net.gobauer.StatusMenu.isEnabled")
    var isEnabled = false {
        didSet {
            if setStatusMenuEnabled(isEnabled) {
            } else {
                isEnabled = false
            }
            objectWillChange.send()
        }
    }
}
#endif
