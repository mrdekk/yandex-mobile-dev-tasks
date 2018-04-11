//
//  AppDelegate.swift
//  notebook
//
//  Created by user on 07.03.18.
//  Copyright © 2018 user. All rights reserved.
//

import UIKit
import CocoaLumberjack

struct RGBAFloat {
    private var r: Float
    private var g: Float
    private var b: Float
    private var a: Float
    
    init(red: Float, green: Float, blue: Float, alpha: Float) {
        r = red
        g = green
        b = blue
        a = alpha
    }
    
    static let bitsPerComponent = 32
    static let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.floatComponents.rawValue
    static func bytesPerRow(width: Int) -> Int{
        return width * MemoryLayout<RGBAFloat>.size
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
        //DDLog.add(DDTTYLogger.sharedInstance) // TTY = Xcode console
        DDLog.add(DDASLLogger.sharedInstance) // ASL = Apple System Logs
        
        let fileLogger: DDFileLogger = DDFileLogger()
        fileLogger.rollingFrequency = TimeInterval(60*60*24)
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
        
        let dispatcher = OperationDispatcher()
        let asyncFileNotebook = FileNotebook()
        let noteOperationsFactory = NoteOperationsFactory(fileNotebook: asyncFileNotebook)
        let noteProvider = FileNotebookNoteProvider(
            noteOperationsFactory: noteOperationsFactory,
            operationsDispatcher: dispatcher)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let navigation = storyboard.instantiateInitialViewController() as? UINavigationController,
            let notesList = storyboard.instantiateViewController(
                withIdentifier: "NotesListViewController") as? NotesListViewController else {
            return false
        }
        
        notesList.notesProvider = noteProvider
        
        navigation.pushViewController(notesList, animated: false)
        window = UIWindow()
        window?.rootViewController = navigation
        window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

