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
    
    var id: String?
    var name: String?
    var email: String?
    var tokens: [String: String]?
    
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
