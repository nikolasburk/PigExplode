//
//  Utils.swift
//  PigExplode
//
//  Created by Nikolas Burk on 17/12/15.
//  Copyright © 2015 Nikolas Burk. All rights reserved.
//

import Foundation
import UIKit

// MARK: Geometry helpers

func DegreesToRadians(value: Double) -> Double {
    return value * M_PI / 180.0
}

func RadiansToDegrees(value: Double) -> Double {
    let degrees = value * 180.0 / M_PI
    return degrees < 0 ? degrees + 360.0 : degrees
}


// MARK: Extensions & other helpers

extension UIGravityBehavior {
    func addItems(items: [UIDynamicItem]) {
        for item in items {
            addItem(item)
        }
    }
}

extension UICollisionBehavior {
    func addItems(items: [UIDynamicItem]) {
        for item in items {
            addItem(item)
        }
    }
}

private var pushAssociationKey: UInt8 = 0
private var attachmentAssociationKey: UInt8 = 0
extension UIDynamicItem {
    var pushBehavior: UIPushBehavior? {
        get {
            return objc_getAssociatedObject(self, &pushAssociationKey) as? UIPushBehavior
        }
        set(newValue) {
            objc_setAssociatedObject(self, &pushAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    var attachmentBehavior: UIAttachmentBehavior? {
        get {
            return objc_getAssociatedObject(self, &attachmentAssociationKey) as? UIAttachmentBehavior
        }
        set(newValue) {
            objc_setAssociatedObject(self, &attachmentAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

extension UIView {
    
    func scale(scaleWithX scaleX: CGFloat, andY scaleY: CGFloat) {
        let newWidth = self.frame.size.width * scaleX
        let newHeight = self.frame.size.height * scaleY
        self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: newWidth, height: newHeight)
    }
    
    func setX(newX: CGFloat) {
        self.frame = CGRect(x: newX, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.height)
    }
    
}

// taken from http://stackoverflow.com/questions/25050309/swift-random-float-between-0-and-1
public extension CGFloat {
    
    public static func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    public static func random(min min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat.random() * (max - min) + min
    }
}

func even(number: Int) -> Bool {
    return number%2 == 0
}

