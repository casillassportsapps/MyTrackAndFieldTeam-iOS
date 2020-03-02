//
//  DualMeetViewController.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/27/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import UIKit
import Firebase

class DualMeetViewController: UIViewController {
    // this class shows the scoring of dual meets
    // dual meet scoring for track is different than cross country
    // this can display up to 3 opponents at once
    
    let ref = DatabaseUtils.realTimeDB
    var resultsRef: DatabaseReference!
    var teamId: String!
    var seasonId: String!
    var meet: Competition!
    var isCrossCountry: Bool!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // sets up a snapshot observer
        self.observeResults()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // removes the observer
        resultsRef.removeAllObservers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        teamId = "-LICDiRCU9HzswMnhCzt"
        seasonId = "-Lj8rV0t-rtmWoKFAqVU"
        meet = Competition(id: "-LLG5_7HFnv2CFGDQy1O") // for outdoor track
        isCrossCountry = false
        
        //meet = Competition(id: "-La5B8M3wu8oL30r0pqM") // for cross country
        
        resultsRef = ref.child("\(Competition.COMPETITIONS)/\(teamId!)/\(seasonId!)/\(Competition.SCORING)/\(meet.id!)")
        
        // menu options
        // Post Score:
        // this menu options takes the current meet score and updates the competition document in the schedule at field score/opponent{#}
        // see method postScore()
    }
    
    func observeResults() {
        // loading dialog should appear and disappear once tablewview has data
        resultsRef.observe(.childAdded, with: { (snapshot) -> Void in
            // add score to tableview
            
            // key is either opponent1, opponent2, or opponent3 to make sure you know which opponent is getting a score added
            let opponent = snapshot.key
            
            if self.isCrossCountry {
                let score = Score.getCrossCountryPlaces(snapshot: snapshot)
            } else {
                let scores = Score.getTrackPlaces(snapshot: snapshot)
            }
        })
        
        resultsRef.observe(.childChanged, with: { (snapshot) -> Void in
            // replace score in tableview, retrieve with same code as .childAdded
            
            // key is either opponent1, opponent2, or opponent3 to make sure you know which opponent is getting a score change
            let opponent = snapshot.key
            
            if self.isCrossCountry {
                let score = Score.getCrossCountryPlaces(snapshot: snapshot)
            } else {
                let scores = Score.getTrackPlaces(snapshot: snapshot)
            }
        })
        
        resultsRef.observe(.childRemoved, with: { (snapshot) -> Void in
            // clears tableview
            // unlikely to happen, but this will only fire if the opponent{#} node is removed
            
            // key is either opponent1, opponent2, or opponent3 to make sure you know which opponent is getting a score removed
            let opponent = snapshot.key
        })
        
    }
    
    func postScore() {
        // post score does not only work when the menu item is tapped
        // this method should also run whenever there's a change in the score with the following conditions
        // outdoor track - score should update IF every event contains first place points
        // cross country - score should update IF both teams have at least 5 places scored
        
        // otherwise this method only works when the menu item is manually tapped
        
        let path = "\(Team.TEAM)/\(teamId!)/\(Team.SCHEDULE)/\(meet.id!)"
        let docRef = DatabaseUtils.firestoreDB.document(path)
        
        docRef.updateData([Competition.SCORE: "{score of meet in this format: 56 - 42}"])
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
