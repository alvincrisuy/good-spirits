//
//  Model.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

public struct Model
{
    public typealias ID = UInt64
    
    public struct CheckIn
    {
        public let id: ID
        public let untappdId: ID?
        public let time: Date
        public let drink: Drink
    }
    
    public struct Drink
    {
        public enum Style: String
        {
            case beer
            case wine
            case sake
            
            // TODO: move to data file?
            public var defaultABV: Double
            {
                get
                {
                    switch self
                    {
                    case .beer: return 0.065
                    case .wine: return 0.14
                    case .sake: return 0.17
                    }
                }
            }
        }
        
        public let name: String?
        public let style: Style
        public let abv: Double
        public let price: Double?
        public let volume: Measurement<UnitVolume>
    }
}

public extension Model
{
    // TODO: maybe this does not belong here
    public static func assetNameForDrink(_ drink: Model.Drink) -> String
    {
        let epsilon = Measurement<UnitVolume>.init(value: 0.5, unit: .fluidOunces)
        
        switch drink.style
        {
        case .beer:
            if drink.volume >= Measurement<UnitVolume>.init(value: 200, unit: .milliliters) && drink.volume <= Measurement<UnitVolume>.init(value: 300, unit: .milliliters)
            {
                return "lowball"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 8, unit: .fluidOunces), delta: Measurement<UnitVolume>.init(value: 2, unit: .fluidOunces))
            {
                return "snifter"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 12, unit: .fluidOunces), delta: Measurement<UnitVolume>.init(value: 1, unit: .fluidOunces))
            {
                return "tulip"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 500, unit: .milliliters), delta: Measurement<UnitVolume>.init(value: 10, unit: .milliliters))
            {
                return "weizen_glass"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 16, unit: .fluidOunces), delta: epsilon)
            {
                return "pint_shaker"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 20, unit: .fluidOunces), delta: epsilon)
            {
                return "pint_nonic"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 1000, unit: .milliliters), delta: epsilon)
            {
                return "beer_mug"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 2000, unit: .milliliters), delta: epsilon)
            {
                return "beer_boot"
            }
        case .wine:
            if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 3, unit: .fluidOunces), delta: epsilon)
            {
                return "wine_glass_small"
            }
            else if drink.volume >= Measurement<UnitVolume>.init(value: 4.5, unit: .fluidOunces) && drink.volume <= Measurement<UnitVolume>.init(value: 8, unit: .fluidOunces)
            {
                return "wine_glass_big"
            }
        case .sake:
            if drink.volume <= Measurement<UnitVolume>.init(value: 2, unit: .fluidOunces)
            {
                return "shot_glass"
            }
        }
        
        return "tall_glass"
    }
}