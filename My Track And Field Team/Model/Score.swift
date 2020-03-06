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
        } else {
            self.name = dict[Score.NAME] as? String
            self.order = dict[Score.ORDER] as? Int
            self.firstPlace = dict[Score.FIRST_PLACE] as? Int ?? Score.NO_SCORE
            self.secondPlace = dict[Score.SECOND_PLACE] as? Int ?? Score.NO_SCORE
            self.thirdPlace = dict[Score.THIRD_PLACE] as? Int ?? Score.NO_SCORE
        }
    }
    
    init(name: String, order: Int) {
        self.name = name
        self.order = order
        self.firstPlace = Score.NO_SCORE
        self.secondPlace = Score.NO_SCORE
        self.thirdPlace = Score.NO_SCORE
    }
    
    func toDictTrackScoring() -> [String: Any] {
        var dict = [String: Any]()
        dict[Score.NAME] = self.name
        dict[Score.ORDER] = self.order
        dict[Score.FIRST_PLACE] = self.firstPlace
        dict[Score.SECOND_PLACE] = self.secondPlace
        dict[Score.THIRD_PLACE] = self.thirdPlace
        return dict
    }
    
    // get the score model for cross country
    static func getCrossCountryPlaces(snapshot: DataSnapshot) -> Score {
        return Score(snapshot: snapshot, isCrossCountry: true)
    }
    
    // calculates the points for cross country, only top 5 places on each team count
    // ie: if a team's places String is 1-3-5-6-9-11-12, then total = 1+3+5+6+9 = 24 points
    static func calculatePointsInXC(myPlaces: String, opponentPlaces: String) -> [Int] {
        var myPoints = 0
        var opponentPoints = 0
        
        let places1 = myPlaces.components(separatedBy: "-")
        let places2 = opponentPlaces.components(separatedBy: "-")
        
        for i in 0..<5 {
            myPoints += Int(places1[i])!
            opponentPoints += Int(places2[i])!
        }
        
        return [myPoints, opponentPoints]
    }
    
    // get an array of score models for track, one for each event
    static func getTrackPlaces(snapshot: DataSnapshot) -> [Score] {
        var scores = [Score]()
        
        for scoreSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
            let score = Score(snapshot: scoreSnapshot, isCrossCountry: false)
            scores.append(score)
        }
        
        return scores
    }
    
    // calculate the points for track, points depend on who and what place per event
    // ie: team A gets first and third and team B gets second in an event, the points are team A 6 and team B 3 for that event
    static func calculatePointsInTrack(score: Score) -> [Double] {
        let firstPlace = score.firstPlace
        let secondPlace = score.secondPlace
        let thirdPlace = score.thirdPlace
        
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
        
        return [myPoints, opponentPoints]
    }
    
    static func calculateTotalScoreTrack(scores : [Score]) -> [Double] {
        var myPoints = 0.0
        var opponentPoints = 0.0
        
        for score in scores {
            let points = calculatePointsInTrack(score: score)
            myPoints += points[0]
            opponentPoints += points[1]
        }
        
        return [myPoints, opponentPoints]
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Score {
            return self.name == object.name
        } else {
            return false
        }
    }
}
