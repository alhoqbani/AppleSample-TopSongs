//
//  SongDetailsViewController.swift
//  AppleSample-TopSongs
//
//  Created by Hamoud Alhoqbani on 3/13/18.
//  Copyright © 2018 Hamoud Alhoqbani. All rights reserved.
//

import UIKit

class SongDetailsViewController: UITableViewController {

    var song: Song? {
        didSet {
            tableView.reloadData()
        }
    }
    
    var dateFormatter: DateFormatter = {
       
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        
        return dateFormatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    //: MARK: - TableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongDetailCell", for: indexPath)
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "song:"
            cell.detailTextLabel?.text = song?.title
        case 1:
            cell.textLabel?.text = "artist:"
            cell.detailTextLabel?.text = song?.artist
        case 2:
            cell.textLabel?.text = "category:"
            cell.detailTextLabel?.text = song?.category?.name
        case 3:
            cell.textLabel?.text = "released:"
            cell.detailTextLabel?.text = dateFormatter.string(from: (song?.releaseDate)!)
        default:
            break
        }
        
        return cell
    }

}
