//
//  User.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/20/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Foundation

class User: NSObject {
    static let USER = "users"
    static let ID = "id"
    static let NAME = "name"
    static let EMAIL = "email"
    static let TEAMS = "teams"
    static let SUBSCRIPTION = "subscription"
    static let SUBSCRIPTION_ENDS = "subscriptionEnds"
    static let CREATED = "created"
    
    static let SUBSCRIPTION_MANAGER = 4;
    static let SUBSCRIPTION_SEASON = 3;
    static let SUBSCRIPTION_YEARLY = 2;
    static let SUBSCRIPTION_SINGLE_YEAR = 1;
    static let SUBSCRIPTION_NONE = 0;
    static let SUBSCRIPTION_FREE = -1;
    static let SUBSCRIPTION_TRIAL = -2;
    
    var id: String?
    var name: String?
    var email: String?
    var tokens: [String: String]?
    var lastLogin: Int?
    var subscription: Int?
    var subscriptionEnds: Int?
    var teams: [String: String]?
    
    
    override init() {
    }
    
    init(id: String) {
        self.id = id
    }
    
    init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
    
    func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict[User.ID] = id
        dict[User.NAME] = name
        dict[User.EMAIL] = email
        return dict
    }
}
