////
////  BaseTestCase.swift
////  IssueTrackingAppTests
////
////  Created by Scott Bauer on 10/21/21.
////
//
//import XCTest
//import CoreData
//@testable import IssueTrackingApp
//
//class BaseTestCase: XCTestCase {
//    static let defaultTimeout = 10.0
//    private var _coreDataStack: StorageProvider?
//    var coreDataStack: StorageProvider {
//        return _coreDataStack!
//    }
//    
//    var dataController: StorageProvider!
//    var managedObjectContext: NSManagedObjectContext!
//
//    override func setUpWithError() throws {
//        continueAfterFailure = false
//        let appDelegate = AppDelegate.sharedAppDelegate
//        _coreDataStack = appDelegate.coreDataStack
//        
//        XCTAssertNotNil(coreDataStack.persistentContainer)
//        XCTAssertEqual(2, coreDataStack.persistentContainer.persistentStoreCoordinator.persistentStores.count)
//        _coreDataStack?.persistentContainer.viewContext.transactionAuthor = "\(type(of: self)).\(NSStringFromSelector(self.invocation!.selector))"
//    }
//    
//    override func tearDownWithError() throws {
//        let context = coreDataStack.persistentContainer.viewContext
//        let model = coreDataStack.persistentContainer.managedObjectModel
//        
//        context.performAndWait {
//            for entityName in model.entitiesByName.keys {
//                do {
//                    let request = NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: entityName))
//                    request.resultType = .resultTypeStatusOnly
//                    guard let deleteResult = try context.execute(request) as? NSBatchDeleteResult else {
//                        XCTFail("Unexpected result from batch delete for \(entityName)")
//                        return
//                    }
//                    
//                    guard let status = deleteResult.result as? NSNumber else {
//                        XCTFail("Expected an \(NSNumber.self) from batch delete for \(entityName)")
//                        return
//                    }
//                    XCTAssertTrue(status.boolValue)
//                } catch let error {
//                    XCTFail("Failed to batch delete data from test run for entity \(entityName): \(error)")
//                }
//            }
//            context.reset()
//        }
//        
//        try super.tearDownWithError()
//    }
//}
