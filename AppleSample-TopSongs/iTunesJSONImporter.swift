//
//  iTunesJSONImporter.swift
//  AppleSample-TopSongs
//
//  Created by Hamoud Alhoqbani on 3/13/18.
//  Copyright © 2018 Hamoud Alhoqbani. All rights reserved.
//

import Foundation
import CoreData

class iTunesJSONImporter: Operation {
    
    
    var iTunesURL: URL
    var persistentStoreCoordinator: NSPersistentStoreCoordinator
    var delegate: iTunesJSONImporterDelegate?
    var theCache: CategoryCache?
    var sessionTask: URLSessionTask?
    
    
    // CoreData managedContext to insert records
    lazy var insertionContext: NSManagedObjectContext = {
        let mangedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mangedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        return mangedObjectContext
    }()
    
    init(iTunesURL: URL, persistentStoreCoordinator: NSPersistentStoreCoordinator) {
        self.iTunesURL = iTunesURL
        self.persistentStoreCoordinator = persistentStoreCoordinator
    }
    
    override func main() {
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
                
                // Store the results in CoreData
                
                for (index, result) in json.feed.results.enumerated() {
                   
                    let song = Song(context: self.insertionContext)
                    
                    song.album = result.collectionName
                    song.artist = result.artistName
                    song.releaseDate = result.releaseDate
                    song.title = result.name
                    song.rank = (index + 1) as NSNumber
                    
                    // Category Assignemnt.
                    // In JSON version, it's called genre and a song can have more than one.
                    // We will take the first one and use as a category. Until we udpate the schema.
                    if let genreName = result.genres.first?.name {
                        
                        // Check if the category already exists
                        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "name == %@", genreName)
                        let categories = try self.insertionContext.fetch(fetchRequest)
                        
                        if let category = categories.first {
                            song.category = category
                        // We need to create new category
                        } else {
                            let category = Category(context: self.insertionContext)
                            category.name = genreName
                            // We save before assiging the cateogry to avoid dangling reference to an invalid object (Does not Work)
                            // But, do we need to fetch the category again?!!
                            try self.insertionContext.save()
                            song.category = try self.insertionContext.fetch(fetchRequest).first!
                        }
                    }
                    
                    do {
                        try self.insertionContext.save()
                        
                    } catch {
                        print(error)
                    }
                }
                
                
                
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
