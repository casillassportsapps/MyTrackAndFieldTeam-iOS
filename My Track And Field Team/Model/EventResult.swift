//
//  EventResult.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/6/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Firebase

class EventResult: NSObject {
    static let ID = "id"
    static let NAME = "name"
    static let RESULT = "result"
    static let TIMES = "times"
    static let ATTEMPTS = "attempts"
    static let POINTS = "points"
    static let COMMENT = "comment"
    static let ATHLETE = "athlete"
    static let SPLITS = "splits"
    static let SEED = "seed"
    
    static let DQ_SEED = 99999
    static let FOUL_SEED = -1
    static let UNAVAILABLE_SEED = -2 // should never be used, but just in case of any errors
    
    static let RUN_KILO = "K Run"; // build cross country race ie: 5K Run
    static let RUN_MILE = " Mile Run"; // build cross country race ie: 2.8 Mile Run
    
    var id: String?
    var name: String?
    var result: String?
    var comment: String?
    var points: Int?
    var seed: Double?
    
    var athlete: Athlete?
    
    var splits: [String]?
    var attempts: [String]?
    var times: [String: String]?
    
    override init() {
    }
    
    init(name: String) {
        self.name = name;
    }
    
    init(name: String, result: String) {
        self.name = name;
        self.result = result;
    }
    
    init(snapshot: DataSnapshot) {
        let dict = snapshot.value as! [String: Any]
        self.id = dict[EventResult.ID] as? String ?? ""
        self.name = dict[EventResult.NAME] as? String ?? ""
        self.result = dict[EventResult.RESULT] as? String ?? ""
        self.comment = dict[EventResult.COMMENT] as? String ?? ""
        self.points = dict[EventResult.POINTS] as? Int
        self.seed = dict[EventResult.SEED] as? Double
        
        if (snapshot.hasChild(EventResult.ATHLETE)) {
            let athleteSnapshot = snapshot.childSnapshot(forPath: EventResult.ATHLETE)
            self.athlete = Athlete(snapshot: athleteSnapshot)
        }
        
        self.splits = dict[EventResult.SPLITS] as? [String]
        self.attempts = dict[EventResult.ATTEMPTS] as? [String]
        self.times = dict[EventResult.TIMES] as? [String: String]
    }
    
    func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict[EventResult.ID] = id
        dict[EventResult.NAME] = name
        if athlete != nil { // check this because relay.toDict overrides this func and doesn't have athlete field
            dict[EventResult.ATHLETE] = athlete?.toDictBasic()
        }
        return dict
    }
    
    func toDictMultiEvent() -> [String: Any] {
        var dict = [String: Any]()
        dict[EventResult.NAME] = name
        dict[EventResult.POINTS] = 0
        return dict
    }
    
    func setTrial(time: String) {
        if times == nil {
            times = [String: String]()
        }
        
        times?["trial"] = time
    }
    
    func getTrial() -> String? {
        return times?["trial"]
    }
    
    func setFinal(time: String) {
        if times == nil {
            times = [String: String]()
        }
        
        times?["final"] = time
    }
    
    func getFinal() -> String? {
        return times?["final"]
    }
    
    func isRelay() -> Bool {
        return TrackEvent.isRelayEvent(name: self.name ?? "")
    }
    
    static func compareResults(eventResult1: EventResult, eventResult2: EventResult, isTimed: Bool) -> Int {
        if eventResult1.name == eventResult2.name {
            return 0;
        }
        
        var seed1 = eventResult1.seed
        if seed1 == nil {
            seed1 = Double(isTimed ? DQ_SEED : FOUL_SEED)
        }
        
        var seed2 = eventResult2.seed
        if seed2 == nil {
            seed2 = Double(isTimed ? DQ_SEED : FOUL_SEED)
        }
        
        if (seed1 == seed2) { // if seeds are the same, compare athletes or relay team
            let athlete1 = eventResult1.athlete
            let athlete2 = eventResult2.athlete
            
            if athlete1 != nil && athlete2 != nil {
                return 0 // return compare athlete.lastNameFirstName case insensitive
            } else if eventResult1.isRelay() && eventResult2.isRelay() {
                let relay1 = eventResult1 as? Relay
                let relay2 = eventResult2 as? Relay
                if relay1 != nil && relay2 != nil {
                    return 0 // return compare relay.team case insensitive
                }
            }
        } else {
            return isTimed ? Int(seed1! - seed2!) : Int(seed2! - seed1!)
        }
        
        return 0
    }
    
    static func sortResults(results: [EventResult], isTimed: Bool) -> [EventResult] {
        var sortedResults = [EventResult]()
        if isTimed {
            sortedResults = results.sorted(by: { $0.seed ?? Double(EventResult.DQ_SEED) < $1.seed ?? Double(EventResult.DQ_SEED) })
        } else {
            sortedResults = results.sorted(by: { $0.seed ?? Double(EventResult.FOUL_SEED) > $1.seed ?? Double(EventResult.FOUL_SEED) })
        }
        return sortedResults
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? EventResult {
            return self.id == object.id
        } else {
            return false
        }
    }
}
