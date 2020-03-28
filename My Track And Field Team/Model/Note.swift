//
//  Note.swift
//  My Track And Field Team
//
//  Created by David Casillas on 3/28/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Firebase

class Note: NSObject {
    
    static let ID = "id"
    static let COMMENT = "comment"
    static let DATE_TIME = "dateTime"
    
    var id: String?
    var comment: String?
    var title: String?
    var dateTime: Int?
    
    override init() {
    }
    
    // from realtime database
    init(snapshot: DataSnapshot) {
        let dict = snapshot.value as! [String: Any]
        self.id = dict[Note.ID] as? String ?? ""
        self.comment = dict[Athlete.FIRST_NAME] as? String ?? ""
        self.dateTime = dict[Note.DATE_TIME] as? Int ?? 0
    }
    
    // you can create a Note object from the event result and it's belonging competition
    init(eventResult: EventResult, competition: Competition) {
        self.comment = eventResult.comment
        self.dateTime = competition.dateTime
        self.title = "\(competition.name!): \(eventResult.name!)"
    }
    
    func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict[Note.ID] = id
        dict[Note.COMMENT] = comment
        dict[Note.DATE_TIME] = dateTime
        return dict
    }
}
