//
//  CheckInDrawerViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-1.
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

import UIKit
import DrawerKit

public class CheckInDrawerViewController: UIViewController, DrawerPresentable, DrawerCoordinating
{
    @IBOutlet var buttonStack: UIStackView!
    @IBOutlet var confirmButton: UIButton?
    @IBOutlet var deleteButton: UIButton?
    @IBOutlet var closeButton: UIButton?
    @IBOutlet var stackView: UIView!
    @IBOutlet var titleLabel: UILabel!
    
    public var drawerDisplayController: DrawerDisplayController?
    
    public var standardConfiguration: DrawerConfiguration
    {
        var configuration = DrawerConfiguration.init()
        configuration.isFullyPresentableByDrawerTaps = false
        configuration.flickSpeedThreshold = 0
        configuration.timingCurveProvider = UISpringTimingParameters(dampingRatio: 0.8)
        configuration.cornerAnimationOption = .alwaysShowBelowStatusBar
        
        // KLUDGE: prevents full-sreen mode
        configuration.upperMarkGap = 100000
        
        var handleViewConfiguration = HandleViewConfiguration()
        handleViewConfiguration.autoAnimatesDimming = false
        configuration.handleViewConfiguration = handleViewConfiguration
        
        let drawerShadowConfiguration = DrawerShadowConfiguration(shadowOpacity: 0.25,
                                                                  shadowRadius: 5,
                                                                  shadowOffset: .zero,
                                                                  shadowColor: .black)
        configuration.drawerShadowConfiguration = drawerShadowConfiguration
        
        return configuration
    }
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if let closeButton = self.closeButton
        {            
            self.confirmButton?.setTitle("Accept", for: .normal)
        }
        
        // TODO: why does this not work with system buttons?
        let themeColor = Appearance.themeColor.withAlphaComponent(1)
        let darkenedThemeColor = Appearance.darkenedThemeColor
        let darkenedTextColor = UIColor.init(white: 0.9, alpha: 1)
        self.confirmButton?.setBackgroundImage(themeColor.resizableImage(withCornerRadius: 8), for: .normal)
        self.confirmButton?.setBackgroundImage(darkenedThemeColor.resizableImage(withCornerRadius: 8), for: .highlighted)
        self.confirmButton?.setBackgroundImage(darkenedThemeColor.resizableImage(withCornerRadius: 8), for: .selected)
        self.confirmButton?.setBackgroundImage(darkenedThemeColor.resizableImage(withCornerRadius: 8), for: [.highlighted, .selected])
        self.confirmButton?.setTitleColor(.white, for: .normal)
        self.confirmButton?.setTitleColor(darkenedTextColor, for: .highlighted)
        self.confirmButton?.setTitleColor(darkenedTextColor, for: .selected)
        self.confirmButton?.setTitleColor(darkenedTextColor, for: [.highlighted, .selected])
        self.confirmButton?.layer.cornerRadius = 8
        self.confirmButton?.adjustsImageWhenHighlighted = false
        self.confirmButton?.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.semibold)
        self.confirmButton?.contentEdgeInsets = .init(top: 8, left: 0, bottom: 8, right: 0)
        
        //self.confirmButton?.addTarget(self, action: #selector(changeShadowDown), for: .touchDown)
        //self.confirmButton?.addTarget(self, action: #selector(changeShadowDown), for: .touchDragInside)
        //self.confirmButton?.addTarget(self, action: #selector(changeShadowUp), for: .touchUpInside)
        //self.confirmButton?.addTarget(self, action: #selector(changeShadowUp), for: .touchUpOutside)
        //self.confirmButton?.addTarget(self, action: #selector(changeShadowUp), for: .touchDragOutside)
        //self.confirmButton?.layer.shadowColor = UIColor.black.cgColor
        //self.confirmButton?.layer.shadowOpacity = 0.2
        //self.confirmButton?.layer.shadowRadius = 2
        //self.confirmButton?.layer.shadowOffset = CGSize.init(width: 0, height: 1.5)
        
        self.confirmButton?.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        
        if let deleteButton = self.deleteButton
        {
            let redColor = Appearance.redProgressColor.darkened(by: 0.0)
            let darkenedRedColor = redColor.darkened(by: 0.2)
            deleteButton.setBackgroundImage(redColor.resizableImage(withCornerRadius: 8), for: .normal)
            deleteButton.setBackgroundImage(darkenedRedColor.resizableImage(withCornerRadius: 8), for: .highlighted)
            deleteButton.setBackgroundImage(darkenedRedColor.resizableImage(withCornerRadius: 8), for: .selected)
            deleteButton.setBackgroundImage(darkenedRedColor.resizableImage(withCornerRadius: 8), for: [.highlighted, .selected])
            deleteButton.setTitleColor(.white, for: .normal)
            deleteButton.setTitleColor(darkenedTextColor, for: .highlighted)
            deleteButton.setTitleColor(darkenedTextColor, for: .selected)
            deleteButton.setTitleColor(darkenedTextColor, for: [.highlighted, .selected])
            deleteButton.layer.cornerRadius = 8
            deleteButton.adjustsImageWhenHighlighted = false
            deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.semibold)
            deleteButton.contentEdgeInsets = .init(top: 8, left: 0, bottom: 8, right: 0)
            
            deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        }
        
        self.closeButton?.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        self.titleLabel?.textColor = Appearance.themeColor.withAlphaComponent(1)
    }
    
    @IBAction func confirmTapped(_ button: UIControl)
    {
        confirmCallback()
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deleteTapped(_ button: UIControl)
    {
        confirmCallback(true)
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeTapped(_ button: UIControl)
    {
        dismiss(animated: true, completion: nil)
    }
    
    open func confirmCallback(_ deleted: Bool = false) {}
    
    public var heightOfPartiallyExpandedDrawer: CGFloat
    {
        let view = self.view!
        view.layoutIfNeeded() // AB: ensures autolayout is done
        
        let safeArea: CGFloat
        
        // KLUDGE: should pull this from parent VC, but we need this to work as soon as the view is loaded
        if #available(iOS 11.0, *)
        {
            let window = UIApplication.shared.keyWindow
            let bottomPadding = window?.safeAreaInsets.bottom
            safeArea = bottomPadding ?? 0
        }
        else
        {
            safeArea = 0
        }
        
        return view.convert(CGPoint.init(x: 0, y: self.stackView.bounds.maxY), from: self.stackView).y + safeArea + 16
    }
}
