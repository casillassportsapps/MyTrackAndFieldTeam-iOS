//
//  AthleteDetailsViewController.swift
//  My Track And Field Team
//
//  Created by David Casillas on 3/23/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import UIKit
import Firebase


class AthleteDetailsViewController: UIViewController {
    
    let ref = DatabaseUtils.realTimeDB
    var resultsRef: DatabaseReference!
    let teamId = "-Kw7SanZs1Fry-It_NG9" // Islip
    let athleteId = "-KxrYMYWZjW0Wu78Ew9V" // Natalia Cuttler athlete Id
    
    var snapshotListener: ListenerRegistration!
    let storageRef = Storage.storage().reference()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load results of Natalia Cuttler
        self.loadResults()
        
        // explanation of athlete profile picture
        // you need a storage reference then download the link to the image
        // https://firebase.google.com/docs/storage/ios/download-files#generate_a_download_url
        // the athlete id in this case does have a link, therefore show the image
        let photoRef = self.storageRef.child("\(Athlete.PHOTOS)/\(athleteId).jpg")
        // fetch the download url, in android this method is run on a background thread and i assume it's same for ios
        photoRef.downloadURL { url, error in
          if error != nil {
            // most athletes won't have a photo so do nothing, default profile photo should show
          } else {
            // use whatever library or default ios way of showing the photo from url
          }
        }
        
        // menu options:
        // athlete stats
        // this will bring up the athlete stats page where the user you view personal bests, season bests, and chart
        // all the event results that was loaded from the loadResults() method should be passed to this page to avoid loading the data all over again
        
        // edit athlete
        // same UI as adding an athlete, except now the athlete first name, last name, and type can be updated and possible denormalized
        
        // delete athlete
        // an athlete can only be deleted if there are no results, see deleteAthlete() method in DatabaseUtils.swift
        
        // athlete notes
        // this goes to an athlete notes page, must pass in the event results that was loaded form the loadResults() method to retreive all the comments from the EventResult
    }
    
    func loadResults() {
        // database sample of above athlete:
        // https://my-track-and-field-team-testing.firebaseio.com/athletes/-Kw7SanZs1Fry-It_NG9/-KxrYMYWZjW0Wu78Ew9V
        
        // first get a one time call for the datasnapshot at athletes/{teamId}/{athleteId}/results
        
        resultsRef = ref.child("\(Athlete.ATHLETES)/\(teamId)/\(athleteId)/\(Athlete.RESULTS)")
        resultsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            // once we have the datasnapshot before we can iterate through the data,
            // we must get all competitions from the schedule, because we'll need it for the UI
            // use a snapshot listener to retreive competitions to avoid unnecessary reads
            
            // in android I found it easy to store competitions in a map/dictionary
            var competitionDict = [String: Competition]()
            
            let scheduleRef = DatabaseUtils.firestoreDB.collection("\(Team.TEAM)/\(self.teamId)/\(Team.SCHEDULE)")
            self.snapshotListener = scheduleRef.addSnapshotListener { (querySnapshot, err) in
                // important, remove snapshot listener
                self.snapshotListener.remove()
                
                if err != nil {
                    // this should not happen, but here just in case
                    return
                }
                
                // store competitions in dictionary
                for document in querySnapshot!.documents {
                    let competition = Competition(document: document)
                    competitionDict[competition.id!] = competition
                }
                
                // now iterate through the datasnapshot to get the athlete's results per season
                let seasonEnumerator = snapshot.children
                while let seasonSnapshot = seasonEnumerator.nextObject() as? DataSnapshot {
                    // use the seasonId to get the Season model from teams.seasons dictionary
                    // you will need the Season model for the name of season for the groupings
                    let seasonId = seasonSnapshot.key
                    print(seasonId)
                    
                    // store all competitions in an array for sorting
                    var competitions = [Competition]()
                    let competitionEnumerator = snapshot.children
                    while let competitionSnapshot = competitionEnumerator.nextObject() as? DataSnapshot {
                        let competitionId = competitionSnapshot.key
                        let competition = competitionDict[competitionId]
                        
                        // store all event results in an array for sorting
                        var results = [EventResult]()
                        let eventEnumerator = competitionSnapshot.children
                        while let eventSnapshot = eventEnumerator.nextObject() as? DataSnapshot {
                            // I updated the eventResult.swift class to get the 'relayLeg' field
                            // the 'split' field of the relayLeg will be used in the UI
                            let eventResult = EventResult(snapshot: eventSnapshot)
                            results.append(eventResult)
                        }
                        // sort the event results by natural event order
                        results.sort {TrackEvent.sortEvents(event1: $0.name!, event2: $1.name!)}
                        // store the results in the competition and store in competitions array
                        competition?.results = results
                        competitions.append(competition!)
                    }
                    // sort the competitions by the date earliest to latest
                    competitions.sort { $0.dateTime! < $1.dateTime! }
                    // store the competitions array with the corresponding season from above
                }
                
                // display in TableView
                // if there are no results at all, display "Athlete Has Not Competed"
                
                // by default, the results for the current season shall be expanded
                // if there are no results for the current season, all results stay collapsed
            }
        })
    }
}
