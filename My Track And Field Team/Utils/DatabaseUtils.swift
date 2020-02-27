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
    
    // give team owner access in realtime database
    static func allowTeamOwnerAccess(teamId: String, userId: String) {
        realTimeDB.child("\(Access.ACCESS)/\(teamId)/\(Access.OWNER)").setValue(userId)
    }
    
    // testing with a completion listener, but not neccessary
    static func allowTeamOwnerAccess(teamId: String, userId: String, success: @escaping (Bool) -> Void) {
        realTimeDB.child("\(Access.ACCESS)/\(teamId)/\(Access.OWNER)").setValue(userId) { (error, ref) in
            success(error == nil)
        }
    }
    
    // allow team access for manager
    static func allowTeamManagerAccess(teamId: String, userId: String) {
        realTimeDB.child("\(Access.ACCESS)/\(teamId)/\(Access.MANAGERS)/\(userId)").setValue(true)
    }
    
    // allow/disallow season access for manager
    static func updateSeasonAccess(teamId: String, userId: String, access: [String: Bool]) {
        var updates = [String: Any]()
        
        let path = "\(Access.ACCESS)/\(teamId)/\(Access.SEASONS)"
        for (seasonId, access) in access {
            updates["\(path)/\(seasonId)/\(Access.MANAGERS)/\(userId)"] = access ? true : nil
        }
        
        realTimeDB.updateChildValues(updates)
    }
    
    // toggle season access lock
    static func lockSeasonAccess(teamId: String, seasonId: String, locked: Bool) {
        let path = "\(Access.ACCESS)/\(teamId)/\(Access.SEASONS)/\(seasonId)/\(Access.LOCK)"
        realTimeDB.updateChildValues([path: locked])
    }
    
    // add athlete to current team and season
    static func addAthlete(teamId: String, seasonId: String, athlete: Athlete) {
        let athleteId = generateId()
        athlete.id = athleteId
        
        var seasons = [String]()
        seasons.append(seasonId)
        
        firestoreDB.document("\(Team.TEAM)/\(teamId)/\(Team.ROSTER)/\(athleteId)").setData(athlete.toDict())
    }
    
    // add athletes from other seasons
    static func addExistingAthletes(teamId: String, seasonId: String, athletes: [Athlete]) {
        let batch = firestoreDB.batch()
        
        for athlete in athletes {
            let docRef = firestoreDB.document("\(Team.TEAM)/\(teamId)/\(Team.ROSTER)/\(athlete.id!)")
            batch.updateData([Athlete.SEASONS: FieldValue.arrayUnion([seasonId])], forDocument: docRef)
        }
        
        batch.commit()
    }
    
    // update the athlete and denormalize competitions in realtime database
    static func updateAthlete(teamId: String, athlete: Athlete) {
        var updates = [String: Any]()
        updates[Athlete.FIRST_NAME] = athlete.firstName
        updates[Athlete.LAST_NAME] = athlete.lastName
        updates[Athlete.TYPE] = athlete.type
        
        let docRef = firestoreDB.document("\(Team.TEAM)/\(teamId)/\(Team.ROSTER)/\(athlete.id!)")
        docRef.updateData(updates) { error in
            if error != nil {
                if athlete.denormalize {
                    let path = "\(Athlete.ATHLETES)/\(athlete.id!)/\(Athlete.RESULTS)/\(teamId)"
                    realTimeDB.child(path).observeSingleEvent(of: .value) { (snapshot) in
                        let updates = Athlete.getPathsToDenormalize(teamId: teamId, athlete: athlete, snapshot: snapshot)
                        if updates != nil {
                            realTimeDB.updateChildValues(updates!)
                        }
                    }
                }
            }
        }
    }
    
    // delete the athlete either from the season or completely from the team
    static func deleteAthlete(teamId: String, seasonId: String, athlete: Athlete) {
        //  first find out if athlete results exist in this season
        let path = "\(Athlete.ATHLETES)/\(athlete.id!)/\(Athlete.RESULTS)/\(teamId)/\(Team.SEASONS)/\(seasonId)"
        realTimeDB.child(path).queryLimited(toFirst: 1).observeSingleEvent(of: .value) { (snapshot) in
            if (snapshot.exists()) {
                // show error
                // Unable to delete athlete. Must delete all the athlete's event results.
            } else {
                let docRef = firestoreDB.document("\(Team.TEAM)/\(teamId)/\(Team.ROSTER)/\(athlete.id!)")
                
                var seasons = athlete.seasons!
                let index = seasons.firstIndex(of: seasonId)!
                seasons.remove(at: index)
                
                let nukeAthlete = seasons.isEmpty
                
                if nukeAthlete { // completely remove athlete from database
                    docRef.delete() { error in
                        if error != nil {
                            realTimeDB.child(Athlete.ATHLETES).child(athlete.id!).removeValue()
                            let photoRef = storageDB.child("\(Athlete.PHOTOS)/\(athlete.id!).jpg")
                            photoRef.delete()
                        }
                    }
                } else { // remove athlete from season
                    docRef.updateData([Athlete.SEASONS: FieldValue.arrayRemove([seasonId])])
                }
            }
        }
    }
    
    // add competition to current season, if type is cross country dual meet, put in default scores in realtime database
    static func addCompetition(teamId: String, season: Season, competition: Competition) {
        let competitionId = generateId()
        competition.id = competitionId
        competition.seasonId = season.id
        
        let docRef = firestoreDB.document("\(Team.TEAM)/\(teamId)/\(Team.SCHEDULE)/\(competitionId)")
        docRef.setData(competition.toDict()) { error in
            if error != nil {
                if competition.isCrossCountryDual(isCrossCountry: season.isCrossCountry()) {
                    let path = "\(Competition.COMPETITIONS)/\(teamId)/\(season.id!)/\(Competition.SCORING)/\(competitionId)"
                    var dict = [String: Any]()
                    for i in 0..<competition.getOpponentCount() {
                        let opponent = "\(Competition.OPPONENT)\(i + 1)"
                        dict["\(path)/\(opponent)/\(Score.MY_PLACES)"] = Score.DEFAULT_XC_PLACES
                        dict["\(path)/\(opponent)/\(Score.OPPONENT_PLACES)"] = Score.DEFAULT_XC_PLACES
                    }
                    
                    realTimeDB.updateChildValues(dict)
                }
            }
        }
    }
    
    static func updateCompetition(teamId: String, competition: Competition) {
        var updates = [String: Any]()
        updates[Competition.NAME] = competition.name
        updates[Competition.LOCATION] = competition.location
        updates[Competition.DATE_TIME] = competition.dateTime
        if competition.course != nil {
            updates[Competition.COURSE] = competition.course
        }
        if competition.opponent != nil {
            updates[Competition.OPPONENT] = competition.opponent
        }
        
        firestoreDB.document("\(Team.TEAM)/\(teamId)/\(Team.SCHEDULE)/\(competition.id!)")
            .updateData(updates) { error in
                if error != nil {
                    if (competition.denormalize) {
                        // if denormalizing is necessary, retrieve competitions results of season
                        // and update the competition fields in the 'athletes' node for competeting athletes
                        let path = "\(Competition.COMPETITIONS)/\(teamId)/\(competition.seasonId!)/\(Competition.RESULTS)\(competition.id!)"
                        realTimeDB.child(path).observeSingleEvent(of: .value) { (snapshot) in
                            let updates = Competition.getPathsToDenormalize(teamId: teamId, competition: competition, snapshot: snapshot)
                            if updates != nil {
                                realTimeDB.updateChildValues(updates!)
                            }
                        }
                    }
                }
        }
    }
    
    static func deleteCompetition(teamId: String, competition: Competition) {
        // first find out if competition results exist before a competition can be deleted
        let path = "\(Competition.COMPETITIONS)/\(teamId)/\(competition.seasonId!)/\(Competition.RESULTS)\(competition.id!)"
        realTimeDB.child(path).queryLimited(toFirst: 1).observeSingleEvent(of: .value) { (snapshot) in
            if (snapshot.exists()) {
                // show error
                // Unable to delete meet. Must delete all events and the results of each event.
            } else {
                firestoreDB.document("\(Team.TEAM)/\(teamId)/\(Team.SCHEDULE)/\(competition.id!)").delete()
            }
        }
    }
}
