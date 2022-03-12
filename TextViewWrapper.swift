//
//  TextViewWrapper.swift
//  IssueTracker
//
//  Created by Scott Bauer on 6/4/21.
//

import SwiftUI

struct TextViewWrapper: UIViewRepresentable {

    let section: ToDo
    let view = UITextView()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, section: section)
    }
    
    func makeUIView(context: Context) -> UITextView {
        view.allowsEditingTextAttributes = true
        view.isEditable = true
        view.isSelectable = true
        view.linkTextAttributes = [.foregroundColor: UIColor.systemBlue, .underlineStyle: NSUnderlineStyle.single.rawValue]
        view.dataDetectorTypes = .link
        view.isUserInteractionEnabled = true
        view.font = UIFont.systemFont(ofSize: 18)

        view.layer.cornerRadius = 10
        view.isScrollEnabled = true
        
        view.textStorage.setAttributedString(section.todoFormattedText)
        view.delegate = context.coordinator

        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.textStorage.setAttributedString(section.todoFormattedText)
        context.coordinator.section = section
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        
        var parent: TextViewWrapper
        var section: ToDo
        
        init(_ parent: TextViewWrapper, section: ToDo) {
            self.parent = parent
            self.section = section
        }
        
        func textViewDidChange(_ textView: UITextView) {
            section.todoFormattedText = textView.attributedText
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                AppDelegate.sharedAppDelegate.coreDataStack.saveContext()
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            textView.isEditable = false
            textView.dataDetectorTypes = .all
        }
    }
}
