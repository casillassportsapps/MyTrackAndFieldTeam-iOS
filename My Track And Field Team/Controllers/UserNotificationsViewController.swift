//
//  UserNotificationsViewController.swift
//  My Track And Field Team
//
//  Created by David Casillas on 4/9/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import UIKit

class UserNotificationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // firestore query gets notifications where userid = the user's id or 'app' limit to 10 documents
        // user a snapshot listener
        DatabaseUtils.firestoreDB.collection(Notification.NOTIFICATIONS)
            .whereField(Notification.USER_ID, in: ["{userId}", "app"]).limit(to: 10)
        
        // tableview and cells
        // order by date starting with the most recent
        // date string from timestamp use getNotificationDate in Notifications.swift
        
        // four different type of notifications with minor differences
    
        // all notifications have fields:
        // id, title, message, timestamp, type
        
        // default notification type 100
        // cell has an X button so the user can delete this notification, no other notification types have this
        // when user selects the delete button use deleteNotification in DatabaseUtils.swift
        
        // manager request notification type 200
        // other fields: userId, teamId
        // cell has 2 buttons, accept and decline button
        // accept button use acceptManager function in DatabaseUtils.swift
        // on success of the accept, since the user doesn't automatically update on a change,
        // add the teamId to the user's teams with value "manager"
        // decline button use cancelManager function in DatabaseUtils.swift
        
        // ad notification type 300
        // other fields: url, urlText, image
        // url is the link to a website when the user clicks on the url text or the image
        // urlText is the text representing the url ie: "Click here to check out photos"
        // image is the url to the image that should be loaded in imageview
        
        // admin notification type 400
        // exactly like default notification except there's no X button and the title is red (use same color code as in app)
    }
    

}
