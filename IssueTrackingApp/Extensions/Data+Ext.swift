//
//  Data+Ext.swift
//  IssueTracker
//
//  Created by Scott Bauer on 6/4/21.
//

import Foundation

extension Data {
    
    func toAttributedString() -> NSAttributedString {
        let options: [NSAttributedString.DocumentReadingOptionKey : Any] = [.documentType: NSAttributedString.DocumentType.rtfd, .characterEncoding: String.Encoding.utf8]
        
        let result = try? NSAttributedString(data: self, options: options, documentAttributes: nil)
        
        return result ?? NSAttributedString(string: "")
    }
}

extension NSAttributedString {
    
    func toData() -> Data? {
        let options: [NSAttributedString.DocumentAttributeKey : Any] = [.documentType: NSAttributedString.DocumentType.rtfd, .characterEncoding: String.Encoding.utf8]
        
        let range = NSRange(location: 0, length: length)
        let result = try? data(from: range, documentAttributes: options)

        return result
    }
}
