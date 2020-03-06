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
    
    var multiEventResults: [EventResult]?
    
    override init() {
        super.init()
    }
    
    override init(snapshot: DataSnapshot) {
        super.init(snapshot: snapshot)
        
        multiEventResults = [EventResult]()
        let multiEventEnumerator = snapshot.childSnapshot(forPath: MultiEvent.RESULTS).children
        while let multiEventSnapshot = multiEventEnumerator.nextObject() as? DataSnapshot {
            let eventResult = EventResult(snapshot: multiEventSnapshot)
            multiEventResults?.append(eventResult)
        }
    }
    
    override func toDict() -> [String: Any] {
        var dict = super.toDict()
        
        var resultsDict = [String: Any]()
        for eventResult in multiEventResults! {
            resultsDict[eventResult.name!] = eventResult.toDictMultiEvent()
        }
        
        dict[MultiEvent.RESULTS] = resultsDict
        return dict
    }

    static func getMultiEventList(event: String, isIndoor: Bool, isMale: Bool, isOpen: Bool) -> [EventResult] {
        var eventResults = [EventResult]()
        var eventList = [String]()
        
        switch event {
        case TrackEvent.PENTATHLON:
            eventList = TrackEvent.getEventsOfPentathlon(isIndoor: isIndoor, isMale: isMale, isOpenLevel: isOpen)
        case TrackEvent.HEPTATHLON:
            eventList = TrackEvent.getEventsOfHeptathlon(isMale: isMale)
        case TrackEvent.DECATHLON:
            eventList = TrackEvent.getEventsOfDecathlon(isMale: isMale)
        default:
            return eventResults
        }
        
        for name in eventList {
            let eventResult = EventResult(name: name)
            eventResults.append(eventResult)
        }
        
        return eventResults
    }
}
