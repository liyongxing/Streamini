//
//  Connector.swift
//  Test
//
//  Created by Cloud Stream on 1/27/15.
//  Copyright (c) 2015 Direct Invent. All rights reserved.
//

import UIKit

class Connector: NSObject {
    var manager = RKObjectManager(baseURL: Connector.baseUrl())
    var errorDescriptor:RKResponseDescriptor?
    
    class func baseUrl() -> NSURL {
        let (host) = Config.shared.api()
        return NSURL(string: host)!
    }
    
    override init () {
        super.init()
        self.manager.requestSerializationMIMEType = RKMIMETypeFormURLEncoded
        self.addErrorResponseDescriptor()
    }
    
    func sessionParams() -> [NSObject : AnyObject]? {
        if let session = A0SimpleKeychain().stringForKey("PHPSESSID") {
            let params: [NSObject: AnyObject] = [ "PHPSESSID" : session ]
            return params
        } else {
            return nil
        }
    }
    
    func loginData() -> NSDictionary? {
        let data = NSMutableDictionary()
        if let id = A0SimpleKeychain().stringForKey("id") {
            data["id"] = A0SimpleKeychain().stringForKey("id")
        }
        if let token = A0SimpleKeychain().stringForKey("token") {
            data["token"] = A0SimpleKeychain().stringForKey("token")
        }
        if let secret = A0SimpleKeychain().stringForKey("secret") {
            data["secret"] = A0SimpleKeychain().stringForKey("secret")
        }
        if let type = A0SimpleKeychain().stringForKey("type") {
            data["type"] = A0SimpleKeychain().stringForKey("type")
        }
        
        return (data.count == 4) ? data : nil
    }
    
    func login(loginData: NSDictionary, success: (session: String) -> (), failure: (error: NSError) -> ()) {
        let path = "user/login"
        
        let requestMapping  = UserMappingProvider.loginRequestMapping()
        let responseMapping = UserMappingProvider.loginResponseMapping()
        
        let requestDescriptor = RKRequestDescriptor(mapping: requestMapping, objectClass: NSDictionary.self, rootKeyPath: nil, method: RKRequestMethod.POST)
        
        manager.addRequestDescriptor(requestDescriptor)
        
        let statusCode = RKStatusCodeIndexSetForClass(RKStatusCodeClass.Successful)
        
        let loginResponseDescriptor = RKResponseDescriptor(mapping: responseMapping, method: RKRequestMethod.POST, pathPattern: nil, keyPath: "data", statusCodes: statusCode)
        manager.addResponseDescriptor(loginResponseDescriptor)
        
        manager.postObject(loginData, path: path, parameters: nil, success: { (operation, mappingResult) -> Void in
            // success code
            let error:Error = self.findErrorObject(mappingResult: mappingResult)!
            if !error.status {
                failure(error: error.toNSError())
            } else {
                let data = mappingResult.dictionary()["data"] as! NSDictionary
                let session = data["session"] as! String
                success(session: session)
            }
            }) { (operation, error) -> Void in
                // failure code
                failure(error: error)
        }
    }
    
    func relogin(success: () -> (), failure: () -> ()) {
        func loginSuccess(session: String) {
            success()
        }
        func loginFailure(error: NSError) {
            failure()
        }
        
        if let data = loginData() {
            self.login(data, success: loginSuccess, failure: loginFailure)
        } else {
            failure()
        }
    }

    func addErrorResponseDescriptor() {
        let mapping = ErrorMappingProvider.errorObjectMapping()

        let statusCode = RKStatusCodeIndexSetForClass(RKStatusCodeClass.Successful)
        self.errorDescriptor = RKResponseDescriptor(mapping: mapping, method:RKRequestMethod.Any, pathPattern: nil, keyPath: "", statusCodes: statusCode)
        self.manager.addResponseDescriptor(self.errorDescriptor)
    }
    
    func findErrorObject(mappingResult mappingResult: RKMappingResult) -> Error? {
        for obj in mappingResult.array() {
            if obj is Error {
                return obj as? Error
            }
        }
        
        return nil
    }
}
