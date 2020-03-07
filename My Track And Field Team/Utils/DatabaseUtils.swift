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
    
    static let realTimeDB = Database.database(url: "https://my-track-and-field-team-testing.firebaseio.com/").reference()
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
    
    // add athletes from other seasons by simply adding the season id to the athlete's seasons array
    static func addExistingAthletes(teamId: String, seasonId: String, athletes: [Athlete]) {
        let batch = firestoreDB.batch()
        
        for athlete in athletes {
            let docRef = firestoreDB.document("\(Team.TEAM)/\(teamId)/\(Team.ROSTER)/\(athlete.id!)")
            batch.updateData([Athlete.SEASONS: FieldValue.arrayUnion([seasonId])], forDocument: docRef)
        }
        
        batch.commit()
    }
    
    // update the athlete and denormalize competitions in realtime database
    // denormalize should be set to true if the athlete's first name or last name has changed
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
    
    // this func deletes the athlete either from the season or completely from the team
    // first checks if the athlete has results in this season, if so, display eror message below
    // if the athlete only belong to one season, delete document
    // if the athlete belongs to multiple seasons, then just remove the current seasonid from seasons array
    static func deleteAthlete(teamId: String, seasonId: String, athlete: Athlete) {
        //  first find out if athlete results exist in this season
        let path = "\(Athlete.ATHLETES)/\(athlete.id!)/\(Athlete.RESULTS)/\(teamId)/\(seasonId)"
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
                            // nuke the athlete node from realtime database
                            realTimeDB.child(Athlete.ATHLETES).child(athlete.id!).removeValue()
                            // removes athlete photo if there exists one
                            let photoRef = storageDB.child("\(Athlete.PHOTOS)/\(athlete.id!).jpg")
                            photoRef.delete()
                        }
                    }
                } else { // remove athlete just from season
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
    
    // updates the competition in the schedule, below are fields that can be updated
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
            .updateData(updates)
    }
    
    // this func deletes a competition from the schedule, but first checks if there are results in that competition
    // display error message below if there are results
    static func deleteCompetition(teamId: String, competition: Competition) {
        // first find out if competition results exist before a competition can be deleted
        let path = "\(Competition.COMPETITIONS)/\(teamId)/\(competition.seasonId!)/\(Competition.RESULTS)\(competition.id!)"
        realTimeDB.child(path).queryLimited(toFirst: 1).observeSingleEvent(of: .value) { (snapshot) in
            if (snapshot.exists()) {
                // show error
                // Unable to delete meet. Must delete all events and the results in this meet.
            } else {
                firestoreDB.document("\(Team.TEAM)/\(teamId)/\(Team.SCHEDULE)/\(competition.id!)").delete()
            }
        }
    }
    
    // this func adds track events to a meet
    // the 'numOfCurrentEvents' parameter is the number of track events already listed prior to calling this method
    static func addTrackEvents(teamId: String, isOutdoor: Bool, meet: Competition, trackEvents: [TrackEvent], numOfCurrentEvents: Int) {
        let seasonId = meet.seasonId!
        
        var updates = [String: Any]()
        
        let resultsPath = "\(Competition.COMPETITIONS)/\(teamId)/\(seasonId)/\(Competition.RESULTS)/\(meet.id!)"
        let scoringPath = "\(Competition.COMPETITIONS)/\(teamId)/\(seasonId)/\(Competition.SCORING)/\(meet.id!)"
        
        let isTrackDual = meet.isTrackDual(isOutdoor: isOutdoor)
        
        var order = numOfCurrentEvents
        
        for trackEvent in trackEvents {
            order += 1
            
            // if event name has a ".", change to "*" for the node
            let nodeKey = encodeKey(key: trackEvent.name!)
            
            trackEvent.order = order
            updates["\(resultsPath)/\(nodeKey)"] = trackEvent.toDict()
            
            // if the meet is a dual meet for outdoor track then also put in the events for scoring
            if isTrackDual {
                for i in 0..<meet.getOpponentCount() {
                    let opponent = "\(Competition.OPPONENT)\(i + 1)"
                    let score = Score(name: trackEvent.name!, order: order)
                    
                    updates["\(scoringPath)/\(opponent)/\(nodeKey)"] = score.toDictTrackScoring()
                }
            }
        
            realTimeDB.updateChildValues(updates)
        }
    }
    
    // this func deletes track events from a meet, then reorders the rest of the events
    // the trackEvents parameter should include all track events with the 'isDeleted' field as true only for the events to be deleted
    // track events cannot be deleted if there are results
    static func deleteTrackEvents(teamId: String, isOutdoor: Bool, meet: Competition, trackEvents: [TrackEvent]) {
        let seasonId = meet.seasonId!
        
        var updates = [String: Any]()
        
        let resultsPath = "\(Competition.COMPETITIONS)/\(teamId)/\(seasonId)/\(Competition.RESULTS)/\(meet.id!)"
        let scoringPath = "\(Competition.COMPETITIONS)/\(teamId)/\(seasonId)/\(Competition.SCORING)/\(meet.id!)"
        
        let isTrackDual = meet.isTrackDual(isOutdoor: isOutdoor)
        
        var order = 0
        for trackEvent in trackEvents {
            let nodeKey = encodeKey(key: trackEvent.name!)
            
            if trackEvent.deleted { // track events that will be deleted from database
                updates["\(resultsPath)/\(nodeKey)"] = nil
                if isTrackDual { // also must delete scores for track events that no longer exist
                    for i in 0..<meet.getOpponentCount() {
                        let opponent = "\(Competition.OPPONENT)\(i + 1)"
                        updates["\(scoringPath)/\(opponent)/\(nodeKey)"] = nil
                    }
                }
            } else { // track events that will reorder (update the order field)
                order += 1
                
                updates["\(resultsPath)/\(nodeKey)/\(TrackEvent.ORDER)"] = order
                if isTrackDual { // also must recorder the scores
                    for i in 0..<meet.getOpponentCount() {
                        let opponent = "\(Competition.OPPONENT)\(i + 1)"
                        updates["\(scoringPath)/\(opponent)/\(nodeKey)/\(Score.ORDER)"] = nil
                    }
                }
            }
        }
        
        realTimeDB.updateChildValues(updates)
    }
    
    // add athletes to an event, the event parameter is the TrackEvent.name
    static func addEventResult(team: Team, isIndoor: Bool, meet: Competition, event: String, athletes: [Athlete]) {
        let teamId = team.id!
        let seasonId = meet.seasonId!
        
        let nodeKey = encodeKey(key: event)
        
        var updates = [String: Any]()
        
        let path = "\(Competition.COMPETITIONS)/\(teamId)/\(seasonId)/\(Competition.RESULTS)/\(meet.id!)/\(nodeKey)/\(TrackEvent.RESULTS)"
        
        if TrackEvent.isRelayEvent(name: event) {
            let eventId = generateId()
            let relay = Relay(athletes: athletes)
            relay.id = eventId
            relay.name = event
            
            updates["\(path)/\(eventId)"] = relay.toDict()
        } else if TrackEvent.isMultiEvent(name: event) {
            let multiEvents = MultiEvent.getMultiEventList(event: event, isIndoor: isIndoor, isMale: team.isMale(), isOpen: team.isOpen())
            
            for athlete in athletes {
                let eventId = generateId()
                
                var name = event
                if name == TrackEvent.PENTATHLON {
                    if isIndoor {
                        name = TrackEvent.PENTATHLON_INDOOR
                    } else {
                        name = TrackEvent.PENTATHLON_OUTDOOR
                    }
                }
                
                let multiEvent = MultiEvent()
                multiEvent.id = eventId
                multiEvent.name = name
                multiEvent.athlete = athlete
                multiEvent.multiEventResults = multiEvents
                
                updates["\(path)/\(eventId)"] = multiEvent.toDict()
            }
        } else {
            for athlete in athletes {
                let eventId = generateId()
                let eventResult = EventResult(name: event)
                eventResult.id = eventId
                eventResult.athlete = athlete
                
                updates["\(path)/\(eventId)"] = eventResult.toDict()
            }
        }
        
        realTimeDB.updateChildValues(updates)
    }
    
    // update event result for non-relay events
    static func updateEventResult(team: Team, season: Season, meet: Competition, event: String, eventResult: EventResult) {
        
    }
    
    // update relay result only
    static func updateRelayResult(team: Team, season: Season, meet: Competition, event: String, eventResult: EventResult) {
        
    }
    
    // delete event result from competition node and athlete node
    static func deleteEventResult(teamId: String, seasonId: String, meetId: String, event: String, eventResult: EventResult) {
        let eventId = eventResult.id!
        
        let nodeKey = encodeKey(key: event)
        
        var updates = [String: Any]()
        
        // delete event result from competition
        let competitionPath = "\(Competition.COMPETITIONS)/\(teamId)/\(seasonId)/\(Competition.RESULTS)/\(meet.id!)/\(nodeKey)/\(TrackEvent.RESULTS)/\(eventId)"
        
        updates[competitionPath] = nil
        
        // delete event result from athlete
        var athleteIds = [String]()
        if eventResult.isRelay() {
            let relay = eventResult as! Relay
            for athlete in relay.getRelayAthletes() {
                athleteIds.append(athlete.id!)
            }
        } else {
            athleteIds.append(eventResult.athlete!.id!)
        }
        
        for athleteId in athleteIds {
            updates["\(Athlete.ATHLETES)/\(athleteId)/\(Athlete.RESULTS)/\(teamId)/\(seasonId)/\(meetId)/\(eventId)"] = nil
        }
        
        realTimeDB.updateChildValues(updates)
    }
}
