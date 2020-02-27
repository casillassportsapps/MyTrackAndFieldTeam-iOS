//
//  EventDetailsViewController.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/8/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import UIKit
import Firebase

class EventDetailsViewController: UIViewController {
    
    let ref = DatabaseUtils.realTimeDB
    var resultsRef: DatabaseReference!
    var teamId: String!
    var seasonId: String!
    var meet: Competition!
    var trackEvent: TrackEvent!
    var isRelay: Bool!
    var isMultiEvent: Bool!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // sets up the snapshot observer
        self.observeResults()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // removes the snapshot observer
        resultsRef.removeAllObservers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // retrieve teamID from previous view controller
        // retrieve seasonID from previous view controller
        // retrieve competition model from previous view controller
        // retrieve trackEvent model from previous view controller
        // navigation bar should be title of track event
        
        // dummy data
        teamId = "-LICDiRCU9HzswMnhCzt"
        seasonId = "-Lj8rV0t-rtmWoKFAqVU"
        meet = Competition(id: "-LIqRaCSqctd_E-6eSkc")
        trackEvent = TrackEvent(name: "100m")
        
        // change name such as 3.1 Mile Run to 3*1 Mile Run, realtime database does not support "." in key
        let name = DatabaseUtils.encodeKey(key: trackEvent.name!)
        
        resultsRef = ref.child("\(Competition.COMPETITIONS)/\(teamId!)/\(seasonId!)/\(Competition.RESULTS)/\(meet.id!)/\(name)")
        
        isRelay = TrackEvent.isRelayEvent(name: name)
        isMultiEvent = TrackEvent.isMultiEvent(name: name)
        
        // menu options
        // Time:
        // clock menu icon where the user has an option to set a time when the event is going to be run or remove the time
        // if a time is set, the clock icon becomes the time (ie: 4:00 PM), when removed, the clock icon returns
        // this icon is only an option at invitationals or championship type competitions
    }
    
    func didSelectResult(eventResult: EventResult) {
        // on tapping of a tableViewCell
        // options below tableViewCell should become visible
        // option for edit a result, deleting the result, or entering a note
    }

    func observeResults() {
        // before loading data:
        // clear list of data to avoid possible duplicates
        // disable/hide add button or any other menu options
        
        resultsRef.observe(.childAdded, with: { (snapshot) -> Void in
            // add eventResult to tableView
            if self.isRelay {
                let relay = Relay(snapshot: snapshot)
                print("\(relay.team!) \(relay.result ?? "")")
            } else if self.isMultiEvent {
                let multiEvent = MultiEvent(snapshot: snapshot)
                print("\(multiEvent.athlete!.fullName()!) \(multiEvent.result ?? "")")
            } else {
                let eventResult = EventResult(snapshot: snapshot)
                print("Add: \(eventResult.athlete!.fullName()!) \(eventResult.result ?? "")")
            }
        })
        
        resultsRef.observe(.childChanged, with: { (snapshot) -> Void in
            // replace eventResult in tableView
            if self.isRelay {
                let relay = Relay(snapshot: snapshot)
                print("\(relay.team!) \(relay.result ?? "")")
            } else if self.isMultiEvent {
                let multiEvent = MultiEvent(snapshot: snapshot)
                print("\(multiEvent.athlete!.fullName()!) \(multiEvent.result ?? "")")
            } else {
                let eventResult = EventResult(snapshot: snapshot)
                print("Replace: \(eventResult.athlete!.fullName()!) \(eventResult.result ?? "")")
            }
        })
        
        resultsRef.observe(.childRemoved, with: { (snapshot) -> Void in
            // remove eventResult from tableView
            let eventResult = EventResult(snapshot: snapshot)
            print("Remove: \(eventResult.athlete!.fullName()!) \(eventResult.result ?? "")")
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
}
