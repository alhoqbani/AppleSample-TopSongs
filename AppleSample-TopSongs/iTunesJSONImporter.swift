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

    // The number of parsed songs is tracked so that the autorelease pool for the parsing thread can be periodically
    // emptied to keep the memory footprint under control.
    var ImportBatchSize = 20
    var countForCurrentBatch = 0;

    var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-mm-dd"
        decoder.dateDecodingStrategy = .formatted(formatter)

        return decoder
    }()

    var session: URLSession?
    var sessionTask: URLSessionTask?


    // CoreData managedContext to insert records
    lazy var insertionContext: NSManagedObjectContext = {
        let mangedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        mangedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        return mangedObjectContext
    }()

    init(iTunesURL: URL, persistentStoreCoordinator: NSPersistentStoreCoordinator) {
        self.iTunesURL = iTunesURL
        self.persistentStoreCoordinator = persistentStoreCoordinator
    }

    override func main() {

        // If we have a delegate we add him as an observer to NSManagedObjectContextDidSave notification
        if let delegate = self.delegate {
            NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextDidSave,
                                                   object: self.insertionContext,
                                                   queue: OperationQueue.main,
                                                   using: delegate.importerDidSave)
        }


        // create the session with the request and start loading the data
        let sessionConfiguration = URLSessionConfiguration.default
        session = URLSession(configuration: sessionConfiguration,
                             delegate: self,
                             delegateQueue: nil // This IMPORTANT !! the core data was breaking b/c were/not on the main queue?
        )
        sessionTask = session?.dataTask(with: iTunesURL, completionHandler: { [weak self] (data: Data?, response: URLResponse?, error: Error?) -> Void in

            guard let strongSelf = self else {
                return
            }

            guard error == nil else {
                print(error!)
                return
            }

            guard let data = data else {
                print("no data")
                return
            }

            do {

                let json = try strongSelf.decoder.decode(TopSongsFeed.self, from: data)
                print(json.feed.results.count)
                // Store the results in CoreData

                // We need to chunk save the objects
                var songs = [Song]()
                for (index, result) in json.feed.results.enumerated() {

                    strongSelf.countForCurrentBatch += 1

                    let song = Song(context: strongSelf.insertionContext)

                    song.album = result.collectionName
                    song.artist = result.artistName
                    song.releaseDate = result.releaseDate
                    song.title = result.name
                    song.rank = (index + 1) as NSNumber

                    // Category Assignment.
                    // In JSON version, it's called genre and a song can have more than one.
                    // We will take the first one and use as a category. Until we udpate the schema.
                    if let genreName = result.genres.first?.name {

                        // Check if the category already exists
                        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "name == %@", genreName)
                        let categories = try strongSelf.insertionContext.fetch(fetchRequest)

                        if let category = categories.first {
                            song.category = category
                            // We need to create new category
                        } else {
                            let category = Category(context: strongSelf.insertionContext)
                            category.name = genreName
                            song.category = category
                        }
                    }

                    songs.append(song)

                    if strongSelf.countForCurrentBatch == strongSelf.ImportBatchSize {

                        strongSelf.insertionContext.performAndWait {
                            do {
                                try strongSelf.insertionContext.save()
                                // Release saved objects
                                songs = []
                                strongSelf.countForCurrentBatch = 0
                            } catch {
                                print(error)
                            }
                        }
                    }
                }
            } catch {
                print(error)
            }
            
            
//                do {
//                    try strongSelf.insertionContext.save()
//                } catch {
//                    print(error)
//                }

            

            // We remove our delegate from NSManagedObjectContextDidSave notification
            if let delegate = strongSelf.delegate {
                NotificationCenter.default.removeObserver(delegate,
                                                          name: Notification.Name.NSManagedObjectContextDidSave,
                                                          object: nil)
            }
            strongSelf.delegate?.importerDidFinishParsingData(importer: strongSelf)

        })

        sessionTask?.resume()
    }

}

//: MARK: URLSessionDelegate
extension iTunesJSONImporter: URLSessionDataDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print(data)

        print(Thread.current)

    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print(error)
    }
}

//: MARK: iTunesJSONImporterDelegate
protocol iTunesJSONImporterDelegate {
    // Notification posted by NSManagedObjectContext when saved.
    func importerDidSave(saveNotification: Notification) -> Void
    // Called by the importer when parsing is finished.
    func importerDidFinishParsingData(importer: iTunesJSONImporter) -> Void
    // Called by the importer in the case of an error.
    func importer(importer: iTunesJSONImporter, didFailWithError: Error) -> Void
}

// Make all functions optional by providing default implementation.
extension iTunesJSONImporterDelegate {
//    func importerDidSave(saveNotification: Notification) -> Void {}
//    func importerDidFinishParsingData(importer: iTunesJSONImporter) -> Void {}
//    func importer(importer: iTunesJSONImporter, didFailWithError: Error) -> Void {}
}
