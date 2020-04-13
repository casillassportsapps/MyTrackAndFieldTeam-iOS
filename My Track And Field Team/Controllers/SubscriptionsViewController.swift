//
//  SubscriptionsViewController.swift
//  My Track And Field Team
//
//  Created by David Casillas on 4/12/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import UIKit

class SubscriptionsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        

        // in order to test this in android, you need to change your user's subscription to 0
        // to be able to select the option in the user settings
        // because you are a beta user, if you do tap the BUY button, it would come up as a test
        // when the BUY button is tapped, the pop up to purchase is handled by google
        // on a successfull purchase, the app handles the database updating provided below
        // there are four option (listed in order) and tableview cells are all alike
        
        // option User.SUBSCRIPTION_SEASON: value 3
        // title: One Season Access
        // description: Purchase a flat fee for one season. This purchase will last for 120 days.
        //              Access will end on {END_DATE} ie: August 10, 2020 (date 120 days from current time)
        // price: $5.49
        // on successful purchase: user.subscription = 3
        //                         user.subscriptionEnds = purchase time in milliseconds plus 120 days in milliseconds
        
        // option User.SUBSCRIPTION_YEARLY: value 2
        // title: Yearly Subscription
        // description: Purchase a yearly subscription. Your subscription will auto-renew and your card will be charged
        //              every year on {NEXT_YEARS_DATE} ie: April 13 (today's date without year) (year shown in android is mistake)
        // price: $11.99
        // on successful purchase: user.subscription = 2
        //                         user.subscriptionEnds = purchase time in milliseconds plus 1 year in milliseconds
        
        // option User.SUBSCRIPTION_SINGLE_YEAR: value 1
        // title: One Year Access
        // description: Purchase a flat fee for one year. Access will end on {END_DATE} ie: April 13, 2021 (date 1 year from current time)
        // price: $15.99
        // on successful purchase: user.subscription = 1
        //                         user.subscriptionEnds = purchase time in milliseconds plus 1 year in milliseconds
        
        // option User.SUBSCRIPTION_MANAGER: value 4
        // title: Manager Access
        // description: If you are a user who is only managing an existing team, you can purchase this one year flat fee.
        //              A manager will not be able to create teams.
        //              Access will end on {END_DATE} ie: April 13, 2021 (date 1 year form current time)
        // price: $5.49
        // on successful purchase: user.subscription = 4
        //                         user.subscriptionEnds = purchase time in milliseconds plus 1 year in milliseconds
        
        // write to database after a successful purchase
        DatabaseUtils.storePurchasesToDatabase(userId: "userId", subscription: 1, subscriptionEnds: 1587268800000, purchaseInfo: "Some Purchase Information")
        
    }
    
}
