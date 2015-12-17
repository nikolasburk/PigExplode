//
//  ViewController.swift
//  PigExplode
//
//  Created by Nikolas Burk on 16/12/15.
//  Copyright © 2015 Nikolas Burk. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    // the main component that contains behaviours that
    // are associated with objects
    var animator: UIDynamicAnimator!
    
    // gravity behaviour that'll be added to the items dynamically
    // with every explosion
    var gravity: UIGravityBehavior!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // instantiate animator and configure with gravity behaviour
        // (items are added later on dynamically)
        animator = UIDynamicAnimator(referenceView: view)
        gravity = UIGravityBehavior(items: [])
        animator.addBehavior(gravity)
        
        // make sure that items are removed from the view once
        // they fall beneath the bottom
        gravity.action = { [unowned self] in
            let itemsToRemove = self.gravity.items
                .map {$0 as! UIImageView }
                .filter() { $0.frame.origin.y > self.view.frame.size.height } // remove when falling beneath the bottom
            for item in itemsToRemove {
                // remove the push behaviour from the animator
                if let push = item.pushBehavior {
                    self.animator.removeBehavior(push)
                }

                // remove the item from the gravity behavior
                self.gravity.removeItem(item as UIDynamicItem)
                
                // remove it from superview so its memory can be freed
                item.removeFromSuperview()
            }
        }
    }

    
    // check for touches on the screen
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        // retrieve location of touch
        let touch = touches.first!
        let location = touch.locationInView(self.view)

        // how many objects are being created
        let numberOfPigs = 6
        let pigs = createExplosionImages(numberOfPigs, imageName: "pig", center: location)
        
        // using an old-style for-loop as we need the index 
        // when configuring the push behavior
        for var i = 0; i < numberOfPigs; i++ {
            
            // add to view
            self.view.addSubview(pigs[i])
            
            // create and configure the push behaviour
            let push = UIPushBehavior(items: [pigs[i]], mode: .Instantaneous)
            push.pushDirection = vectorForIndex(i, max: numberOfPigs)
            push.active = true
            
            // add the push behaviour to the item and to the animator
            pigs[i].pushBehavior = push
            animator.addBehavior(push)
        }

        // associate all items with gravity
        self.gravity.addItems(pigs)
        print("touches ended")
    }
}

// MARK: Create image views

func createExplosionImages(number: Int, imageName: String, center: CGPoint) -> [UIImageView] {
    var pigs: [UIImageView] = []
    for var i = 0; i < number; i++ {
        // create and add an image view
        let pigView = UIImageView(image: UIImage(named: imageName))
        pigView.scale(scaleWithX: 0.1, andY: 0.1)
        pigView.center = center
        pigs.append(pigView)
    }
    return pigs
}


// MARK: Helpers to calculate the push directions of the items

// introduces randomness to avoid symmetric explosion
func vectorForIndex(index: Int, max: Int) -> CGVector {

    // the furthest points on the x-scale
    let xStart = -0.75, xEnd = 0.75
    
    // depending on the number of items, calculate the default distance
    let distance = (abs(xStart) + abs(xEnd)) / Double(max*2)

    // x goes from start to end depending on index and max
    let x = even(index) ? xStart + (distance * Double(index)) : xEnd - (distance * Double(index))
    
    // introduce some randomness to avoid a symmetric appearance
    let halfDistance = distance / 2
    let xRand = CGFloat.random(min: CGFloat(-halfDistance), max: CGFloat(halfDistance))
    let yRand = CGFloat.random(min: CGFloat(-1), max: CGFloat(0))
    
    return CGVector(dx: CGFloat(x) + xRand, dy: yRand)
}

// can be used to create a symmetric explosion
func vectorForIndexIndexWithoutRandomness(index: Int, max: Int) -> CGVector {

    // the furthest points on the x-scale
    let xStart = -0.75, xEnd = 0.75
    
    // depending on the number of items, calculate the default distance
    let distance = (abs(xStart) + abs(xEnd)) / Double(max*2)
    
    // x goes from start to end depending on index and max
    let x = even(index) ? xStart + (distance * Double(index)) : xEnd - (distance * Double(index))
    
    return CGVector(dx: CGFloat(x), dy: -1)
}


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

private var pushAssociationKey: UInt8 = 0
extension UIDynamicItem {
    var pushBehavior: UIPushBehavior? {
        get {
            return objc_getAssociatedObject(self, &pushAssociationKey) as? UIPushBehavior
        }
        set(newValue) {
            objc_setAssociatedObject(self, &pushAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN)
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

