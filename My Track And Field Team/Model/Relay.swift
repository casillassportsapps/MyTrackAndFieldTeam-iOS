//
//  Relay.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/7/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Firebase

class Relay : EventResult {
    static let TEAM = "team"
    static let RESULTS = "relayResults"
    
    var team: String?
    var relayResults: [String: Leg]?
    
    override init(snapshot: DataSnapshot) {
        super.init(snapshot: snapshot)
        let dict = snapshot.value as! [String: Any]
        self.team = dict[Relay.TEAM] as? String ?? ""
        
        relayResults = [String: Leg]()
        let relayEnumerator = snapshot.childSnapshot(forPath: Relay.RESULTS).children

        var i: Int = 1
        while let legSnapshot = relayEnumerator.nextObject() as? DataSnapshot {
            relayResults!["leg\(i)"] = Leg(snapshot: legSnapshot)
            i += 1
        }
    }
    
    class Leg {
        static let LEG = "leg"
        static let ATHLETE = "athlete"
        static let SPLIT = "split"
        
        var athlete: Athlete?
        var split: String?
        
        init(snapshot: DataSnapshot) {
            let dict = snapshot.value as! [String: Any]
            self.athlete = Athlete(snapshot: snapshot.childSnapshot(forPath: Leg.ATHLETE))
            self.split = dict[Leg.SPLIT] as? String ?? ""
        }
    }
}
