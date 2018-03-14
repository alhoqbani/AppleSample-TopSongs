//
//  AppDelegate.swift
//  AppleSample-TopSongs
//
//  Created by Hamoud Alhoqbani on 3/13/18.
//  Copyright © 2018 Hamoud Alhoqbani. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // Properties for the importer and its background processing queue.
    var importer: iTunesJSONImporter?

    // Properties for the Core Data stack.
    var managedObjectContext: NSManagedObjectContext?
    var persistentStoreCoordinator: NSPersistentStoreCoordinator?
    var persistentStorePath: URL? = {
        if let applicationSupportDirectory = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            print("applicationSupportDirectory exists")
            return applicationSupportDirectory.appendingPathComponent("TopSongs.sqlite")
        }
        return nil
    }()

    // The number of songs to be retrieved from the RSS feed.
    var importSize = 200
    lazy var iTunesURL: URL = {
        let urlString = "https://rss.itunes.apple.com/api/v1/us/itunes-music/top-songs/all/\(importSize)/explicit.json"

        return URL(string: urlString)!
    }()


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // Print documents directory to check the sqlite file
        print("Document Directory: \(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path)")

        // Reset The Database
//        resetDatabase()

        // create an importer object to retrieve, parse, and import into the CoreData store
        // pass the coordinator so the importer can create its own managed object context
        importer = iTunesJSONImporter(iTunesURL: iTunesURL, persistentStoreCoordinator: self.persistentContainer.persistentStoreCoordinator)
        importer?.delegate = self
        application.isNetworkActivityIndicatorVisible = true

        // TODO add the importer to an operation queue for background processing (works on a separate thread)

        // Inject SongsViewController managedObjectContext.
        // obtain our current initial view controller on the nav stack and set it's managed object context
        if let vc = window?.rootViewController as? UINavigationController, let songsViewController = vc.visibleViewController as? SongsViewController {
            songsViewController.managedObjectContext = self.persistentContainer.viewContext
        }

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
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "TopSongs")

        if let url = self.persistentStorePath {
            print("Changing persistentStorePath to \(url.path)")
            container.persistentStoreDescriptions.first?.url = url
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // remove the old store; easier than deleting every object
    // first, test for an existing store
    func resetDatabase() {

        do {
            if let url = self.persistentStorePath, FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
                print("Database file was deleted")
            } else {
                print("Could not find database file to delete")
            }
        } catch {
            print("Error Resetting the database: \(error)")
        }

    }

}

//: MARK: iTunesJSONImporterDelegate
extension AppDelegate: iTunesJSONImporterDelegate {
}

