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
    
    // update team with only name or password fields
    static func updateTeam(team: Team) {
        var updates = [String: Any]()
        updates[Team.NAME] = team.name
        let password = team.password?.trimmingCharacters(in: .whitespacesAndNewlines)
        updates[Team.PASSWORD] = password?.isEmpty ?? true ? FieldValue.delete() : password

        
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
    
    // update season, you will somehow need to implement a completion listener or someway to tell when the data has finished updating
    static func updateSeason(teamId: String, season: Season) {
        let desc = season.desc?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let teamRef = firestoreDB.document("\(Team.TEAM)/\(teamId)")
        teamRef.updateData(["\(Team.SEASONS).\(season.id!).\(Season.DESCRIPTION)" : desc?.isEmpty ?? true ? FieldValue.delete() : desc!])
    }
    
    // delete season from team
    // you will somehow need to implement a completion listener or someway to tell when the data has finished updating
    // maybe some kind of asynchronous call?
    // this is not tested, I would test this with a season that has 2 athletes, one that belongs to just the current season
    // and one that belongs to multiple seasons
    static func deleteSeason(team: Team, season: Season) {
        let batch = firestoreDB.batch() // prepare for batch update in firestore
        
        let teamPath = "\(Team.TEAM)/\(team.id!)"
        let teamRef = firestoreDB.document(teamPath)
        var field = Team.SEASONS
        // if there are other seasons, just delete the {seasonid} key otherwise delete the 'seasons' field from the team
        if team.seasons!.count > 1 {
            field = "\(field).\(season.id!)"
        }
        
        batch.updateData([field : FieldValue.delete()], forDocument: teamRef)
        
        // now if there is a roster in the season, must delete the season from the athletes' 'seasons' field
        let rosterRef = firestoreDB.collection("\(teamPath)/\(Team.ROSTER)").whereField(Athlete.SEASONS, arrayContains: season.id!)
        rosterRef.getDocuments() { (querySnapshot, err) in
        
            if querySnapshot!.count > 0 {
                for document in querySnapshot!.documents {
                    // get athlete
                    let athlete = Athlete(document: document)
                    // remove the deleted season from athlete 'seasons' field
                    var seasons = athlete.seasons!
                    let index = seasons.firstIndex(of: season.id!)
                    seasons.remove(at: index!)
                    
                    let nukeAthlete = seasons.isEmpty
                    
                    let athleteRef = firestoreDB.document("\(teamRef)/\(Team.ROSTER)/\(athlete.id!)")
                    var updates = [String: Any]()
                    
                    // completely remove athlete from database
                    if nukeAthlete {
                        // delete the athlete document because athlete no longer belongs to any season
                        batch.deleteDocument(athleteRef)
                        // delete the athlete from realtime database (in case there's any data lingering)
                        updates["\(Athlete.ATHLETES)/\(team.id!)/\(athlete.id!)"] = NSNull()
                        realTimeDB.child(Athlete.ATHLETES).child(team.id!).child(athlete.id!).removeValue()
                        // removes athlete photo if one exists
                        let photoRef = storageDB.child("\(Athlete.PHOTOS)/\(athlete.id!).jpg")
                        photoRef.delete()
                    } else {
                        // just remove season id from athlete with update
                        batch.updateData([Athlete.SEASONS : FieldValue.arrayRemove([season.id!])], forDocument: athleteRef)
                    }
                    
                    realTimeDB.updateChildValues(updates) // remove athete from realtime database in one batch call
                    batch.commit() // batch all updates and removals in one call
                }
            } else {
                // if there is no roster then commit right away
                batch.commit()
            }
        }
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
            updates["\(path)/\(seasonId)/\(Access.MANAGERS)/\(userId)"] = access ? true : NSNull()
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
            if error == nil {
                if athlete.denormalize {
                    let path = "\(Athlete.ATHLETES)/\(teamId)/\(athlete.id!)/\(Athlete.RESULTS)"
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
    // first checks if the athlete has results in this season, if so, display error message below
    // if the athlete only belongs to one season, delete document
    // if the athlete belongs to multiple seasons, then just remove the current seasonid from seasons array
    static func deleteAthlete(teamId: String, seasonId: String, athlete: Athlete) {
        let path = "\(Athlete.ATHLETES)/\(teamId)/\(athlete.id!)/\(Athlete.RESULTS)/\(seasonId)"
        realTimeDB.child(path).queryLimited(toFirst: 1).observeSingleEvent(of: .value) { (snapshot) in
            if (snapshot.exists()) {
                // show error
                // Unable to delete athlete. Delete all the athlete's event result(s) to continue.
            } else {
                let docRef = firestoreDB.document("\(Team.TEAM)/\(teamId)/\(Team.ROSTER)/\(athlete.id!)")

                var seasons = athlete.seasons!
                let index = seasons.firstIndex(of: seasonId)!
                seasons.remove(at: index)
                
                let nukeAthlete = seasons.isEmpty
                
                if nukeAthlete { // completely remove athlete from database
                    docRef.delete() { error in
                        if error == nil {
                            // nuke the athlete node from realtime database
                            realTimeDB.child("\(Athlete.ATHLETES)/\(teamId)/\(athlete.id!)").removeValue()
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
            if error == nil {
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
                        updates["\(scoringPath)/\(opponent)/\(nodeKey)"] = NSNull()
                    }
                }
            } else { // track events that will reorder (update the order field)
                order += 1
                
                updates["\(resultsPath)/\(nodeKey)/\(TrackEvent.ORDER)"] = order
                if isTrackDual { // also must recorder the scores
                    for i in 0..<meet.getOpponentCount() {
                        let opponent = "\(Competition.OPPONENT)\(i + 1)"
                        updates["\(scoringPath)/\(opponent)/\(nodeKey)/\(Score.ORDER)"] = order
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
            let multiEvents = MultiEvent.initMultiEventResults(multiEvent: event, isIndoor: isIndoor, isMale: team.isMale(), isOpen: team.isOpen())
            
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
    static func updateEventResult(team: Team, seasonId: String, meetId: String, event: String, eventResult: EventResult) {
        let result = eventResult.result
        let eventId = eventResult.id!
        
        var seed: Any? // seed is any because it can be a Double or an Int (result for multi-event is always an integer)
        
        if result == nil { // if input is entered with no result (blank), then seed should be removed from competition
            seed = NSNull()
        } else {
            // method to convert any type of result to a seed
            seed = EventResult.convertResultToSeed(eventResult: eventResult, isMetric: team.isMetric())
        }
        
        let nodeKey = encodeKey(key: event)
        
        var updates = [String: Any]()
        
        // path to competition data
        let competitionPath = "\(Competition.COMPETITIONS)/\(team.id!)/\(seasonId)/\(Competition.RESULTS)/\(meetId)/\(nodeKey)/\(TrackEvent.RESULTS)/\(eventId)"
        
        updates["\(competitionPath)/\(EventResult.RESULT)"] = eventResult.result
        updates["\(competitionPath)/\(EventResult.SEED)"] = seed
        updates["\(competitionPath)/\(EventResult.ATTEMPTS)"] = eventResult.attempts
        updates["\(competitionPath)/\(EventResult.TIMES)"] = eventResult.times
        
        // probably not necessary, but just in case athlete name didn't denormalize on an update, this will update the names
        updates["\(competitionPath)/\(EventResult.ATHLETE)/\(Athlete.FIRST_NAME)"] = eventResult.athlete?.firstName
        updates["\(competitionPath)/\(EventResult.ATHLETE)/\(Athlete.LAST_NAME)"] = eventResult.athlete?.lastName
        
        if eventResult.isMultiEvent() { // if the event is a multi-event, update multi-event results
            let multiEvent = eventResult as! MultiEvent
            updates["\(competitionPath)/\(MultiEvent.RESULTS)"] = multiEvent.multiEventDict()
        }
        
        // path to athlete
        let athletePath = "\(Athlete.ATHLETES)/\(team.id!)/\(eventResult.athlete!.id!)/\(Athlete.RESULTS)/\(seasonId)/\(meetId)/\(eventId)"
        
        if result == nil {
            updates[athletePath] = NSNull() // if no result, remove the path from the athlete
        } else { // populate athlete path with event result
            updates["\(athletePath)/\(EventResult.ID)"] = eventId
            updates["\(athletePath)/\(EventResult.NAME)"] = eventResult.name
            updates["\(athletePath)/\(EventResult.RESULT)"] = result
            updates["\(athletePath)/\(EventResult.SEED)"] = seed
            updates["\(athletePath)/\(EventResult.ATTEMPTS)"] = eventResult.attempts
            updates["\(athletePath)/\(EventResult.TIMES)"] = eventResult.times
        }
        
        realTimeDB.updateChildValues(updates)
    }
    
    // update relay result only
    static func updateRelayResult(team: Team, seasonId: String, meetId: String, event: String, relay: Relay, athletesRemoved: [String]?) {
        let result = relay.result
        let eventId = relay.id!
        
        var seed: Any? // seed is any because it can be a Double or an Int (result for multi-event is always an integer)
        
        if result == nil { // if input is entered with no result (blank), then seed should be removed from competition
            seed = NSNull()
        } else {
            // method to convert any type of result to a seed
            seed = EventResult.convertResultToSeed(eventResult: relay, isMetric: team.isMetric())
        }
        
        var updates = [String: Any]()
        
        // path to competition data, no need to encode the event since relay names are guaranteed
        let competitionPath = "\(Competition.COMPETITIONS)/\(team.id!)/\(seasonId)/\(Competition.RESULTS)/\(meetId)/\(event)/\(TrackEvent.RESULTS)/\(eventId)"
        
        updates["\(competitionPath)/\(EventResult.RESULT)"] = result
        updates["\(competitionPath)/\(EventResult.SEED)"] = seed
        updates["\(competitionPath)/\(Relay.TEAM)"] = relay.team
        
        var order = 0
        for leg in relay.relayResults!.values { // write to each leg in relayResults node
            order += 1
            
            let relayLeg = "\(Relay.Leg.LEG)\(order)" // leg1, leg2, leg3, leg4
            
            updates["\(competitionPath)/\(Relay.RESULTS)/\(relayLeg)/\(Relay.Leg.ATHLETE)"] = leg.athlete!.toDictBasic()
            updates["\(competitionPath)/\(Relay.RESULTS)/\(relayLeg)/\(Relay.Leg.SPLIT)"] = leg.split
            
            // path to athlete
            let athletePath = "\(Athlete.ATHLETES)/\(team.id!)/\(leg.athlete!.id!)/\(Athlete.RESULTS)/\(seasonId)/\(meetId)/\(eventId)"
            
            if result == nil {
                updates[athletePath] = nil // if no result, remove the path from the athlete
            } else { // populate athlete path with event result
                updates["\(athletePath)/\(EventResult.ID)"] = eventId
                updates["\(athletePath)/\(EventResult.NAME)"] = relay.name
                updates["\(athletePath)/\(EventResult.RESULT)"] = result
                updates["\(athletePath)/\(EventResult.SEED)"] = seed
                updates["\(athletePath)/\(Relay.RELAY_LEG)\(Relay.Leg.LEG)"] = relayLeg
                updates["\(athletePath)/\(Relay.RELAY_LEG)\(Relay.Leg.SPLIT)"] = leg.split
            }
        }
        
        // it is unlikley, but possible that an athlete can be replaced by another athlete in a relay after results were recorded
        // maybe two athletes have the same last name and the coach put the wrong one in and noticed it after the results were recorded
        // below loop will remove the event from the athlete's path who are no longer in the relay
        if athletesRemoved != nil {
            for athleteId in athletesRemoved! {
                let athletePath = "\(Athlete.ATHLETES)/\(team.id!)/\(athleteId)/\(Athlete.RESULTS)/\(seasonId)/\(meetId)/\(eventId)"
                updates[athletePath] = NSNull()
            }
        }
        
        realTimeDB.updateChildValues(updates)
    }
    
    // delete event result from competition node and athlete node
    static func deleteEventResult(teamId: String, seasonId: String, meetId: String, event: String, eventResult: EventResult) {
        let eventId = eventResult.id!
        
        let nodeKey = encodeKey(key: event)
        
        var updates = [String: Any]()
        
        // competition path
        let competitionPath = "\(Competition.COMPETITIONS)/\(teamId)/\(seasonId)/\(Competition.RESULTS)/\(meetId)/\(nodeKey)/\(TrackEvent.RESULTS)/\(eventId)"
        // delete event result from competition
        updates[competitionPath] = NSNull()
        
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
            let athletePath = "\(Athlete.ATHLETES)/\(teamId)/\(athleteId)/\(Athlete.RESULTS)/\(seasonId)/\(meetId)/\(eventId)"
            updates[athletePath] = NSNull()
        }
        
        realTimeDB.updateChildValues(updates)
    }
    
    // updates or deletes an athlete note/comment in the competition and athlete event result
    static func updateComment(teamId: String, seasonId: String, meetId: String, event: String, eventResult: EventResult) {
        let eventId = eventResult.id!
        
        let nodeKey = encodeKey(key: event)
        
        var updates = [String: Any]()
        
        // competition path
        let competitionPath = "\(Competition.COMPETITIONS)/\(teamId)/\(seasonId)/\(Competition.RESULTS)/\(meetId)/\(nodeKey)/\(TrackEvent.RESULTS)/\(eventId)"
        updates["\(competitionPath)/\(EventResult.COMMENT)"] = eventResult.comment
        
        // only non-relay athletes receive the comment in the athlete data
        if eventResult.athlete != nil {
            let athletePath = "\(Athlete.ATHLETES)/\(teamId)/\(eventResult.athlete!.id!)/\(Athlete.RESULTS)/\(seasonId)/\(meetId)/\(eventId)"
            updates["\(athletePath)/\(EventResult.COMMENT)"] = eventResult.comment
        }
        
        realTimeDB.updateChildValues(updates)
    }
    
    // updates splits field for certain distance events and all cross country races in a competition
    static func updateSplits(teamId: String, seasonId: String, meetId: String, event: String, eventResult: EventResult) {
        let eventId = eventResult.id!
        
        let nodeKey = encodeKey(key: event)
        
        var updates = [String: Any]()
        
        // competition path
        let competitionPath = "\(Competition.COMPETITIONS)/\(teamId)/\(seasonId)/\(Competition.RESULTS)/\(meetId)/\(nodeKey)/\(TrackEvent.RESULTS)/\(eventId)"
        updates["\(competitionPath)/\(EventResult.SPLITS)"] = eventResult.splits
        
        realTimeDB.updateChildValues(updates)
    }
    
    // updates the score field of a track meet or cross country meet
    static func updateScore(teamId: String, season: Season, meetId: String, opponent: String, score: Score) {
        var updates = [String: Any]()
        
        // competition path - scoring
        let competitionPath = "\(Competition.COMPETITIONS)/\(teamId)/\(season.id!)/\(Competition.SCORING)/\(meetId)/\(opponent)"
        if season.isCrossCountry() {
            updates["\(competitionPath)"] = score.toDictCrossCountryScoring()
        } else {
            updates["\(competitionPath)/\(score.name!)"] = score.toDictTrackScoring()
        }
        
        realTimeDB.updateChildValues(updates)
    }
    
    // delete notification
    static func deleteNotification(notificationId: String) {
        let notifRef = firestoreDB.document("\(Notification.NOTIFICATIONS)/\(notificationId)")
        notifRef.delete()
    }
    
    // send a manger request to a user, also write to realtime database which triggers a function to deliver a push notification
    static func requestManager(team: Team, user: User) {
        let notification = Notification()
        notification.id = user.id // gaurantees the user gets one manager request at a time
        notification.userId = user.id
        notification.teamId = team.id
        notification.title = "Assistant Coach Request"
        notification.message = "You have been requested to be an assistant coach of \(team.name!)."
        notification.type = Notification.TYPE_MANAGER_REQUEST
        notification.tokens = user.tokens
        
        let batch = firestoreDB.batch()
        
        // add pending to user teams with team id
        let userRef = firestoreDB.document("\(User.USER)/\(user.id!)")
        batch.updateData(["\(User.TEAMS).\(team.id!)": "pending"], forDocument: userRef)
        
        // add notification for user
        let notifRef = firestoreDB.document("\(Notification.NOTIFICATIONS)/\(notification.id!)")
        batch.setData(notification.toDict(), forDocument: notifRef)
        
        batch.commit() { (error) in
            if error != nil {
                print("error in firestore")
            } else {
                realTimeDB.child("managerRequests/\(notification.id!)").setValue(notification.toDictRequest())
                // possibly add completition listener here
            }
        }
    }
    
    // user accepts role as assistance coach
    static func acceptManager(notification: Notification) {
        let batch = firestoreDB.batch()
        
        // adds user as manager in team
        let teamRef = firestoreDB.document("\(Team.TEAM)/\(notification.teamId!)")
        batch.updateData([Team.MANAGERS: FieldValue.arrayUnion([notification.userId!])], forDocument: teamRef)
        
        // add manager to user teams with team id
        let userRef = firestoreDB.document("\(User.USER)/\(notification.userId!)")
        batch.updateData(["\(User.TEAMS).\(notification.teamId!)": Team.MANAGER], forDocument: userRef)
        
        // add notification for user
        let notifRef = firestoreDB.document("\(Notification.NOTIFICATIONS)/\(notification.id!)")
        batch.deleteDocument(notifRef)
        
        batch.commit() { (error) in
            if error != nil {
                print("error in firestore")
            } else {
                let path = "\(Access.ACCESS)/\(notification.teamId!)/\(Access.MANAGERS)/\(notification.userId!)"
                realTimeDB.child(path).setValue(true)
                // possibly add completition listener here
            }
        }
    }
    
    // cancel/decline a pending manger request either from owner side or potential assistant side
    static func cancelManager(notification: Notification) {
        let batch = firestoreDB.batch()
        
        // removes team id from user's teams
        let userRef = firestoreDB.document("\(User.USER)/\(notification.userId!)")
        batch.updateData(["\(User.TEAMS).\(notification.teamId!)": FieldValue.delete()], forDocument: userRef)
        
        // delete notification from user
        let notifRef = firestoreDB.document("\(Notification.NOTIFICATIONS)/\(notification.id!)")
        batch.deleteDocument(notifRef)
        
        batch.commit() { (error) in
           if error != nil {
                print("error in firestore")
            } else {
                // possible completition listener
            }
        }
    }
    
    // delete manager from team and all access fields
    static func deleteManager(team: Team, userId: String, completion: @escaping(_ error: String?) -> Void) {
        let teamId = team.id!
        
        let batch = firestoreDB.batch()
        
        // removes the team from the user's teams field
        let userRef = firestoreDB.document("\(User.USER)/\(userId)")
        batch.updateData(["\(User.TEAMS).\(teamId)" : FieldValue.delete()], forDocument: userRef)
        
        // removes the user from the managers array field
        let teamRef = firestoreDB.document("\(Team.TEAM)/\(teamId)")
        batch.updateData([Team.MANAGERS : FieldValue.arrayRemove([userId])], forDocument: teamRef)
        
        // now must remove user from access node in realtime database
        var updates = [String : Any]()
        let accessPath = "\(Access.ACCESS)/\(teamId)"
        
        // removes user as team manager
        updates["\(accessPath)/\(Access.MANAGERS)/\(userId)"] = NSNull()
        
        // removes user as season manager
        let seasons = team.seasons
        if seasons != nil { // this should always be true, but always check in case
            for season in seasons! {
                // if user is manager of any season, remove the user id
                if season.isManager(id: userId) {
                    updates["\(accessPath)/\(Access.SEASONS)/\(season.id!)/\(Access.MANAGERS)/\(userId)"] = NSNull()
                }
            }
        }
        
        realTimeDB.updateChildValues(updates) { (error, ref) in
            if let error = error {
                print("error in realtime database")
                completion(error.localizedDescription)
            } else {
                batch.commit() { (error) in
                    if error != nil {
                        print("error in firestore")
                    }
                    completion(error?.localizedDescription)
                }
            }
        }
    }
    
    static func addNote(teamId: String, athleteId: String, note: Note) {
        if note.comment!.isEmpty {
            // just make sure the comment cannot be empty
            return
        }
        
        let id = generateId()
        note.id = id
        let path = "\(Athlete.ATHLETES)/\(teamId)/\(athleteId)/\(Athlete.NOTES)/\(id)"
        
        realTimeDB.child(path).setValue(note.toDict())
    }
    
    static func updateNote(teamId: String, athleteId: String, note: Note) {
        if note.comment!.isEmpty {
            // just make sure the comment cannot be empty
            return
        }
        
        let path = "\(Athlete.ATHLETES)/\(teamId)/\(athleteId)/\(Athlete.NOTES)/\(note.id!)/\(Note.COMMENT)"
        
        realTimeDB.child(path).setValue(note.comment!)
    }
    
    static func deleteNote(teamId: String, athleteId: String, note: Note) {
        let path = "\(Athlete.ATHLETES)/\(teamId)/\(athleteId)/\(Athlete.NOTES)/\(note.id!)"
        
        realTimeDB.child(path).removeValue()
    }
    
    static func addRecord(teamId: String, record: Record) {
        let id = generateId()
        record.id = id
        
        let path = "\(Team.TEAM)/\(teamId)/\(Team.RECORDS)/\(id)"
        firestoreDB.document(path).setData(record.toDict())
    }
    
    static func updateRecord(teamId: String, record: Record) {
        let path = "\(Team.TEAM)/\(teamId)/\(Team.RECORDS)/\(record.id!)"
        firestoreDB.document(path).updateData(record.toDict())
    }
    
    static func deleteRecord(teamId: String, record: Record) {
        let path = "\(Team.TEAM)/\(teamId)/\(Team.RECORDS)/\(record.id!)"
        firestoreDB.document(path).delete()
    }
    
    static func storePurchasesToDatabase(userId: String, subscription: Int, subscriptionEnds: Int, purchaseInfo: Any) {
        var updates = [String: Any]()
        
        let batch = firestoreDB.batch()
        let userRef = firestoreDB.document("\(User.USER)/\(userId)")
        
        updates[User.SUBSCRIPTION] = subscription
        updates[User.SUBSCRIPTION_ENDS] = subscriptionEnds
        
        batch.updateData(updates, forDocument: userRef)
        
        // you will have to come up with a way to store the purchase order receipt, etc
        // see url for android example:
        // https://console.firebase.google.com/u/0/project/my-track-and-field-team-c3892/database/firestore/data~2Fbilling~2FGPA.3302-4737-4489-95272
        let billingRef = firestoreDB.document("billing/{purchaseInfo.ORDER_ID}")
        updates = [String: Any]()
        updates["userId"] = userId
        updates["receipt"] = "{purchaseInfo.RECEIPT}" // this is an example, I don't know how apple works
        updates["signature"] = "{purchaseInfo.SIGNATURE}" // this is an example, I don't know how apple works
        
        batch.setData(updates, forDocument: billingRef)
        
        batch.commit()
    }
}
