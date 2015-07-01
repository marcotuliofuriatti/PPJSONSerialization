//
//  PPJSONSerialization.swift
//  PPJSONSerialization
//
//  Created by 崔 明辉 on 15/6/30.
//  Copyright (c) 2015年 PonyCui. All rights reserved.
//

import Foundation

enum PPJSONValueType: Int {
    case Unknown = 0
    case String
    case Number
    case Array
    case Dictionary
}

class PPJSONSerialization: NSObject, NSCopying {
    
    /// You use JSONMap links Property to JSON Object, [Property-Name: JSON-Object-Name]
    internal var JSONMap = [String: String]()
    
    internal func updateWithJSONString(JSONString: String) -> Bool {
        if let data = JSONString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            if let JSONObject: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) {
                return updateWithJSONObject(JSONObject, JSONKey: rootKey)
            }
            else {
                return false
            }
        }
        else {
            return false
        }
    }
    
    // The following code is private
    
    private let rootKey = ""
    
    private func updateWithJSONObject(JSONObject: AnyObject, JSONKey: String) -> Bool {
        let propertyKey = propertyKeyFromJSONKey(JSONKey)
        switch classForInstance(JSONObject) {
        case PPJSONValueType.String:
            if let _ = self.valueForKey(propertyKey) as? String {
                setValue(JSONObject, forKeyPath: propertyKey)
            }
            else if let _ = self.valueForKey(propertyKey) as? Double {
                setValue(numberObjectFromAnyObject(JSONObject), forKey: propertyKey)
            }
            else if let _ = self.valueForKey(propertyKey) as? Int {
                setValue(numberObjectFromAnyObject(JSONObject), forKey: propertyKey)
            }
            break
        case PPJSONValueType.Number:
            if let _ = self.valueForKey(propertyKey) as? String {
                setValue(stringObjectFromAnyObject(JSONObject), forKey: propertyKey)
            }
            else if let _ = self.valueForKey(propertyKey) as? Double {
                setValue(JSONObject, forKey: propertyKey)
            }
            else if let _ = self.valueForKey(propertyKey) as? Int {
                setValue(JSONObject, forKey: propertyKey)
            }
            break
        case PPJSONValueType.Array:
            if let propertyArray = self.valueForKey(propertyKey) as? NSArray {
                if let tplObject: AnyObject = propertyArray.lastObject {
                    var objectWithData = NSMutableArray()
                    if tplObject.isKindOfClass(NSClassFromString("NSNumber")) {
                        if let JSONArray: NSArray = JSONObject as? NSArray {
                            for JSONItem in JSONArray {
                                objectWithData.addObject(numberObjectFromAnyObject(JSONItem))
                            }
                        }
                    }
                    else if tplObject.isKindOfClass(NSClassFromString("NSString")) {
                        if let JSONArray: NSArray = JSONObject as? NSArray {
                            for JSONItem in JSONArray {
                                objectWithData.addObject(stringObjectFromAnyObject(JSONItem))
                            }
                        }
                    }
                    else {
                        if tplObject.respondsToSelector("copy") {
                            if let JSONArray: NSArray = JSONObject as? NSArray {
                                for JSONItem in JSONArray {
                                    if let mirrorObject: PPJSONSerialization = tplObject.copy() as? PPJSONSerialization {
                                        mirrorObject.updateWithJSONObject(JSONItem, JSONKey: rootKey)
                                        objectWithData.addObject(mirrorObject)
                                    }
                                }
                            }
                        }
                    }
                    setValue(objectWithData.copy(), forKey: propertyKey)
                    break
                }
            }
            break
        case PPJSONValueType.Dictionary:
            let JSONDictionary: NSDictionary! = JSONObject as? NSDictionary
            for (JSONKey, JSONValue) in JSONDictionary {
                if let JSONStringKey = JSONKey as? String {
                    updateWithJSONObject(JSONValue, JSONKey: JSONStringKey)
                }
            }
            break
        default:
            break
        }
        return false
    }
    
    private func classForInstance(instance: AnyObject) -> PPJSONValueType {
        if instance.isKindOfClass(NSClassFromString("NSString")!) {
            return PPJSONValueType.String
        }
        else if instance.isKindOfClass(NSClassFromString("NSNumber")!) {
            return PPJSONValueType.Number
        }
        else if instance.isKindOfClass(NSClassFromString("NSArray")!) {
            return PPJSONValueType.Array
        }
        else if instance.isKindOfClass(NSClassFromString("NSDictionary")!) {
            return PPJSONValueType.Dictionary
        }
        else {
            return PPJSONValueType.Unknown
        }
    }
    
    private func propertyKeyFromJSONKey(JSONKey: AnyObject) -> String {
        let tmpKey = stringObjectFromAnyObject(JSONKey) as String
        if let propertyKey = JSONMap[tmpKey] {
            return propertyKey
        }
        else {
            return tmpKey
        }
    }
    
    private func numberObjectFromAnyObject(anyObject: AnyObject) -> NSNumber {
        if let transferString = anyObject as? String {
            if let transferNumber = NSNumberFormatter().numberFromString(transferString) {
                return transferNumber
            }
        }
        else if let transferNumber = anyObject as? NSNumber {
            return transferNumber
        }
        return 0
    }
    
    private func stringObjectFromAnyObject(anyObject: AnyObject) -> NSString {
        if let transferNumber = anyObject as? NSNumber {
            if let transferString = NSNumberFormatter().stringFromNumber(transferNumber) {
                return transferString
            }
        }
        else if let transferString = anyObject as? String {
            return transferString
        }
        return ""
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        return PPJSONSerialization()
    }
    
}
