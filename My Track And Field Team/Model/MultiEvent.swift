//
//  MultiEvent.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/7/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Firebase

class MultiEvent : EventResult {
    static let RESULTS = "multiEventResults"
    
    var multiEventResults: [String: EventResult]?
    
    override init(snapshot: DataSnapshot) {
        super.init(snapshot: snapshot)
        
        multiEventResults = [String: EventResult]()
        let multiEventEnumerator = snapshot.childSnapshot(forPath: MultiEvent.RESULTS).children
        while let multiEventSnapshot = multiEventEnumerator.nextObject() as? DataSnapshot {
            let eventResult = EventResult(snapshot: multiEventSnapshot)
            multiEventResults?[eventResult.name!] = eventResult
        }
    }

}
