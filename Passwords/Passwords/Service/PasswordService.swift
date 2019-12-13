//
//  PasswordService.swift
//  Passwords
//
//  Created by James Hadar on 4/21/18.
//  Copyright © 2018 James Hadar. All rights reserved.
//

import Foundation
import UIKit

typealias AppRecordsMap = Dictionary<String, [Password]>

protocol PasswordServiceProtocol {
    func getAppNames() -> [String]
    func getPasswordRecords() -> [Password]
    func getPasswordRecords(forApp app: String) -> [Password]?
    func createPasswordRecord(app: String, user: String, password: String)
    func deletePasswordRecord(_ record: Password)
    func updatePasswordRecord(_ record: Password)
}

class PasswordService {
    // WARNING: Not thread safe.
    
    static let sharedInstance = PasswordService()
    let kDefaultsKey = "passwordRecords"
    
    private init() {
        loadPasswordRecords()
    }
    
    // MARK: - Private
    
    private let defaults = UserDefaults.standard
    
    private var appRecordsMap = AppRecordsMap()
    private var passwordRecords = [Password]() {
        didSet {
            reloadAllData()
        }
    }
    
    private func reloadAllData() {
        var newAppRecordsMap = AppRecordsMap()
        var newApps = [String]()
        for record in passwordRecords {
            let app = record.app
            
            if newAppRecordsMap[app] == nil {
                newAppRecordsMap[app] = [record]
            } else {
                newAppRecordsMap[app]!.append(record)
            }
            
            if !newApps.contains(app) {
                newApps.append(app)
            }
        }
        appRecordsMap = newAppRecordsMap
    }
    
    func decodedPasswordRecords() -> [Password]? {
        if let savedData = defaults.object(forKey: kDefaultsKey) as? Data {
            let jsonDecoder = JSONDecoder()
            
            if let decodedRecords = try? jsonDecoder.decode([Password].self, from: savedData) {
                return decodedRecords
            }
        }
        return nil
    }
    
    func encodedPasswordData() -> Data? {
        let jsonEncoder = JSONEncoder()
        
        if let encodedData = try? jsonEncoder.encode(passwordRecords) {
            return encodedData
        }
        return nil
    }
    
    private func loadPasswordRecords() {
        if let decodedRecords = decodedPasswordRecords() {
            passwordRecords = decodedRecords
            print("Loaded \(passwordRecords.count) password records")
        } else {
            print("Failed to load password records.")
        }
    }
    
    private func savePasswordRecords() {
        if let encodedData = encodedPasswordData() {
            defaults.set(encodedData, forKey: kDefaultsKey)
            print("Saved \(passwordRecords.count) password records.")
        } else {
            print("Failed to save password records.")
        }
    }
}

// MARK: - PasswordServiceProtocol

extension PasswordService: PasswordServiceProtocol {
    
    func getAppNames() -> [String] {
        return Array(appRecordsMap.keys)
    }
    
    func getPasswordRecords() -> [Password] {
        return passwordRecords
    }
    
    func getPasswordRecords(forApp app: String) -> [Password]? {
        return appRecordsMap[app]
    }
    
    func createPasswordRecord(app: String, user: String, password: String) {
        let passwordRecord = Password(app: app, user: user)
        passwordRecord.setPassword(password)
        passwordRecords.append(passwordRecord)
        savePasswordRecords()
        print("Added password record for \(app) \(user)")
    }
    
    //  TODO: These last two are O(N), but they could be O(1) if passwordRecords were cached against their uuid.
    
    func deletePasswordRecord(_ record: Password) {
        let uuidToDelete = record.uuid
        for (index, record) in passwordRecords.enumerated() {
            if record.uuid == uuidToDelete {
                passwordRecords.remove(at: index)
                savePasswordRecords()
                print("Deleted password record \(uuidToDelete)")
                break
            }
        }
    }
    
    func updatePasswordRecord(_ record: Password) {
        let uuidToUpdate = record.uuid
        for selected in passwordRecords {
            if selected.uuid == uuidToUpdate {
                selected.app = record.app
                selected.user = record.user
                if let newPassword = record.getPassword() {
                    selected.setPassword(newPassword)
                }
                savePasswordRecords()
                print("Updated password record \(uuidToUpdate)")
                break
            }
        }
    }
}
