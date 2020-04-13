//
//  Access.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/16/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Firebase

class Access: NSObject {
    
    static let ACCESS = "access"
    static let OWNER = "owner"
    static let MANAGERS = "managers"
    static let SEASONS = "seasons"
    static let LOCK = "locked"
    
    var owner: String?
    var teamManagers: [String]?
    var seasonLock: [String: Bool]?
    var seasonManagers: [String: [String]]?
    
    init(snapshot: DataSnapshot) {
        if !snapshot.exists() {
            return
        }
        
        let dict = snapshot.value as! [String: Any]
        self.owner = dict[Access.OWNER] as? String ?? ""
        
        if snapshot.hasChild(Access.MANAGERS) {
            teamManagers = [String]()
            
            let teamManagersSnapshot = snapshot.childSnapshot(forPath: Access.MANAGERS)
            let managersEnumerator = teamManagersSnapshot.children
            
            while let managerSnapshot = managersEnumerator.nextObject() as? DataSnapshot {
                let managerId = managerSnapshot.key
                teamManagers?.append(managerId)
            }
        } else {
            teamManagers = nil
        }
        
        if snapshot.hasChild(Access.SEASONS) {
            seasonLock = [String: Bool]()
            
            let seasonsSnapshot = snapshot.childSnapshot(forPath: Access.SEASONS)
            let seasonsEnumerator = seasonsSnapshot.children
            
            while let seasonSnapshot = seasonsEnumerator.nextObject() as? DataSnapshot {
                let seasonId = seasonSnapshot.key
                
                let seasonDict = snapshot.value as! [String: Any]
                let isLocked = seasonDict[Access.LOCK] as? Bool
                
                seasonLock?[seasonId]? = isLocked ?? false
                
                if snapshot.hasChild(Access.MANAGERS) {
                    seasonManagers = [String: [String]]()
                    var managersList = seasonManagers?[seasonId]
                    if managersList == nil {
                        managersList = [String]()
                    }
                    
                    let seasonManagersSnapshot = seasonSnapshot.childSnapshot(forPath: Access.MANAGERS)
                    let managersEnumerator = seasonManagersSnapshot.children
                    
                    while let managerSnapshot = managersEnumerator.nextObject() as? DataSnapshot {
                        let managerId = managerSnapshot.key
                        managersList?.append(managerId)
                    }
                    
                    seasonManagers?[seasonId] = managersList
                }
            }
        } else {
            seasonLock = nil
            seasonManagers = nil
        }
    }
    
    func isTeamOwner(id: String) -> Bool {
        return owner == id
    }
    
    func isTeamManager(id : String) -> Bool {
        return teamManagers != nil && teamManagers?.contains(id) ?? false
    }
    
    func isSeasonManager(seasonId: String, userId: String) -> Bool {
        if seasonManagers == nil {
            return false
        }
        
        let managers = seasonManagers?[seasonId]
        
        return managers != nil && managers?.contains(userId) ?? false
    }

    func isSeasonLocked(seasonId: String) -> Bool {
        if seasonLock == nil {
            return false
        }
        
        return seasonLock?[seasonId] ?? false
    }
}
