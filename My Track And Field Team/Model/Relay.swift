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
    static let RELAY_LEG = "relayLeg"
    
    var team: String?
    var relayResults: [String: Leg]?
    
    override init(snapshot: DataSnapshot) {
        super.init(snapshot: snapshot)
        let dict = snapshot.value as! [String: Any]
        self.team = dict[Relay.TEAM] as? String
        
        relayResults = [String: Leg]()
        let relayEnumerator = snapshot.childSnapshot(forPath: Relay.RESULTS).children

        var i = 1
        while let legSnapshot = relayEnumerator.nextObject() as? DataSnapshot {
            relayResults!["leg\(i)"] = Leg(snapshot: legSnapshot)
            i += 1
        }
    }
    
    init(athletes: [Athlete]) {
        super.init()
        relayResults = [String: Leg]()
        var order = 0
        for athlete in athletes {
            order += 1
            let leg = Leg()
            leg.athlete = athlete
            relayResults!["\(Leg.LEG)\(order)"] = leg
        }
    }
    
    override func toDict() -> [String: Any] {
        var dict = super.toDict()
        dict[Relay.TEAM] = team
        
        var resultsDict = [String: Any]()
        for (order, leg) in relayResults! {
            resultsDict[order] = leg.toDict()
        }
        
        dict[Relay.RESULTS] = resultsDict
        return dict
    }
    
    func getRelayAthletes() -> [Athlete] {
        var athletes = [Athlete]()
        
        for i in 1...4 {
            let leg = relayResults!["leg\(i)"]!
            athletes.append(leg.athlete!)
        }
        
        return athletes
    }
    
    class Leg {
        static let LEG = "leg"
        static let ATHLETE = "athlete"
        static let SPLIT = "split"
        
        var athlete: Athlete?
        var split: String?
        
        init() {
        }
        
        init(snapshot: DataSnapshot) {
            let dict = snapshot.value as! [String: Any]
            self.athlete = Athlete(snapshot: snapshot.childSnapshot(forPath: Leg.ATHLETE))
            self.split = dict[Leg.SPLIT] as? String ?? ""
        }
        
        func toDict() -> [String: Any] {
            var dict = [String: Any]()
            dict[Leg.SPLIT] = split
            if athlete != nil {
                dict[Leg.ATHLETE] = athlete?.toDictBasic()
            }
            return dict
        }
    }
}
