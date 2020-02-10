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


var authUI: FUIAuth!
var authStateListener: AuthStateDidChangeListenerHandle!


class MainViewController: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        if authStateListener == nil {
            authStateListener = authUI.auth?.addStateDidChangeListener({(auth, firebaseUser) in
                if firebaseUser != nil {
                    print("authenticated")
                    print(firebaseUser!.uid)
                } else {
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
    
    func getAthlete() {
        let db = Firestore.firestore()
        //let docRef = db.collection("teams").document("-LICDiRCU9HzswMnhCzt").collection(Athlete.ROSTER).document("-LIlAb-of3DUYuGv-_j3")
        let docRef = db.document("teams/-LICDiRCU9HzswMnhCzt/\(Athlete.ROSTER)/-LIlAb-of3DUYuGv-_j3")
        docRef.getDocument { (document, error) in
            if error != nil {
                print("no access to this document")
            } else {
                let athlete = Athlete(document: document!)
                print(athlete.id!)
                print(athlete.fullName()!)
                print(athlete.type!)
                for id in athlete.seasons! {
                    print(id)
                }
            }
        }
    }
    
    func getCompetition() {
        let db = DatabaseUtils.firestoreDB
        //let docRef = db.collection("teams").document("-LICDiRCU9HzswMnhCzt").collection(Competition.SCHEDULE).document("-LLG5_7HFnv2CFGDQy1O")
        let docRef = db.document("teams/-LICDiRCU9HzswMnhCzt/\(Competition.SCHEDULE)/-LLG5_7HFnv2CFGDQy1O")
        docRef.getDocument { (document, error) in
            if error != nil {
                print("no access to this document")
            } else {
                let competition = Competition(document: document!)
                print(competition.id!)
                print(competition.name!)
                print(competition.type!)
                print(competition.location!)
                print(competition.seasonId!)
                
                let date = Date(timeIntervalSince1970: TimeInterval(competition.dateTime!/1000))
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "EEE, MMM d, yyyy h:mm aa"
                print(dateFormatter.string(from: date))
      
                for opponent in competition.opponent!.values {
                    print(opponent)
                }
                
                for score in competition.score!.values {
                    print(score)
                }
            }
        }
    }
}
