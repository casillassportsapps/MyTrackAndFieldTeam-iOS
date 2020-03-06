//
//  Athlete.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/6/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Firebase

class Athlete: NSObject {
    static let ATHLETES = "athletes"
    static let ROSTER = "roster"
    static let ID = "id"
    static let FIRST_NAME = "firstName"
    static let LAST_NAME = "lastName"
    static let TYPE = "type"
    static let SEASONS = "seasons"
    
    static let RESULTS = "results"
    static let NOTES = "notes"
    
    static let PHOTOS = "athletePhotos"
    
    var id: String?
    var firstName: String?
    var lastName: String?
    var type: String?
    var seasons: [String]?
    var denormalize: Bool = false // set true ONLY if updating athlete's first name or last name
    
    override init() {
    }
    
    init(id: String) {
        self.id = id
    }
    
    init(snapshot: DataSnapshot) {
        let dict = snapshot.value as! [String: Any]
        self.id = dict[Athlete.ID] as? String ?? ""
        self.firstName = dict[Athlete.FIRST_NAME] as? String ?? ""
        self.lastName = dict[Athlete.LAST_NAME] as? String ?? ""
    }
    
    init(document: DocumentSnapshot) {
        let dict = document.data()!
        self.id = dict[Athlete.ID] as? String
        self.firstName = dict[Athlete.FIRST_NAME] as? String
        self.lastName = dict[Athlete.LAST_NAME] as? String
        self.type = dict[Athlete.TYPE] as? String
        self.seasons = dict[Athlete.SEASONS] as? [String]
    }
    
    func toDict() -> [String: Any] {
        var dict = self.toDictBasic()
        dict[Athlete.TYPE] = type
        dict[Athlete.SEASONS] = seasons
        return dict
    }
    
    func toDictBasic() -> [String: Any] {
        var dict = [String: Any]()
        dict[Athlete.ID] = id
        dict[Athlete.FIRST_NAME] = firstName
        dict[Athlete.LAST_NAME] = lastName
        return dict
    }
    
    // find all paths where athlete has competed in order to update athlete's name
    static func getPathsToDenormalize(teamId: String, athlete: Athlete, snapshot: DataSnapshot) -> [String: Any]? {
        if !snapshot.exists() {
            return nil
        }
        
        var updates = [String: Any]()
        
        let seasonEnumerator = snapshot.children
        while let seasonSnapshot = seasonEnumerator.nextObject() as? DataSnapshot {
            let seasonId = seasonSnapshot.key
            let competitionEnumerator = snapshot.children
            while let competitionSnapshot = competitionEnumerator.nextObject() as? DataSnapshot {
                let competitionId = competitionSnapshot.key
                let eventEnumerator = competitionSnapshot.children
                while let eventSnapshot = eventEnumerator.nextObject() as? DataSnapshot {
                    let eventResult = EventResult(snapshot: eventSnapshot)
                    
                    var eventName = DatabaseUtils.encodeKey(key: eventResult.name!)
                    // since event name is either Pentathlon (Outdoor) or Pentathlon (Indoor) must change the event name
                    // to pentathlon to get the correct path in the realtime database
                    if eventName.contains(TrackEvent.PENTATHLON) {
                        eventName = TrackEvent.PENTATHLON
                    }
                    
                    let path = "\(Competition.COMPETITIONS)/\(teamId)/\(seasonId)/\(Competition.RESULTS)/\(competitionId)\(eventName)\(TrackEvent.RESULTS)/\(eventResult.id!)"
                    
                    if eventResult.athlete != nil { // normal event or multi-event
                        updates["\(path)/\(EventResult.ATHLETE)"] = athlete.toDictBasic()
                    } else { // relay event
                        let relay = Relay(snapshot: eventSnapshot)
                        updates["\(path)/\(Relay.RESULTS)/\(relay.relayLeg!)/\(EventResult.ATHLETE)"] = athlete.toDictBasic()
                    }
                }
            }
        }
        
        return updates
    }
    
    func lastNameFirstName() -> String? {
        return "\(self.lastName ?? ""), \(self.firstName ?? "")"
    }
    
    func fullName() -> String? {
        return "\(self.firstName ?? "") \(self.lastName ?? "")"
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Athlete {
            return self.id == object.id
        } else {
            return false
        }
    }

}
