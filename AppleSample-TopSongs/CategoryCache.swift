//
//  CategoryCache.swift
//  AppleSample-TopSongs
//
//  Created by Hamoud Alhoqbani on 3/13/18.
//  Copyright © 2018 Hamoud Alhoqbani. All rights reserved.
//

import Foundation
import CoreData

/*
 About the LRU implementation in this class:
    There are many different ways to implement an LRU cache. This class takes a very minimal approach using
    an integer "access counter". This counter is incremented each time an item is retrieved from the cache,
    and the item retrieved has a counter that is set to match the counter for the cache as a whole. This is
    similar to using a timestamp - the access counter for a given cache node indicates at what point it was
    last used. The counter does not reflect the number of times the node has been used.

    With the access counter, it is easy to iterate over the items in the cache and find the item with the
    lowest access value. This item is the "least recently used" item.
 */

class CategoryCache {

    var managedObjectContext: NSManagedObjectContext

    var categoryName = "NAME"
    var categoryNamePredicateTemplate: NSPredicate = {
        var leftHand = NSExpression(forKeyPath: "name")
        var rightHand = NSExpression(forVariable: "categoryName")
        var categoryNamePredicateTemplate = NSComparisonPredicate(leftExpression: leftHand,
                                                                  rightExpression: rightHand,
                                                                  modifier: .direct,
                                                                  type: .like,
                                                                  options: [])
        return categoryNamePredicateTemplate
    }()

    // Number of objects that can be cached
    var cacheSize: Int = 15

    // A dictionary holds the actual cached items
    var cache: [String: CacheNode] = [:]

    // Counter used to determine the least recently touched item.
    var accessCounter: Int = 0

    // Some basic metrics are tracked to help determine the optimal cache size for the problem.
    var totalCacheHitCost: Double = 0
    var totalCacheMissCost: Double = 0
    var cacheHitCount: Int = 0
    var cacheMissCount: Int = 0
    
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        
        // When a managed object is first created, it has a temporary managed object ID.
        // When the managed object context in which it was created is saved, the temporary ID is replaced with a permanent ID.
        // The temporary IDs can no longer be used to retrieve valid managed objects.
        // The cache handles the save notification by iterating through its cache nodes and removing any nodes with temporary IDs.
        // While it is possible force Core Data to provide a permanent ID before an object is saved, using the method -[ NSManagedObjectContext obtainPermanentIDsForObjects:error:], this method incurrs a trip to the database, resulting in degraded performance - the very thing we are trying to avoid.
        NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextDidSave, object: nil, queue: nil) { [weak self] (notification) in
//            print("** CategoryCache: managedObjectContext did save, we clear the cache")
            // Just remove any object with TemporaryID
            let objectsWithPermanentId = self?.cache.filter {
                !$0.value.objectID.isTemporaryID
            }
            
            self?.cache = objectsWithPermanentId!

        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        print("average cache hit cost: \(self.totalCacheHitCost / Double(self.cacheHitCount))")
        print("average cache miss cost: \(self.totalCacheMissCost / Double(self.cacheMissCount))")
    }

    func categoryWithName(_ name: String) -> Category? {

        // To calculate times
        let before = Date().timeIntervalSince1970

        // Check cache.
        if var cacheNode = cache[name] {
            // We have the object in the cache, increase its access counter and return it.

            // Cache hit, update access counter.
            cacheNode.accessCounter += 1
            
            // We fetch the object from the mangedObject context by its objectID
            let category = managedObjectContext.object(with: cacheNode.objectID) as? Category

            totalCacheHitCost = Date().timeIntervalSince1970 - before
            cacheHitCount += 1
            
            return category
        }

        // Cache missed, fetch from store -
        // if not found in store there is no category object for the name and we must create one.
        var category: Category
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        let predicate = categoryNamePredicateTemplate.withSubstitutionVariables(["categoryName" : name])
        fetchRequest.predicate = predicate
         let fetchResults = try? managedObjectContext.fetch(fetchRequest)
        
        if let resutls = fetchResults, resutls.count > 0 {
            // We found the category in the store
            // Get category from fetch.
            category = resutls.first!

        } else {
            // Category not in store, must create a new category object.
            category = Category(context: managedObjectContext)
            category.name = name
        }
        
        
        // Add to cache.
        // First check to see if cache is full.
        if cache.count > cacheSize {
            // Evict least recently used (LRU) item from cache.
            let leastUsed = cache.min { (first, second) in
                first.value.accessCounter < second.value.accessCounter
            }
            
            cache.removeValue(forKey: (leastUsed?.key)!)
        } else {
            // Create a new cache node.
            cache[name] = CacheNode(objectID: category.objectID, accessCounter: 1)
        }
        
        
        totalCacheMissCost = Date().timeIntervalSince1970 - before
        cacheMissCount += 1
        
        return category
    }


}

// CacheNode is a simple object to help with tracking cached items
struct CacheNode: Hashable {

    var objectID: NSManagedObjectID
    var accessCounter: Int
    var hashValue: Int {
        return objectID.hashValue
    }

    static func ==(lhs: CacheNode, rhs: CacheNode) -> Bool {
        return lhs.objectID == rhs.objectID
    }

}
