### Building an _explosion_ effect with `UIKitDynamics`

In this post, I want to show how the `UIKitDynamics` API can be used to create a fun *explosion* of images whenever a user taps on the screen. In particular, I am going to use `UIPushBehavior` and `UIGravityBehavior` to achieve this.

![Creating an explosion effect with images](http://nikolasburk.com/wp-content/uploads/2015/12/demo_short.gif)

If you want to follow along, start by setting up setup an empty Xcode Project (*Single View Application* for *iPhone* will do). Note that this repository contains an evolving version of the code [Github page][1] and this article is crossposted from my [actual blog](http://nikolasburk.com/?page_id=70).

#### Getting started with `UIDynamicAnimator`

At first add a property to the empty `ViewController` like so:

```swift
var animator: UIDynamicAnimator!
```

The `animator` is the major component in our `UIKitDynamics`setup. It is going to control all the effects and behaviors that we are introducing in our app. It can be seen as the *intermediator* between the underlying iOS physics engine and our dynamic items. Every effect that we want ot use has to somehow be *registered* with our `animator`.

We are then instantiating the `animator` in `viewDidLoad()`:

```swift
animator = UIDynamicAnimator(referenceView: view)
```    

#### Catching user taps to add items to the view

As a next step, we want to add a number of images to our view that will later spread out and fall down. I am using a [*pig emoji*][2] as an image, so I will refer to my images as `pigs`.

First we're writing a function that creates a number of `UIImageViews` and returns them.

```swift
let pigTag = 42
func createExplosionImages(number: Int, imageName: String, center: CGPoint) -> [UIImageView] {
    var pigs: [UIImageView] = []
    for var i = 0; i < number; i++ {
        // create and add an image view
        let pigView = UIImageView(image: UIImage(named: imageName))
        pigView.scale(scaleWithX: 0.1, andY: 0.1)
        pigView.center = center
        pigView.tag = pigTag
        pigs.append(pigView)
    }
    return pigs
}
```

Note that the function `scale` is a utility function that I implemented [here][3].

Then we override `touchesEnded()`, a function defined in `UIResponder` which is the superclass of `UIViewController`. It gets called within our `ViewController` whenever the user's finger *leaves* the screen. Whenever that happens, we want to add our images to the view:

```swift
// catch ending touches on the screen
override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {

    // retrieve location of touch
    let touch = touches.first!
    let location = touch.locationInView(self.view)

    // create the images
    let numberOfPigs = 3
    let pigs = createExplosionImages(numberOfPigs, imageName: "pig", center: location)

    // add all images to the view (using c-style for because we need the index later)
    for var i = 0; i < numberOfPigs; i++ {

        // add to view
        self.view.addSubview(pigs[i])
    }
}
```    

With this code, we can run the application, touch the screen of our `ViewController` and see how our images are created and added to the view. Be aware that it'll look like you're only adding one image at a time, as all the images have exactly the same frame and are thus hidden behind the foremost image.

#### Use `UIPushBehavior` for dispersion

Next, we want to create the *explosion* effect, that is we want the images to *disperse* right after we add them to the view. That is exactly what we can use `UIPushBehavior` for.

`UIPushBehavior` can be used to apply a force to an item, either in a *continuous* or *instantaneous* way. The difference is that when using the latter, the force will gradually decline so that the item gets to a halt after a while whereas for *continuous* push behavior, the item will be exposed to the force until told otherwise in the code.

As we want to only have a short, *spring*-like push, we are using the *instantaneous* version of `UIPushBehavior` by passing `.Instantaneous` during initilization. We also need to add the `items` that the behavior should be applied on. In the `for`-loop, right after we added the images to the view, we add the following code:

```swift
let push = UIPushBehavior(items: [pigs[i]], mode: .Instantaneous)
push.pushDirection = vectorForIndex(i, max: numberOfPigs)
```

And implement `vectorForIndex()` like so:

```swift
func vectorForIndex(index: Int, max: Int) -> CGVector {

    // the furthest points on the x-scale
    let xStart = -0.75, xEnd = 0.75

    // depending on the number of items, calculate the default distance
    let distance = (abs(xStart) + abs(xEnd)) / Double(max*2)

    // x goes from start to end depending on index and max
    let x = even(index) ? xStart + (distance * Double(index)) : xEnd - (distance * Double(index))

    return CGVector(dx: CGFloat(x), dy: -1)
}
```    

There's a lot happening, so let's look at it in more detail. At first, we create a `UIPushBehavior` for every image. We need to create individual push behaviors for the images because we want them to disperse into different directions. The `pushDirection` is a property of each `UIPushBehavior` instance, so we need to calculate a specific `pushDirection` for every image, otherwise we'll have the same problem as before that images aren't visible because their frames are identical.

That's what we're using `vectorForIndexIndex()` for. It is important to note that the `pushDirection` can be expressed in two ways:

1. by creating a `CGVector` and setting the `pushDirection` (much like we did in the code above)
2. by setting the `angle` and `magnitude` properties

These two approaches are equivalent, and using one will override the other. This makes sense, as vectors are able to express an `angle` as well as a `magnitude`, so these two properties will be set (and potentially overridden) automatically if you set the `pushDirection` with a `CGVector`.

As a last step, we need to add the created behavior to our `animator` for it to have any effect. The `animator` has a property `behaviors` that keeps track of all the behaviors currently in place. Put the following line right after setting the `pushDirection` in the `for`-loop.

```swift
animator.addBehavior(push)
```

When running this code now, you'll see a number of images floating away towards the top of the screen and then leaving the visible area. Good, so we introduced our first behavior!

#### Use `UIGravityBehavior` to make things fall on the ground

`UIGravityBehavior` can be used, as its name suggests, to apply gravitational forces to your items. These forces can be controlled with respect to their strength and direction. As with `UIPushBehavior`, this can either be done by specifying `angle` and `magnitude` or the `gravityDirection` also expressed as a `CGVector`. In our case we want good old gravity from planet earth, that is pulling items *downwards*, which is the default for `UIGravityBehavior`, so we don't have to put our hands on `gravityDirection`.

To implement the gravity, we'll take the following approach. At first we add another property to our `ViewController`:

```swift
var gravity: UIGravityBehavior!
```    

Which we instantiate in `viewDidLoad()` right after instantiating the `animator`. We also add the newly created behavior to the `animator` right away:

```swift
gravity = UIGravityBehavior(items: [])
animator.addBehavior(gravity)
```    

Why are we only using a single property for the `UIGravityBehavior` but earlier created multiple instances of `UIPushBehavior` (one for every item)? As I mentioned, all our items should have different characteristics for the push behavior (i.e. a varying `pushDirection`), whereas `gravity` should be consistent among all our items. This allows us to to create `gravity` only once and then dynamically add and remove items to and from it. The `items` of a behavior can be controlled dynamically, while the `pushDirection` or `gravityDirection` can not be associated with specific items but always applies to *all* items that are associated with a behavior.

The only thing left to do now is adding our items to the `gravity` to make sure the gravitational forces are applied to them. As the last line in the `for`-loop in `touchesEnded()`, add the following:

```swift
self.gravity.addItem(pig)
```

Now, we can see that with every tap, the images are not only pushed upwards but fall down to the bottom shortly after.

One thing that is a bit annoying right now is that the explosion is *symmetric*. That's because of the way we calculate the `pushDirection` for the items. Let's modify this a bit and introduce some randomness, Modify `vectorForIndex()` by adding the following lines at the end and adjusting the return statement:

```swift
let halfDistance = distance / 2
let xRand = CGFloat.random(min: CGFloat(-halfDistance), max: CGFloat(halfDistance))
let yRand = CGFloat.random(min: CGFloat(-1), max: CGFloat(0))

return CGVector(dx: CGFloat(x) + xRand, dy: yRand)
```

When running the code now, you'll see that the dispersion of the items has lost its symmetry and feels a bit more like a real explosion.

#### Cleaning up

We now have our desired behavior, but we aren't done yet! What happens to our items once they go off screen? Well, at the moment they will just keep on falling forever causing a potential risk for our memory usage if we create a whole lot of them. Don't believe me? Let's investigate!

Thanks to the `action` property that is common to all subclasses of `UIDynamicBehavior` (which our behaviors are), we can observe every animation step that is performed by the `gravity` and `push` behaviors. Let's do so by adding the following code in `viewDidLoad()` right after we added `gravity` to the `animator`:

```swift
gravity.action = { 
  for item in self.gravity.items {
    print(item.frame)
  }
}
```

Run the code, tap the screen once and see what happens. We're getting an infinite console output, logging every new position of the items that we created, even after they've left the visible area of the screen.

Luckily, we can use the `action` property of our `UIGravityBehavior` to perform clean up actions as well. So, let's delete the logging statement from before and add the following code instead:

```swift
gravity.action = { 
    let itemsToRemove = self.gravity.items
       .map {$0 as! UIImageView }
       .filter() { $0.frame.origin.y > self.view.frame.size.height }
    for item in itemsToRemove {
       self.gravity.removeItem(item as UIDynamicItem)
       item.removeFromSuperview()
    }
    print("remaining items: \(self.view.subviews.count)")
}
```

From all the items that are currently associated with our `gravity`, we only are interested in those who have fallen beneath the bottom of the screen. We're using `filter` to express this requirement and store the results in `itemsToRemove`. We then iterate over those and remove the items from the `gravity` behavior as well as from our `view`.

When running the code now and tapping the screen, we see that the logging stops right after all items went off the visible area. As for cleaning up, there's still one step left that's a bit more subtle but is also a potential cause for memory issues when used with a vast amount of items. Adjust the logging statement to the following and tap the screen a few times:

```swift
print("remaining items: \(self.animator.behaviors.count)")
```

You can see the number of behaviors that are associated with our `animator` increase and there's currently nothing we can do about it. Again, this is obviously not a desired behavior and we should always free the memory of objects that we don't require any more in our program, as is the case with all the `push` behaviors that we have individually added to our items and that the `animator` still keeps track of.

This issue can be solved in a number of ways. For the sake of keeping it short for this tutorial, I decided to add a property to the `UIDynamicItem` protocol. This is possible by jumping through a few hoops that I won't discuss in detail (check [NSHipster][4] and [SO][5] for that), instead here is the code that you should add somewhere in your project:

```swift
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
```

This allows you to add the `UIPushBehavior` to the items directly and even better, access and remove it from the `animator` when necessary. Having this code in place, we only need to make sure that every item gets associated with its `push` behavior. Add the following line in the `for`-loop right before adding `push` to the `animator`:

```swift
pigs[i].pushBehavior = push
```

As a last step, we now need to remove the `UIPushBehavior` instance from the `animator`. We do this in the closure that we have set as the `action` property of `gravity` right before we call `item.removeFromSuperview()`:

```swift
if let push = item.pushBehavior { self.animator.removeBehavior(push) }
```

Run the code again and tap the screen a few times. You'll notice that the number of behaviors that are associated with the `animator` drops down to `1` every time all items have left the screen. The one remaining behavior is of course the `gravity` that remains there indefinitely.

 [1]: https://github.com/nikolasburk/PigExplode
 [2]: https://www.marcoklobas.net/sharing/MacHeist/pig.png
 [3]: https://github.com/nikolasburk/PigExplode/blob/master/PigExplode/Utils.swift#L65
 [4]: http://nshipster.com/associated-objects/
 [5]: http://stackoverflow.com/questions/25426780/swift-extension-stored-properties-alternative


