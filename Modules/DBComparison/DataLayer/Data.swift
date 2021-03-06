//
//  Data.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-5.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//
//  This file is part of Good Spirits.
//
//  Good Spirits is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Good Spirits is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation
import UIKit

// TODO: automatic sync between main and remote store
// TODO: notifications
// Persistent store coordinator.
public class DataLayer
{
    public typealias OperationLog = [DataLayer.SiteID : (startingIndex: DataLayer.Index, operations: [GlobalID])]
    public typealias DataType = DataAccessProtocol & DataDebugProtocol & DataObservationProtocol
    
    public typealias SiteID = UUID
    public typealias Index = UInt32
    public typealias Time = UInt64
    
    public static let calendar = Calendar.init(identifier: .gregorian)
    public let owner: SiteID
    
    private var stores: [DataType]
    private var mainStoreIndex: Int
    
    private var notificationObserver: Any?
    
    public var primaryStore: DataType & DataAccessProtocolImmediate
    {
        return self.stores[self.mainStoreIndex] as! (DataType & DataAccessProtocolImmediate)
    }
    
    public func store(atIndex i: Int) -> DataType
    {
        return self.stores[i]
    }
    
    deinit
    {
        if let observer = notificationObserver
        {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    public init(withStore store: DataType & DataAccessProtocolImmediate, owner: SiteID = UIDevice.current.identifierForVendor!)
    {
        self.owner = owner
        self.mainStoreIndex = 0
        self.stores = []
        
        self.addStore(store)
        
        self.notificationObserver = NotificationCenter.default.addObserver(forName: type(of: store).DataDidChangeNotification, object: nil, queue: nil)
        { [weak `self`] notification in
            // BUGFIX: We get into a locked state without this async! GRDB posts notification and then locks
            // while waiting on other db access from main thread.
            onMain
            {
                NotificationCenter.default.post(name: DataLayer.DataDidChangeNotification, object: self)
            }
        }
    }
    
    public func addStore(_ store: DataType)
    {
        self.stores.append(store)
        
        let dispatch = DispatchGroup()
        dispatch.enter()
        
        store.initialize
        {
            assert($0 == nil)
            dispatch.leave()
        }
        
        dispatch.wait()
    }
}

extension DataLayer
{
    public static var wildcardIndex: Index = Index.max
    public static func wildcardID(withOwner owner: SiteID) -> GlobalID
    {
        return GlobalID.init(siteID: owner, operationIndex: wildcardIndex)
    }
}

extension DataLayer: DataObservationProtocol
{
    public static var DataDidChangeNotification: Notification.Name = Notification.Name.init(rawValue: "DataDidChangeNotification")
}

public enum DataError: StringLiteralType, LocalizedError, Error
{
    case couldNotOpenStore
    case missingPreceedingOperations
    case wrongSyncCommitChoice
    case mismatchedOperation
    case improperOperationFormat
    case internalError
    case unknownError
    
    public var errorDescription: String?
    {
        return self.rawValue
    }
}

// Intended to be called from the main thread.
extension DataLayer
{
    public typealias Token = VectorClock
    public static var NullToken = VectorClock.init(map: [:])
    
    public func save(model: Model, syncing: Bool = false, withCallbackBlock block: @escaping (MaybeError<GlobalID>)->Void)
    {
        func ret(id: GlobalID)
        {
            onMain
            {
                block(.value(v: id))
            }
        }
        func ret(e: Error)
        {
            onMain
            {
                block(.error(e: e))
            }
        }
        
        self.primaryStore.readWriteTransaction
        { db in
            db.lamportTimestamp
            {
                switch $0
                {
                case .error(let e):
                    ret(e: e)
                case .value(let t):
                    db.data(forID: model.metadata.id)
                    {
                        switch $0
                        {
                        case .error(let e):
                            ret(e: e)
                        case .value(let p):
                            let data = model.toData(withLamport: t + 1, existingData: p)
                            if data == p
                            {
                                // TODO: appDebug
                                #if DEBUG
                                print("🔵 data already exists")
                                #endif
                                ret(id: data.metadata.id)
                            }
                            else
                            {
                                if syncing
                                {
                                    db.nextOperationIndex(forSite: self.owner)
                                    {
                                        switch $0
                                        {
                                        case .error(let e):
                                            ret(e: e)
                                        case .value(let v):
                                            let log = [self.owner : (v, [model.metadata.id])]
                                            db.sync(data: [data], withOperationLog: log)
                                            {
                                                if let error = $0
                                                {
                                                    ret(e: error)
                                                }
                                                else
                                                {
                                                    ret(id: model.metadata.id)
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    db.commit(data: data, withSite: self.owner)
                                    {
                                        switch $0
                                        {
                                        case .error(let e):
                                            ret(e: e)
                                        case .value(let id):
                                            ret(id: id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    public func load(model: GlobalID, withCallbackBlock block: @escaping (MaybeError<Model?>)->Void)
    {
        func ret(_ v: MaybeError<Model?>)
        {
            onMain
            {
                block(v)
            }
        }
        
        self.primaryStore.readTransaction
        { db in
            db.data(forID: model)
            {
                switch $0
                {
                case .error(let e):
                    ret(.error(e: e))
                case .value(let p):
                    let model = p?.toModel()
                    ret(.value(v: model))
                }
            }
        }
    }
    
    public func load(untappdModel: Model.ID, withCallbackBlock block: @escaping (MaybeError<Model?>)->Void)
    {
        func ret(_ v: MaybeError<Model?>)
        {
            onMain
                {
                    block(v)
            }
        }
        
        self.primaryStore.readTransaction
        { db in
            db.data(forUntappdID: untappdModel)
            {
                switch $0
                {
                case .error(let e):
                    ret(.error(e: e))
                case .value(let p):
                    let model = p?.toModel()
                    ret(.value(v: model))
                }
            }
        }
    }
    
    // PERF: we can filter these on the database level
    public func getModels(fromIncludingDate from: Date, toExcludingDate to: Date, withToken token: Token? = nil, includingDeleted: Bool = false, includingUntappdPending: Bool = false, withCallbackBlock block: @escaping (MaybeError<([Model], Token)>)->Void)
    {
        func ret(_ v: MaybeError<([Model], Token)>)
        {
            onMain
            {
                block(v)
            }
        }
        
        self.primaryStore.readTransaction
        { db in
            db.data(fromIncludingDate: from, toExcludingDate: to, afterTimestamp: token)
            {
                switch $0
                {
                case .error(let e):
                    ret(.error(e: e))
                case .value(let v):
                    var data = v.0.filter
                    {
                        if !includingDeleted && $0.metadata.deleted.v
                        {
                            return false
                        }
                        if ($0.checkIn.untappdId.v != nil && !$0.checkIn.untappdApproved.v)
                        {
                            return false
                        }
                        return true
                    }
                    if includingUntappdPending
                    {
                        db.pendingUntappd
                        {
                            switch $0
                            {
                            case .error(let e):
                                ret(.error(e: e))
                            case .value(let v):
                                data += v.0
                                let models = data.map { $0.toModel() }
                                ret(.value(v: (models, v.1)))
                            }
                        }
                    }
                    else
                    {
                        let models = data.map { $0.toModel() }
                        ret(.value(v: (models, v.1)))
                    }
                }
            }
        }
    }
    
    // PERF: we can filter these on the database level
    public func getModels(fromIncludingDate from: Date, toExcludingDate to: Date, withToken token: Token? = nil, includingDeleted: Bool = false, includingUntappdPending: Bool = false) throws -> ([Model], Token)
    {
        return try self.primaryStore.readTransaction
        { db -> ([Model], Token) in
            let v = try db.data(fromIncludingDate: from, toExcludingDate: to, afterTimestamp: token)
            var data = v.0.filter
            {
                if !includingDeleted && $0.metadata.deleted.v
                {
                    return false
                }
                if ($0.checkIn.untappdId.v != nil && !$0.checkIn.untappdApproved.v)
                {
                    return false
                }
                return true
            }
            if includingUntappdPending
            {
                data += try db.pendingUntappd().0
            }
            let models = data.map { $0.toModel() }
            return (models, v.1)
        }
    }
    
    public func getLastAddedModel() throws -> Model?
    {
        return try self.primaryStore.readTransaction
        { db -> Model? in
            let data = try db.lastAddedData()
            return data?.toModel()
        }
    }
}
