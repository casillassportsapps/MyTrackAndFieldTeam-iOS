//
//  Score.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/9/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Firebase

class Score: NSObject {
    static let ORDER = "order"
    static let NAME = "name"
    static let MY_PLACES = "myPlaces"
    static let OPPONENT_PLACES = "opponentPlaces"
    static let FIRST_PLACE = "firstPlace"
    static let SECOND_PLACE = "secondPlace"
    static let THIRD_PLACE = "thirdPlace"
    
    static let DEFAULT_XC_PLACES = "0-0-0-0-0-0-0"
    
    static let POINTS_FIRST = 5.0
    static let POINTS_SECOND = 3.0
    static let POINTS_THIRD = 1.0
    
    static let NO_SCORE = -1
    static let TIE = 0
    static let MY_TEAM = 1
    static let OPPONENT = 2
    
    static let EVENT_SCORING = [MY_TEAM, OPPONENT, TIE, NO_SCORE]
    
    var order: Int?
    var name: String?
    var myPlaces: String?
    var opponentPlaces: String?
    var firstPlace: Int?
    var secondPlace: Int?
    var thirdPlace: Int?
    var myPoints: Double?
    var opponentPoints: Double?
    
    override init() {
    }
    
    init(name: String) {
        self.name = name
    }
    
    init(snapshot: DataSnapshot, isCrossCountry: Bool) {
        let dict = snapshot.value as! [String: Any]
        if isCrossCountry {
            self.myPlaces = dict[Score.MY_PLACES] as? String ?? Score.DEFAULT_XC_PLACES
            self.opponentPlaces = dict[Score.OPPONENT_PLACES] as? String ?? Score.DEFAULT_XC_PLACES
            
            let points = Score.calculatePointsInXC(myPlaces: self.myPlaces!, opponentPlaces: self.opponentPlaces!)
            self.myPoints = Double(points[0])
            self.opponentPoints = Double(points[1])
        } else {
            self.name = dict[Score.NAME] as? String
            self.order = dict[Score.ORDER] as? Int
            self.firstPlace = dict[Score.FIRST_PLACE] as? Int ?? Score.NO_SCORE
            self.secondPlace = dict[Score.SECOND_PLACE] as? Int ?? Score.NO_SCORE
            self.thirdPlace = dict[Score.THIRD_PLACE] as? Int ?? Score.NO_SCORE
            
            let points = Score.calculatePointsInTrack(firstPlace: self.firstPlace!, secondPlace: self.secondPlace!, thirdPlace: self.thirdPlace!)
            self.myPoints = points[0]
            self.opponentPoints = points[1]
        }
    }
    
    static func calculatePointsInTrack(firstPlace: Int, secondPlace: Int, thirdPlace: Int) -> [Double] {
        var points: [Double] = []
        var myPoints = 0.0
        var opponentPoints = 0.0
        
        if firstPlace == MY_TEAM {
            myPoints += 5.0
        } else if (firstPlace == OPPONENT) {
            opponentPoints += 5.0
        } else if (firstPlace == TIE) {
            myPoints = 2.5
            opponentPoints = 2.5
        }
        
        if secondPlace == MY_TEAM {
            myPoints += 3
        } else if (secondPlace == OPPONENT) {
            opponentPoints += 3
        } else if (secondPlace == TIE) {
            myPoints = 1.5
            opponentPoints = 1.5
        }
        
        if thirdPlace == MY_TEAM {
            myPoints += 1
        } else if (thirdPlace == OPPONENT) {
            opponentPoints += 1
        } else if (thirdPlace == TIE) {
            myPoints = 0.5
            opponentPoints = 0.5
        }
        
        points[0] = myPoints
        points[1] = opponentPoints
        return points
    }
    
    static func calculatePointsInXC(myPlaces: String, opponentPlaces: String) -> [Int] {
        var points: [Int] = []
        var myPoints = 0
        var opponentPoints = 0
        
        let places1 = myPlaces.components(separatedBy: "-")
        let places2 = opponentPlaces.components(separatedBy: "-")
        
        for i in 0..<5 {
            myPoints += Int(places1[i])!
            opponentPoints += Int(places2[i])!
        }
        
        points[0] = myPoints
        points[1] = opponentPoints
        return points
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Score {
            return self.name == object.name
        } else {
            return false
        }
    }
}
