//
//  AccessUtils.swift
//  My Track And Field Team
//
//  Created by David Casillas on 4/12/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Foundation

class AccessUtils {
    
    var user: User!
    var access: Access!
    
    init(user: User, access: Access) {
        self.user = user
        self.access = access
    }
    
    // does the user have a subscription
    func isSubscribed(showError: Bool) -> Bool {
        let isSubscribed = self.user != nil && self.user.isSubscribed()
        if (showError && !isSubscribed) {
            let message = "You are not a subscribed user. You can select a subscription option in user settings."
            // show alert with message
        }
        
        return isSubscribed
    }
    
    // is the user a season manager
    func isSeasonManager(season: Season, showError: Bool) -> Bool {
        if self.access == nil {
            return false
        }
        let isSeasonManager = self.access.isSeasonManager(seasonId: season.id!, userId: self.user.id!)
        if (showError && !isSeasonManager) {
            let message = "No access to \(season.getFullName()). Contact team owner."
            // show alert with message
        }
        return isSeasonManager
    }
    
    // is the season locked for modifications
    func isSeasonLocked(seasonId: String, showError: Bool) -> Bool {
        if self.access == nil {
            return false
        }
        let isSeasonLocked = self.access.isSeasonLocked(seasonId: seasonId)
        if (showError && !isSeasonLocked) {
            let message = "Season is locked for modifications."
            // show alert with message
        }
        return isSeasonLocked
    }
    
    // does the user have season access (must be subscribed, the owner or season manager, and season is unlocked)
    func hasSeasonAccess(season: Season, showError: Bool) -> Bool {
        if self.access == nil {
            return false
        }
        
        let isTeamOwner = self.access.isTeamOwner(id: user.id!)
        let isSeasonManager = self.isSeasonManager(season: season, showError: showError)
        let isSeasonLocked = self.isSeasonLocked(seasonId: season.id!, showError: showError)
        let hasSeasonAccess = (isTeamOwner || isSeasonManager) && !isSeasonLocked
        
        return hasSeasonAccess && isSubscribed(showError: showError)
    }
    
    // does the user have write access to the athlete
    // user must be subscribed and either the owner or the manager must have the athlete in any of the athlete's season
    func hasAthleteAccess(athlete: Athlete) -> Bool{
        if self.access == nil {
            return false
        }
        
        if !isSubscribed(showError: true) {
            return false
        }
        
        if access.isTeamOwner(id: user.id!) {
            return true
        }
        
        for seasonId in athlete.seasons! {
            if access.isSeasonManager(seasonId: seasonId, userId: user.id!) {
                return true
            }
        }
        
        let message = "You do not have write of access to athlete."
        // show alert with message
        
        return false
    }
    
    
    // app subscription and season access logic
    func logic() {
        // Main UI when adding a team - must be a subscribed user but not a manager subscription
        if self.isSubscribed(showError: true) {
            if self.user.subscription == User.SUBSCRIPTION_MANAGER {
                let message = "Manager subscriptions do not have access to this function."
                // show alert with message
            } else {
                // Add Team
            }
        }
        
        // Main UI when adding a season
        // use: isTeamOwner() && isSubscribed(showError: true)
        
        // Exporting to .pdf or .cvs
        // use: isSubscribed(showError: true)
        
        // Team UI
        // season add button and ability to change the team photo
        // use: isTeamOwner() && isSubscribed(showError: true)
        
        // School Records UI
        // right now you must be a team owner to add a school record or the add button is hidden, you also must be a subscribed user
        // same logic with editing a school record
        // use: isTeamOwner() && isSubscribed(showError: true)
        
        // Managers UI - only displays for team owner
        // the only thing a user can't do is add a manager.
        // use: isSubscribed(showError: true)
        
        // Athlete Profile UI and Athlete Notes UI
        // adding, editing or deleting, including athlete photo
        // use: hasAthleteAccess(athlete: athlete)

        // For the rest of the app (Roster, Schedule, Competition Details, Event Details, Dual Meet)
        // use: hasSeasonAccess(season: season, showError: true) before showing the action
        // for the following actions:
        // clicking the add button
        // edit
        // delete
        // load (competition details)
        // save (competition details)
        // any event result option (event details)
        // setting event time (event details)
        // post score (dual meet)
        // changing place (dual meet)
    }
}
