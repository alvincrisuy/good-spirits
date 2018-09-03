//
//  Formatting.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-31.
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
import DataLayer

public struct Format
{
    public static func format(abv: Double) -> String
    {
        return String.init(format: "%.1f%%", abv * 100)
    }
    
    public static func format(volume: Measurement<UnitVolume>) -> String
    {
        let numberFormatter = NumberFormatter.init()
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.minimumIntegerDigits = 1
        
        let measurementFormatter = MeasurementFormatter.init()
        measurementFormatter.unitStyle = .medium
        measurementFormatter.unitOptions = .providedUnit
        measurementFormatter.numberFormatter = numberFormatter
        
        return measurementFormatter.string(from: volume)
    }
    
    public static func format(unit: UnitVolume) -> String
    {
        let measurementFormatter = MeasurementFormatter.init()
        measurementFormatter.unitStyle = .long
        
        return measurementFormatter.string(from: unit)
    }
    
    // TODO: currency
    public static func format(price: Double) -> String
    {
        return String.init(format: (price.truncatingRemainder(dividingBy: 1) == 0 ? "$%.0f" : "$%.2f"), price)
    }
    
    public static func format(drinks: Double) -> String
    {
        return String.init(format: (drinks.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f"), drinks)
    }
    
    public static func format(calories: Double) -> String
    {
        return String.init(format: "%.0f", calories)
    }
    
    public static func format(style: DrinkStyle) -> String
    {
        return style.description
    }
}
