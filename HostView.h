//
//  HostView.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 10/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Cinematroller;
@class HIDRemote;

@interface HostView : NSView {
@private
	NSMutableArray* controllerStack;
	CALayer* lowestOverlay;
	HIDRemote* remote;
	BOOL inSwap;
	BOOL preventSound;
}

@property (getter=isRemoteActive) BOOL remoteActive;

@property (readonly) NSArray* controllers;
@property (readonly) Cinematroller* currentController;
- (void)pushController:(Cinematroller*)newController;
- (Cinematroller*)popController;
- (NSArray*)popToController:(Cinematroller*)newController;
- (NSArray*)popToRootController;

- (void)preventDefaultSound;

@end
