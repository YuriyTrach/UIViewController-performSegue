//
//  PerformSequeExtention.swift
//  WIZTR
//
//  Created by Yuriy Trach on 5/31/16.
//  Copyright © 2016 Lemberg Solutions. All rights reserved.
//

import UIKit
extension UIViewController {
	struct AssociatedKey {
		static var ClosurePrepareForSegueKey = "ClosurePrepareForSegueKey"
		static var token: dispatch_once_t = 0
	}
	
	typealias ConfiguratePerformSegue = (UIStoryboardSegue) -> Void
	func performSegueWithIdentifier(identifier: String, sender: AnyObject?, configurate: ConfiguratePerformSegue?) {
		swizzlingPrepareForSegue()
		configuratePerformSegue = configurate
		performSegueWithIdentifier(identifier, sender: sender)
	}
	
	private func swizzlingPrepareForSegue() {
		dispatch_once(&AssociatedKey.token) {
			let originalSelector = #selector(UIViewController.prepareForSegue(_:sender:))
			let swizzledSelector = #selector(UIViewController.closurePrepareForSegue(_:sender:))
			
			let instanceClass = UIViewController.self
			let originalMethod = class_getInstanceMethod(instanceClass, originalSelector)
			let swizzledMethod = class_getInstanceMethod(instanceClass, swizzledSelector)
			
			let didAddMethod = class_addMethod(instanceClass, originalSelector,
			                                   method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
			
			if didAddMethod {
				class_replaceMethod(instanceClass, swizzledSelector,
				                    method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
			} else {
				method_exchangeImplementations(originalMethod, swizzledMethod)
			}
		}
	}
	
	func closurePrepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		configuratePerformSegue?(segue)
		closurePrepareForSegue(segue, sender: sender)
		configuratePerformSegue = nil
	}
	
	var configuratePerformSegue: ConfiguratePerformSegue? {
		get {
			let box = objc_getAssociatedObject(self, &AssociatedKey.ClosurePrepareForSegueKey) as? Box
			return box?.value ?? nil
		}
		set {
			objc_setAssociatedObject(self, &AssociatedKey.ClosurePrepareForSegueKey, Box(newVal: newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
		}
	}
}

class Box: NSObject{
	typealias ConfiguratePerformSegue = (UIStoryboardSegue) -> ()
	var value: ConfiguratePerformSegue?
	init(newVal: ConfiguratePerformSegue?) {
		value = newVal
	}
}