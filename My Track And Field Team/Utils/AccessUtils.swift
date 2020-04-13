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
    
    // is the user subscribed, but with the manager option
    func isSubscribedAsManager(showError: Bool) -> Bool {
        let isSubscribedAsManager = self.user != nil && self.user.isSubscribedAsManager()
        if (showError && !isSubscribedAsManager) {
            let message = "Manager subscriptions do not have access to this function."
            // show alert with message
        }
        
        return isSubscribedAsManager
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
}
