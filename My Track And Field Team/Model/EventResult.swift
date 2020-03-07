//
//  EventResult.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/6/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Firebase

class EventResult: NSObject {
    static let ID = "id"
    static let NAME = "name"
    static let RESULT = "result"
    static let TIMES = "times"
    static let ATTEMPTS = "attempts"
    static let POINTS = "points"
    static let COMMENT = "comment"
    static let ATHLETE = "athlete"
    static let SPLITS = "splits"
    static let SEED = "seed"
    
    static let RESULT_DQ = "DQ"
    static let RESULT_FOUL = "FOUL"
    
    static let DQ_SEED = 99999
    static let FOUL_SEED = -1
    static let UNAVAILABLE_SEED = -2 // should never be used, but just in case of any errors
    
    static let RUN_KILO = "K Run"; // build cross country race ie: 5K Run
    static let RUN_MILE = " Mile Run"; // build cross country race ie: 2.8 Mile Run
    
    var id: String?
    var name: String?
    var result: String?
    var comment: String?
    var points: Int?
    var seed: Double?
    
    var athlete: Athlete?
    
    var splits: [String]?
    var attempts: [String]?
    var times: [String: String]?
    
    override init() {
    }
    
    init(name: String) {
        self.name = name;
    }
    
    init(name: String, result: String) {
        self.name = name;
        self.result = result;
    }
    
    init(snapshot: DataSnapshot) {
        let dict = snapshot.value as! [String: Any]
        self.id = dict[EventResult.ID] as? String ?? ""
        self.name = dict[EventResult.NAME] as? String ?? ""
        self.result = dict[EventResult.RESULT] as? String ?? ""
        self.comment = dict[EventResult.COMMENT] as? String ?? ""
        self.points = dict[EventResult.POINTS] as? Int
        self.seed = dict[EventResult.SEED] as? Double
        
        if (snapshot.hasChild(EventResult.ATHLETE)) {
            let athleteSnapshot = snapshot.childSnapshot(forPath: EventResult.ATHLETE)
            self.athlete = Athlete(snapshot: athleteSnapshot)
        }
        
        self.splits = dict[EventResult.SPLITS] as? [String]
        self.attempts = dict[EventResult.ATTEMPTS] as? [String]
        self.times = dict[EventResult.TIMES] as? [String: String]
    }
    
    func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict[EventResult.ID] = id
        dict[EventResult.NAME] = name
        if athlete != nil { // check this because relay.toDict overrides this func and doesn't have athlete field
            dict[EventResult.ATHLETE] = athlete?.toDictBasic()
        }
        return dict
    }
    
    func toDictMultiEvent() -> [String: Any] {
        var dict = [String: Any]()
        dict[EventResult.NAME] = name
        dict[EventResult.POINTS] = points
        dict[EventResult.RESULT] = result
        return dict
    }
    
    func setTrial(time: String) {
        if times == nil {
            times = [String: String]()
        }
        
        times?["trial"] = time
    }
    
    func getTrial() -> String? {
        return times?["trial"]
    }
    
    func setFinal(time: String) {
        if times == nil {
            times = [String: String]()
        }
        
        times?["final"] = time
    }
    
    func getFinal() -> String? {
        return times?["final"]
    }
    
    func isMultiEvent() -> Bool {
        return TrackEvent.isMultiEvent(name: self.name ?? "")
    }
    
    func isRelay() -> Bool {
        return TrackEvent.isRelayEvent(name: self.name ?? "")
    }
    
    // converts the time string into a Double for the seed field
    // ie: 1:36.89 to 96.89 or 9.583 to 9.583
    static func convertTimeToSeconds(time: String, decimalPlaces: Int) -> Double {
        var minutes = 0
        var seconds: Double
        let rounding = pow(10.0, Double(decimalPlaces))
        
        if time.contains(":") {
            let split = time.split(separator: ":")
            minutes = Int(split[0])!
            seconds = Double(split[1])!
        } else {
            seconds = Double(time)!
        }
        
        let seed: Double = seconds + Double(minutes * 60)
        
        return round(rounding * seed) / rounding
    }
    
    // same as above but with 2 decimal places by default
    static func convertTimeToSeconds(time: String) -> Double {
        return convertTimeToSeconds(time: time, decimalPlaces: 2)
    }
    
    // converts the measurement result string into a Double for the seed field up to 4 decimal places
    // the Double value will be in meters to be able to compare imperial and metric event results
    // ie: 10'-6" to 3.2004
    static func convertFeetToSeed(measurement: String) -> Double {
        let split = measurement.split(separator: "-")
        let feet = Double(split[0])!
        let inches = Double(split[1])!
        return ((feet + inches / 12) * 3048) / 10000
    }
    
    static func convertResultToSeed(eventResult: EventResult, isMetric: Bool) -> Double {
        return convertResultToSeed(event: eventResult.name!, result: eventResult.result!, isMetric: isMetric)
    }
    
    static func convertResultToSeed(event: String, result: String, isMetric: Bool) -> Double {
        if result == RESULT_DQ {
            return Double(DQ_SEED)
        }
        
        if result == RESULT_FOUL {
            return Double(FOUL_SEED)
        }
        
        if TrackEvent.isEventTimed(name: event) {
            return convertTimeToSeconds(time: result)
        } else if TrackEvent.isFieldEvent(name: event) {
            if isMetric { // metric result is already in meters so just cast
                return Double(result)!
            } else {
                return convertFeetToSeed(measurement: result)
            }
        } else if TrackEvent.isMultiEvent(name: event) { // points result is already an integer
            return Double(result)!
        }
        
        return Double(UNAVAILABLE_SEED)
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? EventResult {
            return self.id == object.id
        } else {
            return false
        }
    }
}
