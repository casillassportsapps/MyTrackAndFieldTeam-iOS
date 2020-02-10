//
//  Season.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/9/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Firebase

class Season: NSObject {
    static let SEASONS = "seasons"
    static let COMPETITIONS = "competitions"
    static let ID = "id"
    static let NAME = "name"
    static let YEAR = "year"
    static let DESCRIPTION = "description"
    static let LOCKED = "locked"
    static let MANAGERS = "managers"
    
    static let CROSS_COUNTRY = "cross country"
    static let INDOOR = "indoor"
    static let OUTDOOR = "outdoor"
    
    static let seasonList = [CROSS_COUNTRY, INDOOR, OUTDOOR]
    
    var id: String?
    var name: String?
    var desc: String?
    var year: Int?
    var locked: Bool?
    var managers: [String]?
    var competitions: [Competition]? // used to retrieve athlete data
    
    override init() {
    }
    
    // used with realtime database to load a season from athletes node (athletes' personal result data)
    init(snapshot: DataSnapshot) {
        let dict = snapshot.value as! [String: Any]
        self.id = dict[Season.ID] as? String ?? ""
        self.name = dict[Season.NAME] as? String ?? ""
        self.year = dict[Season.YEAR] as? Int ?? 0
        
        if snapshot.hasChild(Season.COMPETITIONS) {
            competitions = [Competition]()
            
            let competitionsSnapshot = snapshot.childSnapshot(forPath: Season.COMPETITIONS)
            let competitionsEnumerator = competitionsSnapshot.children
             while let competitionSnapshot = competitionsEnumerator.nextObject() as? DataSnapshot {
                let competition = Competition(snapshot: competitionSnapshot)
                competitions?.append(competition)
            }
            
            competitions?.sort(by: {$0.dateTime! < $1.dateTime!})
        }
    }
    
    func isCrossCountry() -> Bool {
        return name == Season.CROSS_COUNTRY
    }
    
    func isIndoor() -> Bool {
        return name == Season.INDOOR
    }
    
    func isOutdoor() -> Bool {
        return name == Season.OUTDOOR
    }
    
    func getSeasonName() -> String {
        if isCrossCountry() {
            return "Cross Country"
        }
        
        if isIndoor() {
            return "Indoor"
        }
        
        if isOutdoor() {
            return "Outdoor"
        }
        
        return ""
    }
    
    func getIndoorYears() -> String {
        return "\(year!)-\(year! + 1)"
    }
    
    func getYear() -> String {
        return isIndoor() ? getIndoorYears() : "\(year!)"
    }
    
    func getFullName() -> String {
        return "\(getSeasonName())\(isCrossCountry() ? " " : " Track ")\(getYear())"
    }
    
    func getFullNameWithDescription() -> String {
        if desc == nil {
            return getFullName()
        }
        
        return "\(desc!) \(getSeasonName())\(isCrossCountry() ? " " : " Track ")\(getYear())"
    }
    
    static func sortSeasons(seasons: Array<Season>, ascending: Bool) -> [Season] {
        var sortedSeasons = [Season]()
        sortedSeasons.sort { (season1, season2) -> Bool in
            let year1 = season1.year
            let year2 = season2.year
            
            var index1 = getSeasonNameIndex(name: season1.name!)
            var index2 = getSeasonNameIndex(name: season2.name!)
            
            if year1! > year2! {
                index1 += 6
            } else if year1! < year2! {
                index2 += 6
            }
            
            return ascending ? index1 < index2 : index1 > index2
        }
        
        return sortedSeasons
    }
    
    private static func getSeasonNameIndex(name: String) -> Int {
        switch name {
        case Season.OUTDOOR:
            return 0
        case Season.CROSS_COUNTRY:
            return 2
        case Season.INDOOR:
            return 4
        default:
            return -1
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Season {
            return self.id == object.id
        } else {
            return false
        }
    }
}