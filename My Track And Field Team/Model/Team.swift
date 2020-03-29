//
//  Team.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/20/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Firebase

class Team: NSObject {
    static let TEAM = "teams"
    static let ID = "id"
    static let OWNER = "owner"
    static let NAME = "name"
    static let PASSWORD = "password"
    static let LEVEL = "level"
    static let GENDER = "gender"
    static let UNIT = "unit"
    static let LOCATION = "location"
    static let MANAGERS = "managers"
    static let SEASONS = "seasons"
    
    static let SCHEDULE = "schedule"
    static let ROSTER = "roster"
    static let COMPETITIONS = "competitions"
    static let RECORDS = "records"
    
    static let MANAGER = "manager"
    
    static let PHOTOS = "teamPhotos"
    
    static let MALE = "male"
    static let FEMALE = "female"
    
    static let SCHOOL = "school";
    static let COLLEGE = "college";
    static let CLUB_YOUTH = "youth";
    static let CLUB_OPEN = "open";

    static let LEVELS = [SCHOOL, COLLEGE, CLUB_YOUTH, CLUB_OPEN];

    static let IMPERIAL = "imperial";
    static let METRIC = "metric";
    
    var id: String?
    var name: String?
    var password: String?
    var level: String?
    var gender: String?
    var unit: String?
    
    var owner: User?
    var location: Location?
    
    var managers: [String]?
    var seasons: [Season]?
    
    override init() {
    }
    
    init(name: String, password: String, level: String, gender: String, unit: String, owner: User, location: Location) {
        self.name = name
        self.password = password
        self.level = level
        self.gender = gender
        self.unit = unit
        self.owner = owner
        self.location = location
    }
    
    init(document: DocumentSnapshot) {
        let dict = document.data()!
        self.id = dict[Team.ID] as? String
        self.name = dict[Team.NAME] as? String
        self.password = dict[Team.PASSWORD] as? String
        self.level = dict[Team.LEVEL] as? String
        self.gender = dict[Team.GENDER] as? String
        self.unit = dict[Team.UNIT] as? String
        self.owner = dict[Team.OWNER] as? User
        self.location = dict[Team.LOCATION] as? Location
        self.managers = dict[Team.MANAGERS] as? [String]

        self.seasons = [Season]()
        if let seasonsDict = dict[Team.SEASONS] as? [String: [String: Any?]] {
            for (_, rawSeason) in seasonsDict {
                let season = Season(dict: rawSeason)
                seasons?.append(season)
            }
        }
    }
    
    func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict[Team.ID] = id
        dict[Team.NAME] = name
        dict[Team.PASSWORD] = password
        dict[Team.LEVEL] = level
        dict[Team.GENDER] = gender
        dict[Team.UNIT] = unit
        dict[Team.OWNER] = owner!.toDict()
        dict[Team.LOCATION] = location!.toDictUS()
        managers = [String]()
        managers?.append(owner!.id!)
        dict[Team.MANAGER] = managers
        return dict
    }
    
    func isMale() -> Bool {
        return self.gender == Team.MALE
    }
    
    func isOpen() -> Bool {
        return self.level == Team.COLLEGE || self.level == Team.CLUB_OPEN
    }
    
    func isMetric() -> Bool {
        return self.unit == Team.METRIC
    }
}
