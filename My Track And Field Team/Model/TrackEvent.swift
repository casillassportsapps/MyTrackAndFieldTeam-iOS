//
//  TrackEvent.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/8/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Firebase

class TrackEvent: NSObject {
    static let NAME = "name"
    static let ORDER = "order"
    static let TIME = "time"
    static let RESULTS = "results"
    
    var name: String?
    var order: Int?
    var time: Int?
    var deleted: Bool = false
    var results: [EventResult]?
    
    override init() {
    }
    
    init(name: String) {
        self.name = name
    }
    
    init(snapshot: DataSnapshot) {
        let dict = snapshot.value as! [String: Any]
        self.name = dict[TrackEvent.NAME] as? String ?? ""
        self.order = dict[TrackEvent.ORDER] as? Int
        self.time = dict[TrackEvent.TIME] as? Int
        
        if snapshot.hasChild(TrackEvent.RESULTS) {
            results = [EventResult]()
            
            let resultsSnapshot = snapshot.childSnapshot(forPath: TrackEvent.RESULTS)
            let resultsEnumerator = resultsSnapshot.children
            while let eventResultSnapshot = resultsEnumerator.nextObject() as? DataSnapshot {
                let eventResult = EventResult(snapshot: eventResultSnapshot)
                if eventResult.athlete != nil { // normal a event or multi-event
                    if eventResultSnapshot.hasChild(MultiEvent.RESULTS) { // multi-event
                        let multiEvent = MultiEvent(snapshot: eventResultSnapshot)
                        results?.append(multiEvent)
                    } else {
                        results?.append(eventResult)
                    }
                } else { // must be a relay (relay does not have athlete node)
                    let relay = Relay(snapshot: eventResultSnapshot)
                    results?.append(relay)
                }
            }
            
            let isTimed = TrackEvent.isEventTimed(name: name!) as Bool
            results = EventResult.sortResults(results: results!, isTimed: isTimed)
        }
    }
    
    func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict[TrackEvent.NAME] = name
        dict[TrackEvent.ORDER] = order
        return dict
     }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? TrackEvent {
            return self.name == object.name
        } else {
            return false
        }
    }
    
    override var hash: Int {
        return self.name.hashValue
    }
    
    // determines if an event is timed
    static func isEventTimed(name: String) -> Bool {
        let events = getTimedEvents()
        return events.contains(name)
    }
    
    // array all timed events
    static func getTimedEvents() -> [String] {
        var events = [String]()
        events.append(contentsOf: getWalkingEvents())
        events.append(contentsOf: getRunningEvents())
        events.append(contentsOf: getRelayEvents())
        events.append(TWELVE_HUNDRED_METERS) // // not a normal event, used only in distance medley relay
        return events
    }
    
    // determines if an event is timed with seconds and milliseconds (ie: 9.52, 72.39, up to 3 decimal places)
    // if event is not listed then the event is timed with minutes, seconds, and milliseconds (ie: 2:15.68)
    static func isEventTimedInSeconds(name: String) -> Bool {
        let events = getEventsTimedInSeconds()
        return events.contains(name)
    }
    
    // array of events timed in seconds
    static func getEventsTimedInSeconds() -> [String] {
        var events = [String]()
        events.append(FIFTY_METERS)
        events.append(FIFTY_METER_HURDLES)
        events.append(FIFTY_FIVE_METERS)
        events.append(FIFTY_FIVE_HURDLES)
        events.append(SIXTY_METERS)
        events.append(SIXTY_HURDLES)
        events.append(ONE_HUNDRED_METERS)
        events.append(ONE_HUNDRED_HURDLES)
        events.append(ONE_HUNDRED_TEN_HURDLES)
        events.append(TWO_HUNDRED_METERS)
        events.append(TWO_HUNDRED_HURDLES)
        events.append(THREE_HUNDRED_METERS)
        events.append(THREE_HUNDRED_HURDLES)
        events.append(FOUR_HUNDRED_METERS)
        events.append(FOUR_HUNDRED_HURDLES)
        events.append(FIVE_HUNDRED_METERS)
        events.append(FOUR_BY_ONE_HUNDRED)
        events.append(SHUTTLE_HURDLE_RELAY_55)
        events.append(SHUTTLE_HURDLE_RELAY_60)
        events.append(SHUTTLE_HURDLE_RELAY_100)
        events.append(SHUTTLE_HURDLE_RELAY_110)
        return events
    }
    
    // determine if an event can display a trial and/or final time
    static func isEventWithTrialFinal(name: String) -> Bool {
        let events = getEventsWithTrialFinal()
        return events.contains(name)
    }
    
    // array of events which can display a trial and/or final time
    static func getEventsWithTrialFinal() -> [String] {
        var events = [String]()
        events.append(FIFTY_METERS)
        events.append(FIFTY_METER_HURDLES)
        events.append(FIFTY_FIVE_METERS)
        events.append(FIFTY_FIVE_HURDLES)
        events.append(SIXTY_METERS)
        events.append(SIXTY_HURDLES)
        events.append(ONE_HUNDRED_METERS)
        events.append(ONE_HUNDRED_HURDLES)
        events.append(ONE_HUNDRED_TEN_HURDLES)
        events.append(TWO_HUNDRED_METERS)
        events.append(TWO_HUNDRED_HURDLES)
        events.append(THREE_HUNDRED_METERS)
        events.append(THREE_HUNDRED_HURDLES)
        events.append(FOUR_HUNDRED_METERS)
        events.append(FOUR_HUNDRED_HURDLES)
        events.append(FIVE_HUNDRED_METERS)
        return events
    }
    
    // determines if an event can have time splits (either per lap or distance)
    static func isEventThatSplits(isCrossCountry: Bool, name: String) -> Bool {
        let events = getEventsThatSplit()
        return isCrossCountry || events.contains(name)
    }
    
    // array of events that can split
    static func getEventsThatSplit() -> [String] {
        var events = [String]()
        events.append(SIX_HUNDRED_METERS)
        events.append(EIGHT_HUNDRED_METERS)
        events.append(ONE_THOUSAND_METERS)
        events.append(FIFTEEN_HUNDRED_METERS)
        events.append(SIXTEEN_HUNDRED_METERS)
        events.append(ONE_MILE)
        events.append(TWO_THOUSAND_STEEPLE)
        events.append(THREE_THOUSAND_METERS)
        events.append(THREE_THOUSAND_STEEPLE)
        events.append(THIRTY_TWO_HUNDRED_METERS)
        events.append(TWO_MILE)
        events.append(FIVE_THOUSAND_METERS)
        events.append(TEN_THOUSAND_METERS)
        return events
    }
    
    // determines if event is a running event
    static func isRunningEvent(name: String) -> Bool {
        let events = getRunningEvents()
        return events.contains(name)
    }
    
    // array of all running events
    static func getRunningEvents() -> [String] {
        var events = [String]()
        events.append(FIFTY_METERS)
        events.append(FIFTY_METER_HURDLES)
        events.append(FIFTY_FIVE_METERS)
        events.append(FIFTY_FIVE_HURDLES)
        events.append(SIXTY_METERS)
        events.append(SIXTY_HURDLES)
        events.append(ONE_HUNDRED_METERS)
        events.append(ONE_HUNDRED_HURDLES)
        events.append(ONE_HUNDRED_TEN_HURDLES)
        events.append(TWO_HUNDRED_METERS)
        events.append(TWO_HUNDRED_HURDLES)
        events.append(THREE_HUNDRED_METERS)
        events.append(THREE_HUNDRED_HURDLES)
        events.append(FOUR_HUNDRED_METERS)
        events.append(FOUR_HUNDRED_HURDLES)
        events.append(FIVE_HUNDRED_METERS)
        events.append(SIX_HUNDRED_METERS)
        events.append(EIGHT_HUNDRED_METERS)
        events.append(ONE_THOUSAND_METERS)
        events.append(FIFTEEN_HUNDRED_METERS)
        events.append(SIXTEEN_HUNDRED_METERS)
        events.append(ONE_MILE)
        events.append(TWO_THOUSAND_STEEPLE)
        events.append(THREE_THOUSAND_METERS)
        events.append(THREE_THOUSAND_STEEPLE)
        events.append(THIRTY_TWO_HUNDRED_METERS)
        events.append(TWO_MILE)
        events.append(FIVE_THOUSAND_METERS)
        events.append(TEN_THOUSAND_METERS)
        return events
    }
    
    // array of all running events for a specific season or gender
    static func getRunningEvents(isIndoor: Bool, isMale: Bool) -> [String] {
        var events = [String]()
        if isIndoor {
            events.append(FIFTY_METERS)
            events.append(FIFTY_METER_HURDLES)
            events.append(FIFTY_FIVE_METERS)
            events.append(FIFTY_FIVE_HURDLES)
            events.append(SIXTY_METERS)
            events.append(SIXTY_HURDLES)
            events.append(TWO_HUNDRED_METERS)
            events.append(THREE_HUNDRED_METERS)
            events.append(FOUR_HUNDRED_METERS)
            events.append(FOUR_HUNDRED_HURDLES)
            events.append(FIVE_HUNDRED_METERS)
            events.append(SIX_HUNDRED_METERS)
            events.append(EIGHT_HUNDRED_METERS)
            events.append(ONE_THOUSAND_METERS)
            events.append(FIFTEEN_HUNDRED_METERS)
            events.append(SIXTEEN_HUNDRED_METERS)
            events.append(ONE_MILE)
            events.append(THREE_THOUSAND_METERS)
            events.append(THIRTY_TWO_HUNDRED_METERS)
            events.append(TWO_MILE)
            events.append(FIVE_THOUSAND_METERS)
            events.append(TEN_THOUSAND_METERS)
        } else {
            events.append(ONE_HUNDRED_METERS)
            events.append(isMale ? ONE_HUNDRED_TEN_HURDLES : ONE_HUNDRED_HURDLES)
            events.append(TWO_HUNDRED_METERS)
            events.append(TWO_HUNDRED_HURDLES)
            events.append(THREE_HUNDRED_METERS)
            events.append(THREE_HUNDRED_HURDLES)
            events.append(FOUR_HUNDRED_METERS)
            events.append(FOUR_HUNDRED_HURDLES)
            events.append(FIVE_HUNDRED_METERS)
            events.append(SIX_HUNDRED_METERS)
            events.append(EIGHT_HUNDRED_METERS)
            events.append(ONE_THOUSAND_METERS)
            events.append(FIFTEEN_HUNDRED_METERS)
            events.append(SIXTEEN_HUNDRED_METERS)
            events.append(ONE_MILE)
            events.append(TWO_THOUSAND_STEEPLE)
            events.append(THREE_THOUSAND_METERS)
            events.append(THREE_THOUSAND_STEEPLE)
            events.append(THIRTY_TWO_HUNDRED_METERS)
            events.append(TWO_MILE)
            events.append(FIVE_THOUSAND_METERS)
            events.append(TEN_THOUSAND_METERS)
        }
        
        return events
    }
    
    // determines if an event is a walking event
    static func isWalkEvent(name: String) -> Bool {
        let events = getWalkingEvents()
        return events.contains(name)
    }
    
    // array of all walking events
    static func getWalkingEvents() -> [String] {
        var events = [String]()
        events.append(FIFTEEN_HUNDRED_METER_WALK)
        events.append(SIXTEEN_HUNDRED_METER_WALK)
        events.append(THREE_THOUSAND_METER_WALK)
        events.append(FIVE_THOUSAND_METER_WALK)
        return events
    }
    
    // determines if an event is a relay (relay always has 4 legs (athletes) running)
    static func isRelayEvent(name: String) -> Bool {
        let events = getRelayEvents()
        return events.contains(name)
    }
    
    // array of all relay events
    static func getRelayEvents() -> [String] {
        var events = [String]()
        events.append(FOUR_BY_ONE_HUNDRED)
        events.append(FOUR_BY_TWO_HUNDRED)
        events.append(FOUR_BY_FOUR_HUNDRED)
        events.append(FOUR_BY_EIGHT_HUNDRED)
        events.append(FOUR_BY_FIFTEEN_HUNDRED)
        events.append(FOUR_BY_SIXTEEN_HUNDRED)
        events.append(EIGHT_HUNDRED_MEDLEY_RELAY)
        events.append(SIXTEEN_HUNDRED_MEDLEY_RELAY)
        events.append(SWEDISH_MEDLEY_RELAY)
        events.append(DISTANCE_MEDLEY_RELAY)
        events.append(SHUTTLE_HURDLE_RELAY_55)
        events.append(SHUTTLE_HURDLE_RELAY_60)
        events.append(SHUTTLE_HURDLE_RELAY_100)
        events.append(SHUTTLE_HURDLE_RELAY_110)
        return events
    }
    
    // the 4 events in a 4x100m relay (each split/leg is 100m)
    static func getEventsOfFourByOne() -> [String] {
        var events = [String]()
        for _ in 0...3 {
            events.append(ONE_HUNDRED_METERS)
        }
        return events
    }
    
    // the 4 events in a 4x200m relay
    static func getEventsOfFourByTwo() -> [String] {
        var events = [String]()
        for _ in 0...3 {
            events.append(TWO_HUNDRED_METERS)
        }
        return events
    }
    
    // the 4 events in a 4x400m relay
    static func getEventsOfFourByFour() -> [String] {
        var events = [String]()
        for _ in 0...3 {
            events.append(FOUR_HUNDRED_METERS)
        }
        return events
    }
    
    // the 4 events in a 4x800m relay
    static func getEventsOfFourByEight() -> [String] {
        var events = [String]()
        for _ in 0...3 {
            events.append(EIGHT_HUNDRED_METERS)
        }
        return events
    }
    
    // the 4 events in a 4x1500m relay
    static func getEventsOfFourByFifteen() -> [String] {
        var events = [String]()
        for _ in 0...3 {
            events.append(FIFTEEN_HUNDRED_METERS)
        }
        return events
    }
    
    // the 4 events in a 4x1600m relay
    static func getEventsOfFourBySixteen() -> [String] {
        var events = [String]()
        for _ in 0...3 {
            events.append(SIXTEEN_HUNDRED_METERS)
        }
        return events
    }
    
    // the 4 events in a shuttle hurdle relay
    static func getEventsOfSHR(isIndoor: Bool, isMale: Bool, is55: Bool) -> [String] {
        var events = [String]()
        for _ in 0...3 {
            if isIndoor { // indoor you can select 4x55H and/or 4x60H
                if is55 {
                    events.append(FIFTY_FIVE_HURDLES)
                } else {
                    events.append(SIXTY_HURDLES)
                }
            } else {
                if isMale { // male is 4x110H
                    events.append(ONE_HUNDRED_TEN_HURDLES)
                } else { // female is 4x100H
                    events.append(ONE_HUNDRED_HURDLES)
                }
            }
        }
        return events
    }
    
    //medley relays have 4 events, usually all different distances
    // the 4 events of 800m medley relay
    static func getEventOf800mMedley() -> [String] {
        var events = [String]()
        events.append(ONE_HUNDRED_METERS)
        events.append(ONE_HUNDRED_METERS)
        events.append(TWO_HUNDRED_METERS)
        events.append(FOUR_HUNDRED_METERS)
        return events
    }
    
    // the 4 events of swedish medley relay
    static func getEventOfSwedishMedley() -> [String] {
        var events = [String]()
        events.append(ONE_HUNDRED_METERS)
        events.append(TWO_HUNDRED_METERS)
        events.append(THREE_HUNDRED_METERS)
        events.append(FOUR_HUNDRED_METERS)
        return events
    }
    
    // the 4 events of 1600m medley relay
    static func getEventOf1600mMedley() -> [String] {
        var events = [String]()
        events.append(TWO_HUNDRED_METERS)
        events.append(TWO_HUNDRED_METERS)
        events.append(FOUR_HUNDRED_METERS)
        events.append(EIGHT_HUNDRED_METERS)
        return events
    }
    
    // the 4 events of distance medley relay
    static func getEventOfDistanceMedley() -> [String] {
        var events = [String]()
        events.append(TWELVE_HUNDRED_METERS)
        events.append(FOUR_HUNDRED_METERS)
        events.append(EIGHT_HUNDRED_METERS)
        events.append(SIXTEEN_HUNDRED_METERS)
        return events
    }
    
    // determines if event is a multi-event
    static func isMultiEvent(name: String) -> Bool {
        var events = getMultiEvents()
        events.append(PENTATHLON_INDOOR)
        events.append(PENTATHLON_OUTDOOR)
        return events.contains(name)
    }
    
    // array of multi-events
    static func getMultiEvents() -> [String] {
        var events = [String]()
        events.append(PENTATHLON)
        events.append(HEPTATHLON)
        events.append(DECATHLON)
        return events
    }
    
    // array of multi-events depending on whether season is indoor or outdoor and team is male or female
    static func getMultiEvents(isIndoor: Bool, isMale: Bool) -> [String] {
        var events = [String]()
        events.append(PENTATHLON)
        
        if isIndoor {
            if isMale {
                events.append(HEPTATHLON)
            }
        } else {
            if !isMale {
                events.append(HEPTATHLON)
            }
            events.append(DECATHLON)
        }
        
        return events
    }
    
    // array of events of the multi-event pentathlon, which is different per season, gender, and level
    static func getEventsOfPentathlon(isIndoor: Bool, isMale: Bool, isOpenLevel: Bool) -> [String] {
        var events = [String]()
        
        if isIndoor {
            if isMale {
                events.append(SIXTY_HURDLES)
                events.append(LONG_JUMP)
                events.append(SHOT_PUT)
                events.append(HIGH_JUMP)
                events.append(ONE_THOUSAND_METERS)
            } else {
                events.append(SIXTY_HURDLES)
                events.append(HIGH_JUMP)
                events.append(SHOT_PUT)
                events.append(LONG_JUMP)
                events.append(EIGHT_HUNDRED_METERS)
            }
        } else {
            if isMale {
                if isOpenLevel {
                    events.append(LONG_JUMP)
                    events.append(JAVELIN)
                    events.append(TWO_HUNDRED_METERS)
                    events.append(DISCUS)
                    events.append(FIFTEEN_HUNDRED_METERS)
                } else {
                    events.append(ONE_HUNDRED_TEN_HURDLES)
                    events.append(SHOT_PUT)
                    events.append(HIGH_JUMP)
                    events.append(LONG_JUMP)
                    events.append(FIFTEEN_HUNDRED_METERS)
                }
            } else {
                events.append(ONE_HUNDRED_HURDLES)
                events.append(SHOT_PUT)
                events.append(HIGH_JUMP)
                events.append(LONG_JUMP)
                events.append(EIGHT_HUNDRED_METERS)
            }
        }
        
        return events
    }
    
    // array of events of heptathlon, determines if male (indoor season) or female (outdoor season)
    static func getEventsOfHeptathlon(isMale: Bool) -> [String] {
        var events = [String]()
        if isMale {
            events.append(SIXTY_METERS)
            events.append(LONG_JUMP)
            events.append(SHOT_PUT)
            events.append(HIGH_JUMP)
            events.append(SIXTY_HURDLES)
            events.append(POLE_VAULT)
            events.append(ONE_THOUSAND_METERS)
        } else {
            events.append(ONE_HUNDRED_HURDLES)
            events.append(HIGH_JUMP)
            events.append(SHOT_PUT)
            events.append(TWO_HUNDRED_METERS)
            events.append(LONG_JUMP)
            events.append(JAVELIN)
            events.append(EIGHT_HUNDRED_METERS)
        }
        
        return events
    }
    
    // array of events of decathlon, depending if male or female
    static func getEventsOfDecathlon(isMale: Bool) -> [String] {
        var events = [String]()
        if isMale {
            events.append(ONE_HUNDRED_METERS)
            events.append(LONG_JUMP)
            events.append(SHOT_PUT)
            events.append(HIGH_JUMP)
            events.append(FOUR_HUNDRED_METERS)
            events.append(ONE_HUNDRED_TEN_HURDLES)
            events.append(DISCUS)
            events.append(POLE_VAULT)
            events.append(JAVELIN)
            events.append(FIFTEEN_HUNDRED_METERS)
        } else {
            events.append(ONE_HUNDRED_METERS)
            events.append(DISCUS)
            events.append(POLE_VAULT)
            events.append(JAVELIN)
            events.append(FOUR_HUNDRED_METERS)
            events.append(ONE_HUNDRED_HURDLES)
            events.append(LONG_JUMP)
            events.append(SHOT_PUT)
            events.append(HIGH_JUMP)
            events.append(FIFTEEN_HUNDRED_METERS)
        }
        
        return events
    }
    
    // events which result in measurement type points
    static func getEventsThatResultInPoints() -> [String] {
        var events = getMultiEvents()
        events.append(PENTATHLON_INDOOR)
        events.append(PENTATHLON_OUTDOOR)
        return events
    }
    
    // determines if event is a field event
    static func isFieldEvent(name: String) -> Bool {
        let events = getFieldEvents()
        return events.contains(name)
    }
    
    // determines if event can have attempts
    static func isFieldEventWithAttempts(name: String) -> Bool {
        let events = getEventsThatResultInDistance()
        return events.contains(name)
    }
    
    // array of all field events
    static func getFieldEvents() -> [String] {
        var events = [String]()
        events.append(HIGH_JUMP)
        events.append(LONG_JUMP)
        events.append(TRIPLE_JUMP)
        events.append(POLE_VAULT)
        events.append(SHOT_PUT)
        events.append(DISCUS)
        events.append(JAVELIN)
        events.append(HAMMER)
        events.append(WEIGHT)
        return events
    }
    
    // array of field events depending on season
    static func getFieldEvents(isIndoor: Bool) -> [String] {
        var events = [String]()
        events.append(HIGH_JUMP)
        events.append(LONG_JUMP)
        events.append(TRIPLE_JUMP)
        events.append(POLE_VAULT)
        events.append(SHOT_PUT)

        if isIndoor {
            events.append(WEIGHT)
        } else {
            events.append(DISCUS)
            events.append(JAVELIN)
            events.append(HAMMER)
        }
        
        return events
    }
    
    // events which result in measurement type height
    static func getEventsThatResultInHeight() -> [String] {
        var events = [String]()
        events.append(HIGH_JUMP)
        events.append(POLE_VAULT)
        return events
    }
    
    // events which result in measurement type distance
    static func getEventsThatResultInDistance() -> [String] {
        var events = [String]()
        events.append(LONG_JUMP)
        events.append(TRIPLE_JUMP)
        events.append(SHOT_PUT)
        events.append(DISCUS)
        events.append(JAVELIN)
        events.append(HAMMER)
        events.append(WEIGHT)
        return events
    }
    
    // outputs which measurement type an event measures to
    static func getEventMeasurementType(event: String) -> String {
        var events = getEventsThatResultInHeight();
        if (events.contains(event)) {
            return RESULT_TYPE_HEIGHT
        }
        
        events = getEventsThatResultInDistance();
        if (events.contains(event)) {
            return RESULT_TYPE_DISTANCE
        }
        
        events = getEventsThatResultInPoints();
        if (events.contains(event)) {
            return RESULT_TYPE_POINTS
        }
        
        return RESULT_TYPE_TIME
    }
    
    // field event measured with feet, inches, and quarterinches (ie: 5'-5.5", 16'-11.25")
    // if event is not listed then the event is measured with feet and inches (ie: 5'-0", 231'-2")
    static func isMeasuredInQuarterInches(name: String) -> Bool {
        let events = getEventsMeasuredInQuarterInches()
        return events.contains(name)
    }
    
    // array of field events which measure with quarterinches
    static func getEventsMeasuredInQuarterInches() -> [String] {
        var events = [String]()
        events.append(HIGH_JUMP)
        events.append(LONG_JUMP)
        events.append(TRIPLE_JUMP)
        events.append(POLE_VAULT)
        events.append(SHOT_PUT)
        events.append(WEIGHT)
        return events
    }
    
    // outputs the type of track event
    static func getTrackEventType(event: String) -> String {
        if isWalkEvent(name: event) {
            return TYPE_WALKING
        } else if isMultiEvent(name: event) {
            return TYPE_MULTI
        } else if isFieldEvent(name: event) {
            return TYPE_FIELD
        } else if isRelayEvent(name: event) {
            return TYPE_RELAY
        } else {
            return TYPE_RUNNING
        }
    }
    
    // outputs base event pentathlon from an indoor or outdoor penatathlon
    static func displayEventNameChange(event: String) -> String {
        switch event {
        case PENTATHLON_INDOOR, PENTATHLON_OUTDOOR:
            return PENTATHLON
        default:
            return event
        }
    }
    
    // outputs which pentathlon for event name for field 'name' in event result
    static func getEventNameBySeason(event: String, isIndoor: Bool) -> String {
        if event == PENTATHLON {
            if isIndoor {
                return PENTATHLON_INDOOR
            } else {
                return PENTATHLON_OUTDOOR
            }
        }
        return event
    }
    
    // array of all events, this is the default order of events (used in stats to display order of stats)
    static func getAllEvents() -> [String] {
        var events = [String]()
        events.append(FIFTY_METERS)
        events.append(FIFTY_METER_HURDLES)
        events.append(FIFTY_FIVE_METERS)
        events.append(FIFTY_FIVE_HURDLES)
        events.append(SIXTY_METERS)
        events.append(SIXTY_HURDLES)
        events.append(ONE_HUNDRED_METERS)
        events.append(ONE_HUNDRED_HURDLES)
        events.append(ONE_HUNDRED_TEN_HURDLES)
        events.append(TWO_HUNDRED_METERS)
        events.append(TWO_HUNDRED_HURDLES)
        events.append(THREE_HUNDRED_METERS)
        events.append(THREE_HUNDRED_HURDLES)
        events.append(FOUR_HUNDRED_METERS)
        events.append(FOUR_HUNDRED_HURDLES)
        events.append(FIVE_HUNDRED_METERS)
        events.append(SIX_HUNDRED_METERS)
        events.append(EIGHT_HUNDRED_METERS)
        events.append(ONE_THOUSAND_METERS)
        events.append(TWELVE_HUNDRED_METERS)
        events.append(FIFTEEN_HUNDRED_METERS)
        events.append(SIXTEEN_HUNDRED_METERS)
        events.append(ONE_MILE)
        events.append(TWO_THOUSAND_STEEPLE)
        events.append(THREE_THOUSAND_METERS)
        events.append(THREE_THOUSAND_STEEPLE)
        events.append(THIRTY_TWO_HUNDRED_METERS)
        events.append(TWO_MILE)
        events.append(FIVE_THOUSAND_METERS)
        events.append(TEN_THOUSAND_METERS)
        events.append(FIFTEEN_HUNDRED_METER_WALK)
        events.append(SIXTEEN_HUNDRED_METER_WALK)
        events.append(THREE_THOUSAND_METER_WALK)
        events.append(FIVE_THOUSAND_METER_WALK)
        events.append(HIGH_JUMP)
        events.append(LONG_JUMP)
        events.append(TRIPLE_JUMP)
        events.append(POLE_VAULT)
        events.append(SHOT_PUT)
        events.append(DISCUS)
        events.append(JAVELIN)
        events.append(HAMMER)
        events.append(WEIGHT)
        events.append(FOUR_BY_ONE_HUNDRED)
        events.append(FOUR_BY_TWO_HUNDRED)
        events.append(FOUR_BY_FOUR_HUNDRED)
        events.append(FOUR_BY_EIGHT_HUNDRED)
        events.append(FOUR_BY_FIFTEEN_HUNDRED)
        events.append(FOUR_BY_SIXTEEN_HUNDRED)
        events.append(SHUTTLE_HURDLE_RELAY_55)
        events.append(SHUTTLE_HURDLE_RELAY_60)
        events.append(SHUTTLE_HURDLE_RELAY_100)
        events.append(SHUTTLE_HURDLE_RELAY_110)
        events.append(EIGHT_HUNDRED_MEDLEY_RELAY)
        events.append(SIXTEEN_HUNDRED_MEDLEY_RELAY)
        events.append(SWEDISH_MEDLEY_RELAY)
        events.append(DISTANCE_MEDLEY_RELAY)
        events.append(PENTATHLON)
        events.append(PENTATHLON_INDOOR)
        events.append(PENTATHLON_OUTDOOR)
        events.append(HEPTATHLON)
        events.append(DECATHLON)
        return events
    }
    
    // index of event in allEvents array
    static func getIndex(event: String) -> Int {
        return getAllEvents().firstIndex(of: event)!
    }
    
    // sorts method for default order of events
    static func sortEvents(event1: String, event2: String) -> Bool {
        return getIndex(event: event1) < getIndex(event: event2)
    }
    
    // raw string values of all track event names
    static let FIFTY_METERS = "50m"
    static let FIFTY_METER_HURDLES = "50H"
    static let FIFTY_FIVE_METERS = "55m"
    static let FIFTY_FIVE_HURDLES = "55H"
    static let SIXTY_METERS = "60m"
    static let SIXTY_HURDLES = "60H"
    static let ONE_HUNDRED_METERS = "100m"
    static let ONE_HUNDRED_HURDLES = "100H"
    static let ONE_HUNDRED_TEN_HURDLES = "110H"
    static let TWO_HUNDRED_METERS = "200m"
    static let TWO_HUNDRED_HURDLES = "200H"
    static let THREE_HUNDRED_METERS = "300m"
    static let THREE_HUNDRED_HURDLES = "300H"
    static let FOUR_HUNDRED_METERS = "400m"
    static let FOUR_HUNDRED_HURDLES = "400H"
    static let FIVE_HUNDRED_METERS = "500m"
    static let SIX_HUNDRED_METERS = "600m"
    static let EIGHT_HUNDRED_METERS = "800m"
    static let ONE_THOUSAND_METERS = "1000m"
    static let TWELVE_HUNDRED_METERS = "1200m" // not a normal event, used only in distance medley relay
    static let FIFTEEN_HUNDRED_METERS = "1500m"
    static let SIXTEEN_HUNDRED_METERS = "1600m"
    static let ONE_MILE = "1 Mile"
    static let TWO_THOUSAND_STEEPLE = "2000m Steeplechase"
    static let THREE_THOUSAND_METERS = "3000m"
    static let THREE_THOUSAND_STEEPLE = "3000m Steeplechase"
    static let THIRTY_TWO_HUNDRED_METERS = "3200m"
    static let TWO_MILE = "2 Mile"
    static let FIVE_THOUSAND_METERS = "5000m"
    static let TEN_THOUSAND_METERS = "10000m"
    static let FIFTEEN_HUNDRED_METER_WALK = "1500m Walk"
    static let SIXTEEN_HUNDRED_METER_WALK = "1600m Walk"
    static let THREE_THOUSAND_METER_WALK = "3000m Walk"
    static let FIVE_THOUSAND_METER_WALK = "5000m Walk"
    static let HIGH_JUMP = "High Jump"
    static let LONG_JUMP = "Long Jump"
    static let TRIPLE_JUMP = "Triple Jump"
    static let POLE_VAULT = "Pole Vault"
    static let SHOT_PUT = "Shot Put"
    static let DISCUS = "Discus"
    static let JAVELIN = "Javelin"
    static let HAMMER = "Hammer"
    static let WEIGHT = "Weight"
    static let FOUR_BY_ONE_HUNDRED = "4x100m"
    static let FOUR_BY_TWO_HUNDRED = "4x200m"
    static let FOUR_BY_FOUR_HUNDRED = "4x400m"
    static let FOUR_BY_EIGHT_HUNDRED = "4x800m"
    static let FOUR_BY_FIFTEEN_HUNDRED = "4x1500m"
    static let FOUR_BY_SIXTEEN_HUNDRED = "4x1600m"
    static let EIGHT_HUNDRED_MEDLEY_RELAY = "800m Medley Relay"
    static let SIXTEEN_HUNDRED_MEDLEY_RELAY = "1600m Medley Relay"
    static let SWEDISH_MEDLEY_RELAY = "Swedish Medley Relay"
    static let DISTANCE_MEDLEY_RELAY = "Distance Medley Relay"
    static let SHUTTLE_HURDLE_RELAY_55 = "4x55H" // indoor season only
    static let SHUTTLE_HURDLE_RELAY_60 = "4x60H" // indoor season only
    static let SHUTTLE_HURDLE_RELAY_100 = "4x100H" // outdoor season, female only
    static let SHUTTLE_HURDLE_RELAY_110 = "4x110H" // outdoor season, male only
    static let PENTATHLON = "Pentathlon"
    static let PENTATHLON_INDOOR = "Pentathlon (Indoor)"
    static let PENTATHLON_OUTDOOR = "Pentathlon (Outdoor)"
    static let HEPTATHLON = "Heptathlon"
    static let DECATHLON = "Decathlon"
    
    static let TYPE_RUNNING = "Running"
    static let TYPE_WALKING = "Walking"
    static let TYPE_FIELD = "Field"
    static let TYPE_RELAY = "Relay"
    static let TYPE_MULTI = "Multi Events"
    
    static let RESULT_TYPE_TIME = "Time"
    static let RESULT_TYPE_DISTANCE = "Distance"
    static let RESULT_TYPE_HEIGHT = "Height"
    static let RESULT_TYPE_POINTS = "Points"
}
