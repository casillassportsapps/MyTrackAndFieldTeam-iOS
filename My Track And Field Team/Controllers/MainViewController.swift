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
    func getCompetitionData() {
        let teamId = "-Kw7SanZs1Fry-It_NG9" // Islip
        let seasonId = "-Lj8rSokYrQ3l68CUDUa" // Outdoor 2019
        let isXC = false
        
        let path = "\(Competition.COMPETITIONS)/\(teamId)/\(seasonId)/\(Competition.RESULTS)"
        DatabaseUtils.realTimeDB.child(path).observe(.value, with: { (snapshot) in
            if !snapshot.exists() {
                // show "No Stats"
                return
            }
            
            // get competitions from the season
            let competitionRef = DatabaseUtils.firestoreDB.collection("\(Team.TEAM)/\(teamId)/\(Team.SCHEDULE)")
            self.compListener = competitionRef.whereField(Competition.SEASON_ID, isEqualTo: seasonId).addSnapshotListener({ querySnapshot, error in
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
