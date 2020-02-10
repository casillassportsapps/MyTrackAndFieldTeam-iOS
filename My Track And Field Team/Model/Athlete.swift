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
    
    var id: String?
    var firstName: String?
    var lastName: String?
    var type: String?
    var seasons: [String]?
    
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
