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
    
    func multiEventDict() -> [String: Any] {
        var dict = [String: Any]()
        
        for eventResult in multiEventResults! {
            dict[eventResult.name!] = eventResult.toDictMultiEvent()
        }
        
        return dict
    }
    
    // the events in a multi-event are competed in a specific order
    static func sortEventsOfMultiEvent(multiEvent: String, isIndoor: Bool, isMale: Bool, isOpen: Bool, event1: EventResult, event2: EventResult) -> Bool {
        var eventList = [String]()
        
        switch multiEvent {
        case TrackEvent.PENTATHLON:
            eventList = TrackEvent.getEventsOfPentathlon(isIndoor: isIndoor, isMale: isMale, isOpenLevel: isOpen)
        case TrackEvent.HEPTATHLON:
            eventList = TrackEvent.getEventsOfHeptathlon(isMale: isMale)
        case TrackEvent.DECATHLON:
            eventList = TrackEvent.getEventsOfDecathlon(isMale: isMale)
        default:
            return false
        }
        
        let index1: Int = eventList.firstIndex(of: event1.name!)!
        let index2: Int = eventList.firstIndex(of: event2.name!)!
        
        return index1 < index2
    }

    static func initMultiEventResults(multiEvent: String, isIndoor: Bool, isMale: Bool, isOpen: Bool) -> [EventResult] {
        var eventResults = [EventResult]()
        var eventList = [String]()
        
        switch multiEvent {
        case TrackEvent.PENTATHLON:
            eventList = TrackEvent.getEventsOfPentathlon(isIndoor: isIndoor, isMale: isMale, isOpenLevel: isOpen)
        case TrackEvent.HEPTATHLON:
            eventList = TrackEvent.getEventsOfHeptathlon(isMale: isMale)
        case TrackEvent.DECATHLON:
            eventList = TrackEvent.getEventsOfDecathlon(isMale: isMale)
        default:
            return eventResults
        }
        
        for event in eventList {
            let eventResult = EventResult(name: event)
            eventResult.points = 0
            eventResults.append(eventResult)
        }
        
        return eventResults
    }
    
    class MultiEventPoints {
        
        var event: String
        var isMale: Bool
        
        init(event: String, isMale: Bool) {
            self.event = event
            self.isMale = isMale
        }
        
        func calculate(result: String) -> Int {
            if result == EventResult.RESULT_DQ || result == EventResult.RESULT_FOUL {
                return 0
            }
            
            var a: Double = 0
            var b: Double = 0
            var c: Double = 0
            
            var points: Int = 0
            var isMeasuredInCentimeters: Bool = true
            
            switch event {
            case TrackEvent.SIXTY_METERS:
                a = 58.0150
                b = 11.50
                c = 1.81
                break
            case TrackEvent.SIXTY_HURDLES:
                a = isMale ? 20.5173 : 20.0479
                b = isMale ? 15.50 : 17.00
                c = isMale ? 1.92 : 1.835
            break
            case TrackEvent.ONE_HUNDRED_METERS:
                a = isMale ? 25.4347 : 17.8570
                b = isMale ? 18.00 : 21.050
                c = 1.81
                break
            case TrackEvent.ONE_HUNDRED_HURDLES:
                a = 9.23076
                b = 26.70
                c = 1.835
                break
            case TrackEvent.ONE_HUNDRED_TEN_HURDLES:
                a = 5.74352
                b = 28.50
                c = 1.92
                break
            case TrackEvent.TWO_HUNDRED_METERS:
                a = isMale ? 5.8425 : 4.99087
                b = isMale ? 38.00 : 42.50
                c = 1.81
                break
            case TrackEvent.FOUR_HUNDRED_METERS:
                a = isMale ? 1.53775 : 1.34285
                b = isMale ? 82.00 : 91.70
                c = 1.81
                break
            case TrackEvent.EIGHT_HUNDRED_METERS:
                a = 0.11193
                b = 254.00
                c = 1.88
                break
            case TrackEvent.ONE_THOUSAND_METERS:
                a = 0.08713
                b = 305.50
                c = 1.85
                break
            case TrackEvent.FIFTEEN_HUNDRED_METERS:
                a = isMale ? 0.03768 : 0.02883
                b = isMale ? 480.00 : 535.00
                c = isMale ? 1.85 : 1.88
                break
            case TrackEvent.LONG_JUMP:
                a = isMale ? 0.14354 : 0.188807
                b = isMale ? 220.00 : 210.00
                c = isMale ? 1.40 : 1.41
            break
            case TrackEvent.HIGH_JUMP:
                a = isMale ? 0.8465 : 1.84523
                b = 75.00
                c = isMale ? 1.42 : 1.348
            break
            case TrackEvent.POLE_VAULT:
                a = isMale ? 0.2797 : 0.44125
                b = 100.00
                c = 1.35
            break
            case TrackEvent.SHOT_PUT:
                a = isMale ? 51.39 : 56.0211
                b = 1.50
                c = 1.05
                isMeasuredInCentimeters = false
            break
            case TrackEvent.DISCUS:
                a = isMale ? 12.91 : 12.3311
                b = isMale ? 4.00 : 3.00
                c = 1.10
                isMeasuredInCentimeters = false
            break
            case TrackEvent.JAVELIN:
                a = isMale ? 10.14 : 15.9803
                b = isMale ? 7.00 : 3.580
                c = isMale ? 1.08 : 1.04
                isMeasuredInCentimeters = false
            break
            default:
                return 0
            }
            
            if TrackEvent.isEventTimed(name: event) {
                // T is Time in seconds
                let T = EventResult.convertTimeToSeconds(time: result, decimalPlaces: 2)
                points = Int(a * pow((b - T), c))
            } else {
                // D is Distance in meters or centimeters
                let D = Double(result)! * (isMeasuredInCentimeters ? 100.0 : 1.0)
                points = Int(a * pow((D - b), c))
            }
            
            return points
        }
    }
}
