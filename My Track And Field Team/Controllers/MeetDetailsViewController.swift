//
//  MeetDetailsViewController.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/8/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import UIKit
import Firebase

let ref = DatabaseUtils.realTimeDB
var resultsRef: DatabaseReference!
var teamId: String!
var seasonId: String!
var meet: Competition!

class MeetDetailsViewController: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // sets up a snapshot observer
        self.observeResults()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // removes the observer
        resultsRef.removeAllObservers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // retrieve teamID from previous view controller
        // retrieve seasonID from previous view controller
        // retrieve competition model from previous view controller
        // navigation bar title should be name of competition
        
        // dummy data
        teamId = "-LICDiRCU9HzswMnhCzt"
        seasonId = "-Lj8rV0t-rtmWoKFAqVU"
        meet = Competition(id: "-LIqRaCSqctd_E-6eSkc")
        
        resultsRef = ref.child("\(Competition.COMPETITIONS)/\(teamId!)/\(seasonId!)/\(Competition.RESULTS)/\(meet.id!)")
        
        // menu options
        // Edit, Delete, Save Events, Load Events, Dual Meet Score (always show this icon), Events By Athlete, Export
        
        // Edit:
        // edit a competition by loading the "competition form" populated by current competition information
        // all fields can be updated, see DatabaseUtils method updateCompetition
        // if the competition is a dual meet, the name of the meet nor the number of opponents can be changed
        
        // Delete:
        // a competition can only be deleted if there are no events
        
        // Save Events:
        // saves the events in order to a local database for future loading
        // hide menu icon if season is cross country
        
        // Load Events:
        // adds the events to a meet loaded from a local database, can only be done if there are no events
        // hide menu icon if season is cross country
        
        // Dual Meet Score:
        // this menu icon should always show, on clicked perform segue to DualMeetViewController
        // can only be clicked on if there is at least one event
        // only show menu icon if the meet is a type Dual, Double, or Triple Dual Meet
        
        // Events By Athlete:
        // shows all the athletes in alphabetical order and the events they are competiting in
        // can only be used if there are results
        
        // Export: option to select excel or pdf
        // exports the data to the selected option
    }
    
    func didSelectEvent(trackEvent: TrackEvent) {
        // perform segue to EventDetailsViewController when the tableViewCell is tapped
        // send data: teamId, competition model, and trackEvent from parameter
    }
    
    func didLongTapEvent() {
        // this allows an option to then select multiple events to delete
        // events can only be deleted only if there are no results
    }
    
    func observeResults() {
        // before loading data:
        
        // loading dialog should appear
        // clear list of data to avoid possible duplicates
        // disable/hide add button or any other menu options
        
        resultsRef.observe(.childAdded, with: { (snapshot) -> Void in
            // add trackEvent to tableView
            let trackEvent = TrackEvent(snapshot: snapshot)
            print(trackEvent.name!)
            print("--------------------")
            if let results = trackEvent.results {
                for eventResult in results {
                    if let athlete = eventResult.athlete {
                        print("\(athlete.fullName() ?? "") \(eventResult.result ?? "")")
                    } else {
                        let relay = eventResult as! Relay
                        print("\(relay.team!) \(relay.result ?? "")")
                    }
                }
                print("--------------------")
            }
        })
        
        resultsRef.observe(.childChanged, with: { (snapshot) -> Void in
            // replace trackEvent in tableView
            let trackEvent = TrackEvent(snapshot: snapshot)
            print("childChanged: \(trackEvent.name ?? "")")
        })
        
        resultsRef.observe(.childRemoved, with: { (snapshot) -> Void in
            // remove trackEvent from tableView
            let trackEvent = TrackEvent(snapshot: snapshot)
            print("childRemoved: \(trackEvent.name ?? "")")
        })
        
        resultsRef.observeSingleEvent(of: .value, with:  { (snapshot) in
            // this observeSingleEvent method is not loading the data again according to firebase
            // this is to guarantee that all the data has been loaded
            
            // after data is loaded:
            // enable/show add button or any other menu options
            // loading dialog should disappear
        })
    }

    // singleQueryCompetitionData not used, just practice
    func singleQueryCompetitionData() {
        let ref = Database.database(url: "https://my-track-and-field-team-firestore.firebaseio.com/").reference()
        
        let teamId = "-LICDiRCU9HzswMnhCzt"
        let seasonId = "-Lj8rV0t-rtmWoKFAqVU"
        let competitionId = "-LIqRaCSqctd_E-6eSkc"
        
        //let compRef = ref.child("competitions").child(teamId).child(seasonId).child("results").child(competitionId)
        let compRef = ref.child("competitions/\(teamId)/\(seasonId)/\("results")/\(competitionId)")
        compRef.observeSingleEvent(of: .value, with:  { (snapshot) in
            let eventEnumerator = snapshot.children
            while let eventSnapshot = eventEnumerator.nextObject() as? DataSnapshot {
                let event = eventSnapshot.childSnapshot(forPath: "name").value as? String ?? ""
                print("-------------------------------")
                print(event)
                print("-------------------------------")
                
                let resultsEnumerator = eventSnapshot.childSnapshot(forPath: "results").children
                while let eventResultSnapshot = resultsEnumerator.nextObject() as? DataSnapshot {
                    let eventResult = EventResult(snapshot: eventResultSnapshot)
                    if let athlete = eventResult.athlete { // normal a event or multi-event
                        print("\(athlete.fullName() ?? "") \(eventResult.result ?? "")")
                        if eventResultSnapshot.hasChild(MultiEvent.RESULTS) { // multi-event
                            let multiEvent = MultiEvent(snapshot: eventResultSnapshot)
                            for eventResult in multiEvent.multiEventResults!.values {
                                print("\(eventResult.name ?? "") \(eventResult.result ?? "") \(eventResult.points ?? 0)")
                            }
                        }
                    } else { // must have a relay
                        let relay = Relay(snapshot: eventResultSnapshot)
                        print("\(relay.team ?? "") \(eventResult.result ?? "")")
                        for leg in relay.relayResults!.values {
                            print("\(leg.athlete?.fullName() ?? "") \(leg.split ?? "")")
                        }
                    }
                }
                
            }
        }) { (error) in
            print("Error: \(error.localizedDescription)")
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}
