//
//  Competition.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/8/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Firebase

class Competition: NSObject {
    static let COMPETITIONS = "competitions"
    static let SCHEDULE = "schedule"
    static let ID = "id"
    static let NAME = "name"
    static let LOCATION = "location"
    static let TYPE = "type"
    static let DATE_TIME = "dateTime"
    static let COURSE = "course"
    static let SEASON_ID = "seasonId"
    static let OPPONENT = "opponent"
    static let SCORE = "score"

    static let RESULTS = "results"
    static let SCORING = "scoring"
    
    var id: String?
    var name: String?
    var location: String?
    var type: String?
    var dateTime: Int?
    var course: String?
    var seasonId: String?
    
    var opponent: [String: String]?
    var score: [String: String]?
    
    var results: [EventResult]?
    
    override init() {
    }
    
    init(id: String) {
        self.id = id
    }
    
    // used with firestore to load a competition document from the schedule
    init(document: DocumentSnapshot) {
        let dict = document.data()!
        self.id = dict[Competition.ID] as? String
        self.name = dict[Competition.NAME] as? String
        self.location = dict[Competition.LOCATION] as? String
        self.type = dict[Competition.TYPE] as? String
        self.dateTime = dict[Competition.DATE_TIME] as? Int
        self.course = dict[Competition.COURSE] as? String
        self.seasonId = dict[Competition.SEASON_ID] as? String
        self.opponent = dict[Competition.OPPONENT] as? [String: String]
        self.score = dict[Competition.SCORE] as? [String: String]
    }
    
    // used with realtime database to load a competition from athletes node (athletes' personal result data)
    init(snapshot: DataSnapshot) {
        let dict = snapshot.value as! [String: Any]
        self.id = dict[Competition.ID] as? String ?? ""
        self.name = dict[Competition.NAME] as? String ?? ""
        self.location = dict[Competition.LOCATION] as? String ?? ""
        self.course = dict[Competition.COURSE] as? String ?? ""
        self.dateTime = dict[Competition.DATE_TIME] as? Int ?? 0
        
        if snapshot.hasChild(Competition.RESULTS) {
            results = [EventResult]()
            
            let resultsSnapshot = snapshot.childSnapshot(forPath: Competition.RESULTS)
            let resultsEnumerator = resultsSnapshot.children
            
            while let eventResultSnapshot = resultsEnumerator.nextObject() as? DataSnapshot {
                let eventResult = EventResult(snapshot: eventResultSnapshot)
                if eventResult.athlete != nil { // normal a event or multi-event
                    if eventResultSnapshot.hasChild(MultiEvent.RESULTS) { // multi-event
                        let multiEvent = MultiEvent(snapshot: eventResultSnapshot)
                        results?.append(multiEvent)
                    } else {
                        results?.append(eventResult)
                    }
                } else { // must be a relay (relay does not have athlete node)
                    let relay = Relay(snapshot: eventResultSnapshot)
                    results?.append(relay)
                }
            }
            
            let isTimed = TrackEvent.isEventTimed(name: name!) as Bool
            results = EventResult.sortResults(results: results!, isTimed: isTimed)
        } else {
            // this snapshot should exist, if it doesn't use crashlytics to log the error
            // something most likely went wrong after deleting results
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Competition {
            return self.id == object.id
        } else {
            return false
        }
    }
}
