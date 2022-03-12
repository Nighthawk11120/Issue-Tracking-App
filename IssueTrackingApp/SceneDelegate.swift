//
//  SceneDelegate.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 6/11/21.
//

import UIKit
import SwiftUI
import CloudKit

enum UIUserInterfaceIdiom: Int {
    case unspecified
    
    case phone
    case pad
}

class TestViewController: UIViewController {
    override func viewDidLoad() {
        view.backgroundColor = .orange
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
                let appDelegate = UIApplication.shared.delegate as? AppDelegate

        
        let navController = UINavigationController(rootViewController: ProjectViewController(storageProvider: appDelegate!.coreDataStack))
        navController.navigationBar.prefersLargeTitles = true
        
        let detailHostingController = UIHostingController(rootView: EmptyTaskDetailView())
        
        let detailController = UINavigationController(rootViewController: detailHostingController)
       
        if UIDevice.current.userInterfaceIdiom == .phone  {
            let splitViewController = UISplitViewController(style: .doubleColumn)
            splitViewController.viewControllers = [navController, detailController]
            splitViewController.primaryBackgroundStyle = .sidebar
            splitViewController.preferredDisplayMode = .twoBesideSecondary
            splitViewController.modalPresentationStyle = .overFullScreen
            
            window = UIWindow(frame: windowScene.coordinateSpace.bounds)
            window?.windowScene = windowScene
            window?.rootViewController = splitViewController
            window?.makeKeyAndVisible()
        } else {
            let splitViewController = UISplitViewController(style: .doubleColumn)
            splitViewController.preferredDisplayMode = .twoBesideSecondary
            splitViewController.modalPresentationStyle = .overFullScreen
            splitViewController.viewControllers = [navController, detailController]
            splitViewController.primaryBackgroundStyle = .sidebar
            splitViewController.showsSecondaryOnlyButton = true
            
            window = UIWindow(frame: windowScene.coordinateSpace.bounds)
            window?.windowScene = windowScene
            window?.rootViewController = splitViewController //navController
            window?.makeKeyAndVisible()
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        
        AppDelegate.sharedAppDelegate.coreDataStack.saveContext()
    }
}

