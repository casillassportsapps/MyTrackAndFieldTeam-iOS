//
//  DatabaseUtils.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/8/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import UIKit
import Firebase

class DatabaseUtils {
    
    static let realTimeDB = Database.database(url: "https://my-track-and-field-team-firestore.firebaseio.com/").reference()
    static let firestoreDB = Firestore.firestore()
    static let storageDB = Storage.storage().reference()
    
    static func generateId() -> String {
        return realTimeDB.childByAutoId().key!
    }
    
    // necessary for cross country race names, since realtime database nodes cannot have a '.'
    static func encodeKey(key: String) -> String {
        if key.contains(".") {
            return key.replacingOccurrences(of: ".", with: "*")
        }
        return key
    }
    
    // necessary for cross country race names, since realtime database nodes cannot have a '.'
    static func decodeKey(key: String) -> String {
        if key.contains("*") {
            return key.replacingOccurrences(of: "*", with: ".")
        }
        return key
    }
    
    // add a new team
    static func addTeam(team: Team) {
        let teamId = generateId() // generate an id from realtime db (easier than firestore id)
        team.id = teamId
        
        let batch = firestoreDB.batch() // batch write multiple documents
        
        let teamRef = firestoreDB.document("\(Team.TEAM)/\(teamId)")
        batch.setData(team.toDict(), forDocument: teamRef) // add new team document
        
        let ownerId = team.owner!.id!
        let userRef = firestoreDB.document("\(User.USER)/\(ownerId)")
        let fields = ["\(User.TEAMS).\(teamId)": Team.OWNER]
        batch.updateData(fields, forDocument: userRef) // update user's teams field
        
        // writes the team doc and user doc asynchronously
        batch.commit() { error in
            if error == nil { // team added successfully
                allowTeamOwnerAccess(teamId: teamId, userId: ownerId) // adds team access in realtime database
            }
        }
    }
    
    // update team with only name, password, or unit fields
    static func updateTeam(team: Team) {
        var updates = [String: Any]()
        updates[Team.NAME] = team.name
        let password = team.password?.trimmingCharacters(in: .whitespacesAndNewlines)
        updates[Team.PASSWORD] = password?.isEmpty ?? true ? FieldValue.delete() : password
        updates[Team.UNIT] = team.unit
        
        firestoreDB.document("\(Team.TEAM)/\(team.id!)").updateData(updates)
    }
    
    // delete team (only successful if there are no longer any seasons)
    static func deleteTeam(team: Team) {
        let teamId = team.id
        
        let batch = firestoreDB.batch()
        
        let teamRef = firestoreDB.document("\(Team.TEAM)/\(teamId!)")
        batch.deleteDocument(teamRef) // delete team document
        
        let managers = team.managers
        if managers != nil {
            for id in managers! {
                let userRef = firestoreDB.document("\(User.USER)/\(id)")
                let fields = ["\(User.TEAMS).\(teamId!)": FieldValue.delete()]
                batch.updateData(fields, forDocument: userRef)
            }
        }
        
        // deletes the team doc and updates user doc asynchronously
        batch.commit() { error in
            if error == nil { // team deleted successfully
                realTimeDB.child("\(Access.ACCESS)/\(teamId!)").removeValue() // removes team access in realtime database
                let photoRef = storageDB.child("\(Team.PHOTOS)/\(teamId!).jpg")
                photoRef.delete()
            }
        }
    }
    
    // add new season to a team
    static func addSeason(teamId: String, season: Season) {
        let seasonId = generateId()
        season.id = seasonId
        
        let teamRef = firestoreDB.document("\(Team.TEAM)/\(teamId)")
        let fields = ["\(Team.SEASONS).\(seasonId)": season.toDict()]
        teamRef.updateData(fields)
    }
    
    // update season
    static func updateSeason(teamId: String, season: Season) {
        let seasonId = season.id
        
        var updates = [String: Any]()
        updates["\(Team.SEASONS).\(seasonId!).\(Season.NAME)"] = season.name
        
        let desc = season.desc?.trimmingCharacters(in: .whitespacesAndNewlines)
        updates["\(Team.SEASONS).\(seasonId!).\(Season.DESCRIPTION)"] = desc?.isEmpty ?? true ? FieldValue.delete() : desc
        
        let teamRef = firestoreDB.document("\(Team.TEAM)/\(teamId)")
        teamRef.updateData(updates)
    }
    
    // delete season from team
    static func deleteSeason(teamId: String, season: Season) {
        
    }
    
    static func allowTeamOwnerAccess(teamId: String, userId: String) {
        realTimeDB.child("\(Access.ACCESS)/\(teamId)/\(Access.OWNER)").setValue(userId)
    }
    
    // messing around with a completion listener, not neccessary here
    static func allowTeamOwnerAccess(teamId: String, userId: String, success: @escaping (Bool) -> Void) {
        realTimeDB.child("\(Access.ACCESS)/\(teamId)/\(Access.OWNER)").setValue(userId) { (error, ref) in
            success(error == nil)
        }
    }
    
}
