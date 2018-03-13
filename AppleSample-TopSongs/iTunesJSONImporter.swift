//
//  iTunesJSONImporter.swift
//  AppleSample-TopSongs
//
//  Created by Hamoud Alhoqbani on 3/13/18.
//  Copyright © 2018 Hamoud Alhoqbani. All rights reserved.
//

import Foundation
import CoreData

class iTunesJSONImporter {
    
    
    var iTunesURL: URL
    var persistentStoreCoordinator: NSPersistentStoreCoordinator
    var delegat: iTunesJSONImporterDelegate?
    var theCache: CategoryCache?
    var sessionTask: URLSessionTask?
    
    init(iTunesURL: URL, persistentStoreCoordinator: NSPersistentStoreCoordinator) {
        self.iTunesURL = iTunesURL
        self.persistentStoreCoordinator = persistentStoreCoordinator
        fetchSongs()
    }
    
    private func fetchSongs() {
        sessionTask = URLSession.shared.dataTask(with: iTunesURL, completionHandler: { (data, response, error) in
            guard error == nil else {
                print(error!)
                return
            }
            
            guard let data = data else {
                print("no data")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-mm-dd"
                decoder.dateDecodingStrategy = .formatted(formatter)
                
                let json = try decoder.decode(TopSongsFeed.self, from: data)
                print(json.feed.results.count)
            } catch {
                print(error)
            }
        })
        
        sessionTask?.resume()
    }
    
}

//: MARK: iTunesJSONImporterDelegate
protocol iTunesJSONImporterDelegate {
    // Notification posted by NSManagedObjectContext when saved.
    func importDidSave(saveNotification: NSNotification) -> Void
    // Called by the importer when parsing is finished.
    func importDidFinishParsingData(importer: iTunesJSONImporter) -> Void
    // Called by the importer in the case of an error.
    func importer(importer: iTunesJSONImporter, didFailWithError: Error) -> Void
}

// Make all functions optional by providing default implementation.
extension iTunesJSONImporterDelegate {
    func importDidSave(saveNotification: NSNotification) -> Void {}
    func importDidFinishParsingData(importer: iTunesJSONImporter) -> Void {}
    func importer(importer: iTunesJSONImporter, didFailWithError: Error) -> Void {}
}
