//
//  MainViewController.swift
//  My Track And Field Team
//
//  Created by David Casillas on 1/22/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI


class MainViewController: UIViewController {
    
    @IBAction func testFunction(_ sender: UIButton) {
        self.test()
    }
    
    @IBAction func signOut(_ sender: Any) {
        self.signOut()
    }
    
    var uId: String!
    var authUI: FUIAuth!
    var authStateListener: AuthStateDidChangeListenerHandle!
    
    override func viewWillAppear(_ animated: Bool) {
        if authStateListener == nil {
            authStateListener = authUI.auth?.addStateDidChangeListener({(auth, firebaseUser) in
                if firebaseUser != nil {
                    print("authenticated")
                    print(firebaseUser!.uid)
                    self.uId = firebaseUser!.uid
                } else {
                    print("unauthenticated")
                    self.signIn()
                }
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if authStateListener != nil {
            authUI.auth?.removeStateDidChangeListener(authStateListener)
            authStateListener = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        authUI = FUIAuth.defaultAuthUI()
        
        let provider: [FUIAuthProvider] = [FUIEmailAuth()]
        authUI.providers = provider
        
        let privacyPolicyURL = URL(string: "https://casillassportsapps.com/privacy-policy")
        authUI.privacyPolicyURL = privacyPolicyURL
        
        let tosURL = URL(string: "https://casillassportsapps.com/terms-of-service")
        authUI.tosurl = tosURL
    }

    func signIn() {
        let authViewController = authUI.authViewController()
        present(authViewController, animated: true, completion: nil)
    }
    
    func signOut() {
        do {
            try authUI.signOut()
        } catch {
        
        }
    }

    
    // TESTING DATABASE AND METHODS BELOW
    func test() {
        
    }
    
    var compListener: ListenerRegistration!
    func getCompetitionDataForSeasonStats() {
        let teamId = "-Kw7SanZs1Fry-It_NG9" // Islip
        let seasonId = "-Lj8rSokYrQ3l68CUDUa" // Outdoor 2019
        let isXC = false
        
        let path = "\(Competition.COMPETITIONS)/\(teamId)/\(seasonId)/\(Competition.RESULTS)"
        DatabaseUtils.realTimeDB.child(path).observeSingleEvent(of: .value, with: { (snapshot) in
            if !snapshot.exists() {
                // show "No Stats"
                return
            }
            
            // get competitions from the season
            let competitionsRef = DatabaseUtils.firestoreDB.collection("\(Team.TEAM)/\(teamId)/\(Team.SCHEDULE)")
            self.compListener = competitionsRef.whereField(Competition.SEASON_ID, isEqualTo: seasonId).addSnapshotListener({ querySnapshot, error in
                self.compListener.remove() //

                if error != nil || querySnapshot == nil {
                    return
                }
                
                // create the competition dictionary
                var compDict = [String: Competition]()
                for document in querySnapshot!.documents {
                    let competition = Competition(document: document)
                    compDict[competition.id!] = competition
                }
                
                // get all results
                let dict = Competition.getStatResults(snapshot: snapshot, competitionsDict: compDict, isCrossCountry: isXC)
                
                // print results as a check
                for (key, value) in dict {
                    print(key)
                    print("-----------------")
                    for eventResult in value {
                        if eventResult.isRelay() {
                            let relay = eventResult as! Relay
                            print(relay.result!)
                            for athlete in relay.getRelayAthletes() {
                                print(athlete.fullName()!)
                            }
                        } else {
                            print("\(eventResult.athlete!.fullName()!) \(eventResult.result!)")
                        }
                    }
                    print("-----------------")
                }
            })
        })
    }
    
    func getCompetitionDataForTeamStats() {
        // getting results of all of Islip's Outdoor seasons (user selected outdoor)
        let teamId = "-Kw7SanZs1Fry-It_NG9" // Islip
        
        var seasonIds = [String]() // array of outdoor season ids
        seasonIds.append("-Lj8rSokYrQ3l68CUDUV") // outdoor 2017
        seasonIds.append("-Lj8rSokYrQ3l68CUDUY") // outdoor 2018
        seasonIds.append("-Lj8rSokYrQ3l68CUDUa") // outdoor 2019
        seasonIds.append("-M0-s8Cpx8IKQvpn1ugR") // outdoor 2020, this season has no results so datasnapshot won't exist
        
        let isXC = false
        
        var dataSnapshots = [DataSnapshot]()
        
        let group = DispatchGroup()
        
        for seasonId in seasonIds {
            group.enter()
            let path = "\(Competition.COMPETITIONS)/\(teamId)/\(seasonId)/\(Competition.RESULTS)"
            DatabaseUtils.realTimeDB.child(path).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    dataSnapshots.append(snapshot)
                }
                group.leave()
            })
        }
        
        group.notify(queue: .main, execute: {
            // check if there are multiple seasons to display team stats
            if dataSnapshots.count > 1 {
                // get competitions from specific seasons
                let competitionsRef = DatabaseUtils.firestoreDB.collection("\(Team.TEAM)/\(teamId)/\(Team.SCHEDULE)")
                self.compListener = competitionsRef.whereField(Competition.SEASON_ID, in: seasonIds).addSnapshotListener({ querySnapshot, error in
                    self.compListener.remove() //

                    if error != nil || querySnapshot == nil {
                        return
                    }
                    
                    // create the competition dictionary
                    var compDict = [String: Competition]()
                    for document in querySnapshot!.documents {
                        let competition = Competition(document: document)
                        compDict[competition.id!] = competition
                    }
                    
                    var teamStatsDict = [String: [EventResult]]()
                    for snapshot in dataSnapshots {
                        // get all results from season and merge into teamStatsDict
                        let dict = Competition.getStatResults(snapshot: snapshot, competitionsDict: compDict, isCrossCountry: isXC)
                        teamStatsDict.merge(dict, uniquingKeysWith: +)
                    }
                    
                    // print results as a check
                    for (key, value) in teamStatsDict {
                        print(key)
                        print("-----------------")
                        for eventResult in value {
                            if eventResult.isRelay() {
                                let relay = eventResult as! Relay
                                print(relay.result!)
                                for athlete in relay.getRelayAthletes() {
                                    print(athlete.fullName()!)
                                }
                            } else {
                                print("\(eventResult.athlete!.fullName()!) \(eventResult.result!)")
                            }
                        }
                        print("-----------------")
                    }
                })
            } else {
                // not enough seasons for team stats, go back to tablview of season names
                // display message "You must have at least 2 {selected season} seasons of results. Otherwise view season stats."
            }
        })
    }
    
    func deleteManager() {
        let teamId = "-Kw7SanZs1Fry-It_NG9" // "-M-KuFlPmU1ahZEv8ptg"

        DatabaseUtils.firestoreDB.document("\(Team.TEAM)/\(teamId)").getDocument { (document, error) in
            if let document = document, document.exists {
                let team = Team(document: document)
                
                var managers = [String]()
                managers.append(self.uId)
                
                for season in team.seasons! {
                    if season.id != "-Lj8rSokYrQ3l68CUDUV" {
                        season.managers = managers
                    }
                }
                
                DatabaseUtils.deleteManager(team: team, userId: self.uId, completion: { error in
                    print(error ?? "Success")
                })
            } else {
                print("Document does not exist")
            }
        }
    }
    
}
