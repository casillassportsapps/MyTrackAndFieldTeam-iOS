//
//  UserSettingsViewController.swift
//  My Track And Field Team
//
//  Created by David Casillas on 4/10/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import UIKit
import Firebase

class UserSettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let user = User() // get the actual user
        
        // user settings in group and order with actions
        // MY PROFILE group settings
        
        // NAME setting
        // value is user.name
        // ACTION
        // user should be able to change their name in their auth account and database, name cannot be empty
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = "{entered name}"
        changeRequest?.commitChanges { (error) in
            if error == nil {
                // change name in database
                DatabaseUtils.firestoreDB.document("\(User.USER)/\(user.id!)").updateData([User.NAME: "{entered name}"]) { (error) in
                    if error == nil {
                        user.name = "{entered name}"
                    }
                }
            }
        }
        
        // EMAIL setting
        // value is user.email
        // ACTION
        // user should be able to change their email in their auth account and database, email must be a valid email
        Auth.auth().currentUser?.updateEmail(to: "{entered email}") { (error) in
          if error == nil {
              // change email in database
            DatabaseUtils.firestoreDB.document("\(User.USER)/\(user.id!)").updateData([User.EMAIL: "{entered email}"]) { (error) in
                if error == nil {
                    user.email = "{entered email}"
                }
            }
          }
        }
        
        // PASSWORD setting
        // ACTION
        Auth.auth().sendPasswordReset(withEmail: user.email!) { error in
            // when user accepts log out the app so the user can relogin with the new email
        }
        
        // SUBSCRIPTION setting
        // value
        // the value and icon change based on the subscription setting
        
        switch user.subscription! {
        case User.SUBSCRIPTION_TRIAL:
            // icon is ic_account_trial
            // value is "Your trial period ends on {DATE}"  sample date: April 12, 2020
            // date comes from user.subscriptionEnds value
            break
        case User.SUBSCRIPTION_FREE:
            // icon is ic_account_paid
            // value is "You have a free subscription"
            break
        case User.SUBSCRIPTION_SINGLE_YEAR, User.SUBSCRIPTION_MANAGER:
            // icon is ic_account_paid
            // value is "Your single year subscription ends on {DATE}"  sample date: April 12, 2020
            // date comes from user.subscriptionEnds value
            break
        case User.SUBSCRIPTION_SEASON:
            // icon is ic_account_paid
            // value is "Your season subscription ends on {DATE}"  sample date: April 12, 2020
            // date comes from user.subscriptionEnds value
            break
        case User.SUBSCRIPTION_YEARLY:
            // icon is ic_account_paid
            // value is "You are a yearly subscribed user. Your subscription will renew after {DATE}. Tap to manage subscription."
            // date comes from user.subscriptionEnds value
            break
        default: // User.SUBSCRIPTION_NONE
            // icon is ic_account_alert
            // value is "Your subscription ended on {DATE}. Tap to select a subscription option."
            break
        }
        
        // ACTION
        // if the subscription ended then go to subscription page (done in different task)
        // if the subscription is yearly, go to the apple store where the user can edit their yearly subscription to the app (is possible)
        // otherwise do nothing
        
        // DELETE ACCOUNT setting
        // value "Permanently delete my account
        // ACTION
        let teams = user.teams
        if teams != nil || teams!.count > 0 {
            // show message "You must removal all associations with any teams before you can delete your account"
        } else {
            // first delete from database then delete from auth, then go back to create account page
            DatabaseUtils.firestoreDB.document("\(User.USER)/\(user.id!)").delete() { (error) in
                if error == nil {
                    Auth.auth().currentUser?.delete { error in
                        if error == nil {
                            // go back to create account page
                        }
                    }
                }
            }
        }
        
        // MY TRACK & FIELD TEAM group settings
        
        // Visit Our Facebook Page setting
        // value is "Questions, comments, or recommendations? Message us on facebook and follow us for latest updates.
        // ACTION
        // open up this link https://www.facebook.com/mytrackandfieldteam
        
        // Contact Support setting
        // value is "Email or text support"
        // ACTION
        // give option to either email support or text support
        // support email is support@casillassportsapps.com
        // support text number is 6317717776
        // try in android to see the email information given and support text
        
        // About setting
        // ACTION
        // opens up page with large icon, app name, version code, and privacy policy link
        // try in android
        
        // Frequently Asked Questions
        // ACTION
        // display a message "Currently Unavailable (under future development)
        
        // Log Out setting
        // ACTION
        // log out the user and go to login page
    }
}
