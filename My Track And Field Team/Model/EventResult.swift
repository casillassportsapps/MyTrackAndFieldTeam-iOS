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
    
    static let RUN_KILO = "K Run";
    static let RUN_MILE = " Mile Run";
    
    var id: String?
    var name: String?
    var result: String?
    var comment: String?
    var points: Int?
    var seed: Double?
    
    var athlete: Athlete?
    
    var splits: Array<String>?
    var attempts: Array<String>?
    var times: Dictionary<String, String>?
    
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
        
        self.splits = dict[EventResult.SPLITS] as? Array<String>
        self.attempts = dict[EventResult.ATTEMPTS] as? Array<String>
        self.times = dict[EventResult.TIMES] as? [String: String]
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
