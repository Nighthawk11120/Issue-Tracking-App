//
//  SharingSupport.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 11/8/21.
//

import UIKit

// MARK: Sharing Support
//extension ProjectViewController {
//    
//    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
//        fatalError("Failed to save share \(error)")
//    }
//    
//    func itemTitle(for csc: UICloudSharingController) -> String? {
//        guard let title = project?.title else {
//            return ""
//        }
//
//        return title
//    }
//    
//    class func string(for permission: CKShare.ParticipantPermission) -> String {
//        switch permission {
//        case .unknown:
//            return "Unknown"
//        case .none:
//            return "None"
//        case .readOnly:
//            return "Read-Only"
//        case .readWrite:
//            return "Read-Write"
//        @unknown default:
//            fatalError("It looks like a new value was added to CKShare.Participant.Permission")
//        }
//    }
//    
//    class func string(for role: CKShare.ParticipantRole) -> String {
//        switch role {
//        case .owner:
//            return "Owner"
//        case .privateUser:
//            return "Private User"
//        case .publicUser:
//            return "Public User"
//        case .unknown:
//            return "Unknown"
//        @unknown default:
//            fatalError("It looks like a new value was added to CKShare.Participant.Role")
//        }
//    }
//    
//    class func string(for acceptanceStatus: CKShare.ParticipantAcceptanceStatus) -> String {
//        switch acceptanceStatus {
//        case .accepted:
//            return "Accepted"
//        case .removed:
//            return "Removed"
//        case .pending:
//            return "Invited"
//        case .unknown:
//            return "Unknown"
//        @unknown default:
//            fatalError("It looks like a new value was added to CKShare.Participant.AcceptanceStatus")
//        }
//    }
//}
