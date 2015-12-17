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
    
    // collision for the left and right bounds of the frame
    var collision: UICollisionBehavior!
    
    // attachment behavior comes into play as soon as the
    // user starts dragging on the screen, this is the common anchor
    var anchor: CGPoint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // instantiate animator and configure with gravity behaviour
        // (items are added later on dynamically)
        animator = UIDynamicAnimator(referenceView: view)
        
        gravity = UIGravityBehavior(items: [])
        animator.addBehavior(gravity)
        
        collision = UICollisionBehavior(items: [])
        let topLeft = self.view.bounds.origin
        let bottomLeft = CGPoint(x: self.view.bounds.origin.x, y: self.view.bounds.size.height)
        collision.addBoundaryWithIdentifier("left", fromPoint: topLeft, toPoint: bottomLeft)
        let topRight = CGPoint(x: self.view.bounds.size.width, y: 0.0)
        let bottomRight = CGPoint(x: self.view.bounds.size.width, y: self.view.bounds.size.height)
        collision.addBoundaryWithIdentifier("right", fromPoint: topRight, toPoint: bottomRight)
        animator.addBehavior(collision)
        
        // make sure that items are removed from the view once
        // they fall beneath the bottom
        gravity.action = { // [unowned self] in
            
            let itemsToRemove = self.gravity.items
                .map {$0 as! UIImageView }
                .filter() { $0.frame.origin.y > self.view.frame.size.height } // remove when falling beneath the bottom
            
            for item in itemsToRemove {
                // remove the push behaviour from the animator
                if let push = item.pushBehavior {
                    self.animator.removeBehavior(push)
                }

                // remove the attachment behaviour from the animator
                if let attachment = item.attachmentBehavior {
                    self.animator.removeBehavior(attachment)
                }
                
                // remove the item from the gravity behavior
                self.gravity.removeItem(item as UIDynamicItem)
                self.collision.removeItem(item as UIDynamicItem)
                
                // remove it from superview so its memory can be freed
                item.removeFromSuperview()
                
//                print("left views: \(self.view.subviews.count); behaviours: \(self.animator.behaviors.count)")
            }
        }
        
    }

    // catch ending touches on the screen
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        // retrieve location of touch
        let touch = touches.first!
        let location = touch.locationInView(self.view)

        // how many items should be created
        let numberOfPigs = 3
        let pigs = createExplosionImages(numberOfPigs, imageName: "pig", center: location)
        
        // using an old-style for-loop as we need the index 
        // when configuring the push behavior
        for var i = 0; i < numberOfPigs; i++ {
            
            // add to view
            self.view.addSubview(pigs[i])
            
            // create and configure the push behaviour
            let push = UIPushBehavior(items: [pigs[i]], mode: .Instantaneous)
            push.pushDirection = vectorForIndex(i, max: numberOfPigs)
            
            // add the push behaviour to the item and to the animator
            pigs[i].pushBehavior = push
            animator.addBehavior(push)
        }

        // associate all items with gravity
        self.gravity.addItems(pigs)
        self.collision.addItems(pigs)
        
        // clean up attachment behavior
        let activePigViews = self.view.subviews.filter { $0.tag == PIG_TAG && $0.attachmentBehavior != nil }
        let _ = activePigViews.map {
            if let attachment = $0.attachmentBehavior {
                self.animator.removeBehavior(attachment)
            }
            $0.attachmentBehavior = nil
        }
        
    }

    // catch dragging by the user
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        // retrieve location of touch and update anchor
        let touch = touches.first!
        let location = touch.locationInView(self.view)
        self.anchor = location
        
        // update the achor for existing items
        let activePigViews = self.view.subviews.filter { $0.tag == PIG_TAG && $0.attachmentBehavior != nil }
        let _ = activePigViews.map { $0.attachmentBehavior!.anchorPoint = self.anchor }
        
        // configure and add attachment behavior for new items
        let newPigViews = self.view.subviews.filter { $0.tag == PIG_TAG && $0.attachmentBehavior == nil }
        for newPigView in newPigViews {
            let attachment = UIAttachmentBehavior(item: newPigView, attachedToAnchor: self.anchor)
            newPigView.attachmentBehavior = attachment
            
            // gradually decrease the distance of the item and the anchor point with every move
            attachment.action = {
                attachment.length = attachment.length > 0 ? attachment.length / 1.01  : attachment.length
            }
            
            self.animator.addBehavior(attachment)
        }
    }
    
}


// MARK: Create image views

let PIG_TAG = 42
func createExplosionImages(number: Int, imageName: String, center: CGPoint) -> [UIImageView] {
    var pigs: [UIImageView] = []
    for var i = 0; i < number; i++ {
        // create and add an image view
        let pigView = UIImageView(image: UIImage(named: imageName))
        pigView.scale(scaleWithX: 0.1, andY: 0.1)
        pigView.center = center
        pigView.tag = PIG_TAG
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
