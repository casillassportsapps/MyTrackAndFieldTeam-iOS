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
    
    
    var authUI: FUIAuth!
    var authStateListener: AuthStateDidChangeListenerHandle!
    
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

    
    // TESTING DATABASE AND METHODS BELOW
    func test() {
        let teamId = "-Kw7SanZs1Fry-It_NG9"
        let athlete = Athlete(id: "-Kwbvmr_hnyy4CtxGWXl")
        athlete.firstName = "Madeline"
        athlete.lastName = "Mowbray"
        
        DatabaseUtils.realTimeDB.child("\(Athlete.ATHLETES)/\(teamId)/\(athlete.id!)/\(Athlete.RESULTS)")
            .observeSingleEvent(of: .value, with: { (snapshot) in
                let updates = Athlete.getPathsToDenormalize(teamId: teamId, athlete: athlete, snapshot: snapshot)
                if updates == nil {
                    return
                }
                
                updates!.keys.forEach { key in
                    print(key)
                }
            })
    }
    
}
