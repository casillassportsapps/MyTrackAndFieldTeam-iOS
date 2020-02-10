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
        self.observeResults()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resultsRef.removeAllObservers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // retrieve teamID from previous view controller
        // retrieve seasonID from previous view controller
        // retrieve competition model from previous view controller
        
        teamId = "-LICDiRCU9HzswMnhCzt"
        seasonId = "-Lj8rV0t-rtmWoKFAqVU"
        meet = Competition(id: "-LIqRaCSqctd_E-6eSkc")
        
        resultsRef = ref.child("\(Competition.COMPETITIONS)/\(teamId!)/\(seasonId!)/\(Competition.RESULTS)/\(meet.id!)")
    }
    
    func didSelectEvent(trackEvent: TrackEvent) {
        // perform segue to EventDetailsViewController
        // send data: teamId, competition model, and trackEvent from parameter
    }
    
    func didSelectDualMeet() {
        // perform segue to DualMeetViewController
    }
    
    func observeResults() {
        // before loading data:
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
            // after data is loaded:
            // enable/show add button or any other menu options
        }) { (error) in
            // show error if unable to read data
            // only happens when a user is removed as a manager or an unauthorized user (can't really happen)
            print("Error: You no longer have access to this team's data")
        }
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
