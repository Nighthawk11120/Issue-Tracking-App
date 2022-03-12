////
////  TextViewWrapper.swift
////  IssueTracker
////
////  Created by Scott Bauer on 6/4/21.
////
//
//import SwiftUI
//
//struct TextViewWrapper: NSViewRepresentable {
//    let section: Section
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self, section: section)
//    }
//    
//    
//    func makeNSView(context: Context) -> NSScrollView {
//
//        let nsView = NSTextView()
//
//        nsView.isRichText = true
//        nsView.isEditable = true
//        nsView.isSelectable = true
//        nsView.allowsUndo = true
//
//        nsView.usesInspectorBar = true
//
//        nsView.usesFindPanel = true
//        nsView.usesFindBar = true
//
//        nsView.isGrammarCheckingEnabled = true
//        nsView.isContinuousSpellCheckingEnabled = true
//
//        nsView.usesRuler = true
//
//        nsView.textStorage?.setAttributedString(section.sectionFormattedText)
//        nsView.delegate = context.coordinator
////        nsView.textStorage?.delegate = context.coordinator
//        
//        nsView.autoresizingMask = [.width]
//        nsView.translatesAutoresizingMaskIntoConstraints = true
//        nsView.isHorizontallyResizable = false
//        nsView.isVerticallyResizable   = true
//        nsView.isAutomaticLinkDetectionEnabled = true
//
//        let scroll = NSScrollView()
//        scroll.hasVerticalScroller = true
//        scroll.documentView = nsView
//        scroll.drawsBackground = false
//
//        return scroll
//
//    }
//    
//    func updateNSView(_ nsView: NSScrollView, context: Context) {
//        let text = nsView.documentView as? NSTextView
//        text?.textStorage?.setAttributedString(section.sectionFormattedText)
//        context.coordinator.section = section
//    }
//    
//    class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
//        var parent: TextViewWrapper
//        var section: Section
//        
//        init(_ parent: TextViewWrapper, section: Section) {
//            self.parent = parent
//            self.section = section
//        }
//        
//        
//        func textDidChange(_ notification: Notification) {
//            if let textView = notification.object as? NSTextView {
//                section.sectionFormattedText = textView.attributedString()
//                
////                // make text bold with # before it
////                do {
////                    let attributes = [NSAttributedString.Key.font : NSFont.systemFont(ofSize: 14.0)]
////                    let range = NSRange(location: 0, length: textView.string.count)
////                            textView.textStorage?.setAttributes(attributes, range: range)
////                    let regexString = "#(\\w*)"
////                    let regex = try NSRegularExpression(pattern: regexString, options: [])
////
////                    let matches = regex.matches(in: textView.string, options: [], range: NSRange(location: 0, length: textView.string.count))
////
////                    for match in matches {
////                        textView.textStorage?.setAttributes([NSAttributedString.Key.font : NSFont.boldSystemFont(ofSize: 14.0)], range: match.range)
////                    }
////                    
////                    let regexString2 = "(\\``\\w+(\\s\\w+)*\\)"//"(\\```\\w+(\\s\\w+)*\\```)"
////                    let regex2 = try NSRegularExpression(pattern: regexString2, options: [])
////                    let matches2 = regex2.matches(in: textView.string, options: [], range: NSRange(location: 0, length: textView.string.count))
////                    
////                    for match in matches2 {
////                        let paragraphStyle = NSParagraphStyle.default
////                        
////                        let mutableStyle = NSMutableParagraphStyle()
////                        mutableStyle.setParagraphStyle(paragraphStyle)
////                        mutableStyle.textBlocks = [CodeBlock()]
////                        
////                        textView.textStorage?.setAttributes([NSAttributedString.Key.backgroundColor : NSColor.gray], range: match.range)
//////                            .addAttribute(.paragraphStyle, value: mutableStyle, range: match.range)
//////                        textView.textStorage?.setAttributes([NSAttributedString.Key.font : NSFont.systemFont(ofSize: 14.0), .foregroundColor: NSColor.blue], range: match.range)
////                    }
////                    
////                } catch let error {
////                    print(error)
////                }
////                // end making text bold with #
//                
//                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                    PersistenceController.shared.save()
//                }
//            }
//        }
//        
//    }
//    class CustomTextStorage: NSTextStorage {
//        
//        override func replaceCharacters(in range: NSRange, with str: String) {
//            let codeBlockRange = NSRange("@(\\w*)")!
//            let paragraphStyle = NSParagraphStyle.default
//            
//            let mutableStyle = NSMutableParagraphStyle()
//            mutableStyle.setParagraphStyle(paragraphStyle)
//            mutableStyle.textBlocks = [CodeBlock()]
//            
//            addAttribute(.paragraphStyle, value: mutableStyle, range: codeBlockRange)
//        }
//    }
//    
//    class CodeBlock: NSTextBlock {
//        override init() {
//            super.init()
//            
//            setWidth(15.0, type: .absoluteValueType, for: .padding)
//            setWidth(45.0, type: .absoluteValueType, for: .padding, edge: .minY)
//            
//            backgroundColor = NSColor(white: 0.95, alpha: 1.0)
//        }
//        
//        required init?(coder: NSCoder) {
//            fatalError("init(coder:) has not been implemented")
//        }
//        
//        override func drawBackground(withFrame frameRect: NSRect, in controlView: NSView, characterRange charRange: NSRange, layoutManager: NSLayoutManager) {
//            let adjustedFrame: NSRect = CGRect(x: 1.0, y: 1.0, width: 10.0, height: 10.0)
//            super.drawBackground(withFrame: adjustedFrame, in: controlView, characterRange: charRange, layoutManager: layoutManager)
//            
//            let drawPoint: NSPoint = CGPoint(x: 2, y: 2)
//            let drawString = NSString(string: "Swift Code")
//            let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.blue]
//            drawString.draw(at: drawPoint, withAttributes: attributes)
//        }
//    }
//    
//    
//}
//
//
//
//
//
//struct TextViewWrapper_Previews: PreviewProvider {
//    static var previews: some View {
//        TextViewWrapper(section: Section.example)
//    }
//}
