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
    
    static let TYPE_INVITATIONAL = "Invitational"
    static let TYPE_CHAMPIONSHIP = "Championship"
    static let TYPE_CROSSOVER = "Crossover"
    static let TYPE_DUAL_MEET = "Dual Meet"
    static let TYPE_DOUBLE_DUAL_MEET = "Double Dual Meet"
    static let TYPE_TRIPLE_DUAL_MEET = "triple Dual Meet"
    
    
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
    
    func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict[Competition.ID] = id
        dict[Competition.NAME] = name
        dict[Competition.LOCATION] = location
        dict[Competition.DATE_TIME] = dateTime
        dict[Competition.TYPE] = type
        if course != nil { // to avoid "nil" as a value in the database
            dict[Competition.COURSE] = course
        }
        if opponent != nil {
            dict[Competition.OPPONENT] = opponent
        }
        if score != nil {
            dict[Competition.SCORE] = score
        }
        
        return dict
    }
    
    func getMeetTypes(isIndoor: Bool) -> [String] {
        var types = [String]()
        types.append(Competition.TYPE_INVITATIONAL)
        types.append(Competition.TYPE_CHAMPIONSHIP)
        if isIndoor {
            types.append(Competition.TYPE_CROSSOVER)
        } else {
            types.append(Competition.TYPE_DUAL_MEET)
            types.append(Competition.TYPE_DOUBLE_DUAL_MEET)
            types.append(Competition.TYPE_TRIPLE_DUAL_MEET)
        }
        
        return types
    }
    
    func isInvite() -> Bool {
        return type == Competition.TYPE_INVITATIONAL
        || type == Competition.TYPE_CROSSOVER
    }
    
    func isDualMeet() -> Bool {
        return type == Competition.TYPE_DUAL_MEET
            || type == Competition.TYPE_DOUBLE_DUAL_MEET
            || type == Competition.TYPE_TRIPLE_DUAL_MEET
    }
    
    func isTrackDual(isOutdoor: Bool) -> Bool {
        return isDualMeet() && isOutdoor
    }
    
    func isCrossCountryDual(isCrossCountry: Bool) -> Bool {
        return isDualMeet() && isCrossCountry
    }
    
    func getOpponentCount() -> Int {
        return opponent?.count ?? 0
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Competition {
            return self.id == object.id
        } else {
            return false
        }
    }
    
    // this method retrieves a dictionary of event names to array of event results from the datasnapshot
    // the competitionsDict is needed so each event result takes it's respective competition for date/meet name in the stats tableview cell
    static func getStatResults(snapshot: DataSnapshot, competitionsDict: [String: Competition], isCrossCountry: Bool) -> [String: [EventResult]] {
        var dict = [String: [EventResult]]()
        
        let competitionEnumerator = snapshot.children
        while let competitionSnapshot = competitionEnumerator.nextObject() as? DataSnapshot {
            let competitionId = competitionSnapshot.key
            let competition = competitionsDict[competitionId]
            
            if competition != nil {
                let eventEnumerator = competitionSnapshot.children
                while let eventSnapshot = eventEnumerator.nextObject() as? DataSnapshot {
                    var event = eventSnapshot.key
                    event = DatabaseUtils.decodeKey(key: event)
                    if isCrossCountry {
                        // this is so the title of the event is something like 'Sunken Meadow 2.8 Mile Run'
                        event = competition!.course! + " " + event
                    }
                    
                    if eventSnapshot.hasChild(TrackEvent.RESULTS) {
                        let resultEnumerator = eventSnapshot.childSnapshot(forPath: TrackEvent.RESULTS).children
                        while let resultSnapshot = resultEnumerator.nextObject() as? DataSnapshot {
                            let eventResult = EventResult(snapshot: resultSnapshot)
                            
                            var eventResults = dict[event]
                            if eventResults == nil {
                                eventResults = [EventResult]()
                            }
                            
                            // must make sure there is a result and it's not a foul or dq
                            if !eventResult.isFoulOrDQ() && eventResult.result != nil {
                                if eventResult.isRelay() {
                                    let relay = Relay(snapshot: resultSnapshot)
                                    relay.competition = competition
                                    eventResults?.append(relay)
                                    dict[event] = eventResults
                                } else {
                                    eventResult.competition = competition
                                    eventResults?.append(eventResult)
                                    dict[event] = eventResults
                                }
                            }
                        }
                    }
                }
            }
        }
        
        
        
        
        
        
        
        return dict
    }
}
