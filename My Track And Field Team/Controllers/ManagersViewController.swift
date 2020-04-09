//
//  ManagersViewController.swift
//  My Track And Field Team
//
//  Created by David Casillas on 4/9/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import UIKit

class ManagersViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // firestore query gets users where the users' teams teamId key has value either "pending" or "manager"
        // use a snapshot listener
        DatabaseUtils.firestoreDB.collection(User.USER).whereField("\(User.TEAMS).\("{teamId}")", in: ["manager", "pending"])
        
        // tableview and cells
        // order by user.name
        
        // 2 types of cells one that is pending a manger and one that is a current manager
        // both cells show the name of the user and below that the email
        
        // pending cell
        // shows "Pending response form user..." below email
        // shows X button so the owner can remove the manager pending, use function cancelManager in DatabaseUtils.swift
        
        // manager cell
        // below the email there are 3 buttons
        // season access button
        // loads up a dialog of all seasons with the full description ie: Varsity Girls' Outdoor 2019 with a checkbox
        // check box should be checked if the manager has write access to that season, use the access class
        // when the owner taps OK, the access node gets updated with the user's access
        // use function updateSeasonAccess in DatabaseUtils.swift
        
        // email button
        // send email to user
        
        // delete button
        // user function deleteManager in DatabaseUtils.swift
        
        
        // add button - search user and send manager request
        // have a textfield that automatically runs the below function when a legitmate email is entered
        // owner can't enter own email or an email of a current manager
        DatabaseUtils.firestoreDB.collection(User.USER).whereField(User.EMAIL, isEqualTo: "{entered email}").getDocuments() {
            (snapshots, err) in
            // should only get one document since emails are unique
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in snapshots!.documents {
                    // get user from document and show in tableview
                    // when owner clicks on user, use function requestManager in DatabaseUtils.swift
                }
            }
        }
        
    }
    


}
