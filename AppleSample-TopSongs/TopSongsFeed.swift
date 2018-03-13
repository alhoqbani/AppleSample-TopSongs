//
//  TopSongsFeed.swift
//  AppleSample-TopSongs
//
//  Created by Hamoud Alhoqbani on 3/13/18.
//  Copyright © 2018 Hamoud Alhoqbani. All rights reserved.
//

import Foundation


struct TopSongsFeed: Decodable {
    var feed: Feed
    
    struct Feed: Decodable {
        var results: [Result]
    }
    
    struct Result: Decodable {
        
        var artistName: String
        var id: String
        var releaseDate: Date
        var name: String
        var collectionName: String
        var kind: String
        var copyright: String
        var artistId: String
        var artistUrl: String
        var artworkUrl100: String
        
        var genres: [Genre]

        struct Genre: Decodable {
            var genreId: String
            var name: String
            var url: String
        }
    }
}
