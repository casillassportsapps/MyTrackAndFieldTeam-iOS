//
//  Record.swift
//  My Track And Field Team
//
//  Created by David Casillas on 3/29/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Firebase

class Record: NSObject {
    
    static let RECORD = "records"
    static let ID = "id"
    static let EVENT = "event"
    static let HOLDER = "holder"
    static let RESULT = "result"
    static let SEASON = "season"
    static let YEAR = "year"
    
    var id: String?
    var event: String?
    var holder: String?
    var result: String?
    var season: String?
    var year: String?
    
    
    override init() {
    }
    
    init(document: DocumentSnapshot) {
        let dict = document.data()!
        self.id = dict[Record.ID] as? String
        self.event = dict[Record.EVENT] as? String
        self.holder = dict[Record.HOLDER] as? String
        self.result = dict[Record.RESULT] as? String
        self.season = dict[Record.SEASON] as? String
        self.year = dict[Record.YEAR] as? String
    }
    
    // sorts method by default order of events
    static func sortRecords(record1: Record, record2: Record, isCrossCountry: Bool) -> Bool {
        let event1 = record1.event!
        let event2 = record2.event!
        if isCrossCountry {
            return event1.lowercased() < event2.lowercased()
        } else {
            return TrackEvent.sortEvents(event1: event1, event2: event2)
        }
    }
    
    func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict[Record.ID] = id
        dict[Record.EVENT] = event
        dict[Record.HOLDER] = holder
        dict[Record.RESULT] = result
        dict[Record.SEASON] = season
        if year != nil {
            dict[Record.YEAR] = year
        }
        return dict
    }
}
