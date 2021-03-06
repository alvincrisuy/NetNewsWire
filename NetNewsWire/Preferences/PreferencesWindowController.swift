//
//  PreferencesWindowController.swift
//  NetNewsWire
//
//  Created by Brent Simmons on 8/1/15.
//  Copyright © 2015 Ranchero Software, LLC. All rights reserved.
//

import AppKit

private struct PreferencesToolbarItemSpec {

	let identifier: NSToolbarItem.Identifier
	let name: String
	let imageName: NSImage.Name
	
	init(identifierRawValue: String, name: String, imageName: NSImage.Name) {
		
		self.identifier = NSToolbarItem.Identifier(rawValue: identifierRawValue)
		self.name = name
		self.imageName = imageName
	}
}

private let toolbarItemIdentifierGeneral = "General"

class PreferencesWindowController : NSWindowController, NSToolbarDelegate {
	
	private let windowFrameName = "Preferences"
	fileprivate var viewControllers = [String: NSViewController]()
	fileprivate let toolbarItemSpecs: [PreferencesToolbarItemSpec] = {
		var specs = [PreferencesToolbarItemSpec]()
		specs += [PreferencesToolbarItemSpec(identifierRawValue: toolbarItemIdentifierGeneral, name: NSLocalizedString("General", comment: "Preferences"), imageName: NSImage.Name.preferencesGeneral)]
		return specs
	}()


	override func windowDidLoad() {

		let toolbar = NSToolbar(identifier: NSToolbar.Identifier(rawValue: "PreferencesToolbar"))
		toolbar.delegate = self
		toolbar.autosavesConfiguration = false
		toolbar.allowsUserCustomization = false
		toolbar.displayMode = .iconAndLabel
		toolbar.selectedItemIdentifier = toolbarItemSpecs.first!.identifier

		window?.showsToolbarButton = false
		window?.toolbar = toolbar

		window?.setFrameAutosaveName(NSWindow.FrameAutosaveName(rawValue: windowFrameName))
		
		switchToViewAtIndex(0)
	}

	// MARK: Actions

	@objc func toolbarItemClicked(_ sender: Any?) {


	}

	// MARK: NSToolbarDelegate

	func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

		guard let toolbarItemSpec = toolbarItemSpecs.first(where: { $0.identifier.rawValue == itemIdentifier.rawValue }) else {
			return nil
		}

		let toolbarItem = NSToolbarItem(itemIdentifier: toolbarItemSpec.identifier)
		toolbarItem.action = #selector(toolbarItemClicked(_:))
		toolbarItem.target = self
		toolbarItem.label = toolbarItemSpec.name
		toolbarItem.paletteLabel = toolbarItem.label
		toolbarItem.image = NSImage(named: toolbarItemSpec.imageName)

		return toolbarItem
	}

	func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {

		return toolbarItemSpecs.map { $0.identifier }
	}

	func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		
		return toolbarDefaultItemIdentifiers(toolbar)
	}

	func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		
		return toolbarDefaultItemIdentifiers(toolbar)
	}
}

private extension PreferencesWindowController {

	var currentView: NSView? {
		return window?.contentView?.subviews.first
	}

	func toolbarItemSpec(for identifier: String) -> PreferencesToolbarItemSpec? {

		return toolbarItemSpecs.first(where: { $0.identifier.rawValue == identifier })
	}

	func switchToViewAtIndex(_ index: Int) {

		let identifier = toolbarItemSpecs[index].identifier
		switchToView(identifier: identifier.rawValue)
	}

	func switchToView(identifier: String) {

		guard let toolbarItemSpec = toolbarItemSpec(for: identifier) else {
			assertionFailure("Preferences window: no toolbarItemSpec matching \(identifier).")
			return
		}

		guard let newViewController = viewController(identifier: identifier) else {
			assertionFailure("Preferences window: no view controller matching \(identifier).")
			return
		}
		
		if newViewController.view == currentView {
			return
		}

		newViewController.view.nextResponder = newViewController
		newViewController.nextResponder = window!.contentView

		window!.title = toolbarItemSpec.name

		resizeWindow(toFitView: newViewController.view)

		if let currentView = currentView {
			window!.contentView?.replaceSubview(currentView, with: newViewController.view)
		}
		else {
			window!.contentView?.addSubview(newViewController.view)
		}

		window!.makeFirstResponder(newViewController.view)
	}

	func viewController(identifier: String) -> NSViewController? {

		if let cachedViewController = viewControllers[identifier] {
			return cachedViewController
		}

		let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Preferences"), bundle: nil)
		guard let viewController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: identifier)) as? NSViewController else {
			assertionFailure("Unknown preferences view controller: \(identifier)")
			return nil
		}

		viewControllers[identifier] = viewController
		return viewController
	}
	
	func resizeWindow(toFitView view: NSView) {
		
		let viewFrame = view.frame
		let windowFrame = window!.frame
		let contentViewFrame = window!.contentView!.frame
		
		let deltaHeight = NSHeight(contentViewFrame) - NSHeight(viewFrame)
		let heightForWindow = NSHeight(windowFrame) - deltaHeight
		let windowOriginY = NSMinY(windowFrame)// + deltaHeight
		
		var updatedWindowFrame = windowFrame
		updatedWindowFrame.size.height = heightForWindow
		updatedWindowFrame.origin.y = windowOriginY
		updatedWindowFrame.size.width = NSWidth(viewFrame)
		
		var updatedViewFrame = viewFrame
		updatedViewFrame.origin = NSZeroPoint
		if viewFrame != updatedViewFrame {
			view.frame = updatedViewFrame
		}
		
		if windowFrame != updatedWindowFrame {
			window!.setFrame(updatedWindowFrame, display: true, animate: true)
		}
	}
}
