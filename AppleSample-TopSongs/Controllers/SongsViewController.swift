//
//  SongsViewController.swift
//  AppleSample-TopSongs
//
//  Created by Hamoud Alhoqbani on 3/13/18.
//  Copyright © 2018 Hamoud Alhoqbani. All rights reserved.
//

import UIKit
import CoreData

class SongsViewController: UIViewController {


    //: MARK: - Properties
    var managedObjectContext: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController<Song>!

    @IBOutlet weak var fetchSectioningControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Start fetching songs from our data store.
        fetch()
    }

    private func fetch() {

        // We start with a nil frc, and we need to reset it when changeFetchSectioning set it to nil
        if fetchedResultsController == nil {
            let fetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
            // We sort by rank always
            var sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(keyPath: \Song.rank, ascending: true)]
            // Helper to decide if we have sections whe sort by category
            var sectionNameKeyPath: String?
            // We want sections by category
            if fetchSectioningControl.selectedSegmentIndex == 1 {
                sortDescriptors.append(NSSortDescriptor(keyPath: \Song.category?.name, ascending: true))
                sectionNameKeyPath = "category.name"
            }

            fetchRequest.sortDescriptors = sortDescriptors
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: managedObjectContext,
                                                                  sectionNameKeyPath: sectionNameKeyPath,
                                                                  cacheName: nil)
        }

        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            print(error)
        }
    }

    @IBAction func changeFetchSectioning(_ sender: UISegmentedControl) {
        // To reset the fetchedResultsController based on selected segment
        fetchedResultsController = nil
        fetch()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "SongDetails",
           let songDetailsViewController = segue.destination as? SongDetailsViewController,
           let indexPath = self.tableView.indexPathForSelectedRow {
            songDetailsViewController.song = fetchedResultsController.object(at: indexPath)
        }
    }

}

//: MARK: Table DataSource
extension SongsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo = fetchedResultsController?.sections?[section] {
            return sectionInfo.numberOfObjects
        }

        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath)

        if let song = fetchedResultsController?.object(at: indexPath) {

            cell.textLabel?.text = "#\(song.rank?.intValue ?? 0) \(song.title ?? "No Name")"
        }


        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        guard let frc = fetchedResultsController, let sectionInfo = frc.sections?[section] else {
            return nil
        }

        if fetchSectioningControl.selectedSegmentIndex == 0 {
            return "Top \(sectionInfo.numberOfObjects) songs"
        } else {
            return "\(sectionInfo.name) - \(sectionInfo.numberOfObjects) songs"
        }
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {

        return fetchedResultsController?.sectionIndexTitles
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {

        return fetchedResultsController!.section(forSectionIndexTitle: title, at: index)
    }
}

//: MARK: Table Delegate
extension SongsViewController: UITableViewDelegate {

}
