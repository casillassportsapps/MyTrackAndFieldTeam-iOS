//
//  Location.swift
//  My Track And Field Team
//
//  Created by David Casillas on 2/20/20.
//  Copyright © 2020 Casillas Sports Apps. All rights reserved.
//

import Firebase

class Location: NSObject {
    static let LOCATION = "location"
    static let POSTAL_CODE = "postalCode"
    static let CITY = "city"
    static let COUNTRY = "country"
    static let COUNTY = "county"
    static let DISTRICT = "district" // used in UK
    static let STATE = "state" // used in US
    
    var city: String?
    var state: String?
    var postalCode: String?
    var county: String?
    var country: String?
    var district: String?
    
    override init() {
    }
    
    init(snapshot: DataSnapshot) {
        let dict = snapshot.value as! [String: Any]
        self.city = dict[Location.CITY] as? String ?? ""
        self.state = dict[Location.STATE] as? String ?? ""
        self.postalCode = dict[Location.POSTAL_CODE] as? String ?? ""
        self.county = dict[Location.COUNTY] as? String ?? ""
        self.country = dict[Location.COUNTRY] as? String ?? ""
        self.district = dict[Location.DISTRICT] as? String ?? ""
    }
    
    func toDictUS() -> [String: Any] {
        var dict = [String: Any]()
        dict[Location.CITY] = city
        dict[Location.STATE] = state
        dict[Location.POSTAL_CODE] = postalCode
        dict[Location.COUNTY] = county
        dict[Location.COUNTRY] = country
        return dict
    }
    
    func toDictUK() -> [String: Any] {
        var dict = [String: Any]()
        dict[Location.POSTAL_CODE] = postalCode
        dict[Location.COUNTY] = county
        dict[Location.COUNTRY] = country
        dict[Location.DISTRICT] = district
        return dict
    }
}
