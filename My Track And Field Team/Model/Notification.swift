//
//  Notification.swift
//  My Track And Field Team
//
//  Created by David Casillas on 4/9/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Firebase

class Notification: NSObject {
    
    static let NOTIFICATIONS = "notifications"
    static let ID = "id"
    static let USER_ID = "userId"
    static let TEAM_ID = "teamId"
    static let TITLE = "title"
    static let MESSAGE = "message"
    static let TYPE = "type"
    static let TIME_STAMP = "timeStamp"
    static let TOKENS = "tokens"
    static let URL = "url"
    static let URL_TEXT = "urlText"
    static let IMAGE = "image"
    
    static let TYPE_DEFAULT = 100
    static let TYPE_MANAGER_REQUEST = 200
    static let TYPE_AD = 300
    static let TYPE_ADMIN = 400
    
    var id: String?
    var userId: String?
    var teamId: String?
    var title: String?
    var message: String?
    var type: Int?
    var timeStamp: Int?
    var tokens: [String: String]? // used for firebase function delivery of push notification
    var url: String? // link to website
    var urlText: String? // text to click link
    var image: String? // url of image to load
    
    func isTypeAdmin() -> Bool {
        return type == Notification.TYPE_ADMIN
    }
    
    func isTypeAd() -> Bool {
        return type == Notification.TYPE_AD
    }
    
    func isTypeRequest() -> Bool {
        return type == Notification.TYPE_MANAGER_REQUEST
    }
    
    override init() {
    }
    
    init(document: DocumentSnapshot) {
        let dict = document.data()!
        self.id = dict[Notification.ID] as? String
        self.userId = dict[Notification.USER_ID] as? String
        self.teamId = dict[Notification.TEAM_ID] as? String
        self.title = dict[Notification.TITLE] as? String
        self.message = dict[Notification.MESSAGE] as? String
        self.type = dict[Notification.TYPE] as? Int
        self.timeStamp = dict[Notification.TIME_STAMP] as? Int
        self.url = dict[Notification.URL] as? String
        self.urlText = dict[Notification.URL_TEXT] as? String
        self.image = dict[Notification.IMAGE] as? String
    }
    
    func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict[Notification.ID] = id
        dict[Notification.USER_ID] = userId
        dict[Notification.TEAM_ID] = teamId
        dict[Notification.TITLE] = title
        dict[Notification.MESSAGE] = message
        dict[Notification.TYPE] = type
        dict[Notification.TIME_STAMP] = timeStamp // make this value can always be the current time in milliseconds
        return dict
    }
    
    func toDictRequest() -> [String: Any] {
        var dict = [String: Any]()
        dict[Notification.ID] = id
        dict[Notification.TITLE] = title
        dict[Notification.MESSAGE] = message
        dict[Notification.TYPE] = type
        dict[Notification.TOKENS] = tokens
        return dict
    }
    
    // this gets the notification date string depending on how long has passed since the notification
    static func getNotificationDate(time: Int) -> String {
        let currentYear = 2020 // get current year
        let notificationYear = 2020 // get year of notification date
        let currentTime = 1586427744781 // get current time in millis
        
        var format: String
        if currentTime - time < 86400000 {
            // if notification date is within a day
            format = "h:mm"
        } else if notificationYear == currentYear {
            // if notification date is the same year as the current
            format = "EEE, MMM d"
        } else {
            format = "MMM d, yyyy"
        }
        
        return format // return the date using this format variable
    }
}
