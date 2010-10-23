//
//  HostView.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 10/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "HostView.h"
#import <QuartzCore/QuartzCore.h>

#include "PowerFix.h"

#import "Cinematroller.h"
#import "TLSFX.h"

#import "HIDRemote.h"


@interface HostView () <HIDRemoteDelegate>
- (void)initializeRemote;
@end


@implementation HostView

@synthesize controllers = controllerStack;

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self) {
		self.layer = [CALayer layer];
		self.layer.layoutManager = self;
		controllerStack = [NSMutableArray new];
		remote = [HIDRemote new];
		[self initializeRemote];
		// get these ready for fast response
		(void)[TLSFX sharedSFX];
	}
	return self;
}

- (void)awakeFromNib {
	self.wantsLayer = YES;
}

- (void)layoutSublayersOfLayer:(CALayer*)theLayer {
	NSParameterAssert(theLayer == self.layer);
	for (CALayer* sublayer in theLayer.sublayers) {
		sublayer.frame = theLayer.bounds;
		// not sure why this is necessary for proper layout
		[sublayer setNeedsLayout];
	}
}


#pragma mark Controller stack management

- (Cinematroller*)currentController {
	NSAssert(controllerStack, @"View not properly initialized");
	return [controllerStack lastObject];
}

- (void)showController:(Cinematroller*)newController
			 insteadOf:(Cinematroller*)prevController
{
	NSAssert([NSThread isMainThread], @"Best called on main thread");
	NSAssert(self.layer, @"Not ready to show controllers");
	NSAssert(!inSwap, @"Nested controller management not supported");
	inSwap = YES;
	[newController layerWillAppear];
	[prevController layerWillDisappear];
	if (prevController && newController) {
		[self.layer replaceSublayer:(prevController.layer)
							   with:(newController.layer)];
	}
	else if (newController) {
		if (lowestOverlay) {
			[self.layer insertSublayer:newController.layer
								 below:lowestOverlay];
		}
		else {
			[self.layer addSublayer:newController.layer];
		}
	}
	else if (prevController) {
		[prevController.layer removeFromSuperlayer];
	}
	[self.layer layoutSublayers];
	inSwap = NO;
	[prevController layerDidDisappear];
	[newController layerDidAppear];
}

- (void)pushController:(Cinematroller*)newController {
	Cinematroller* prevController = self.currentController;
	[controllerStack addObject:newController];
	newController.hostView = self;
	newController.parentController = prevController;
	if (newController.overlayLayer) {
		[self.layer addSublayer:(newController.overlayLayer)];
		if (!lowestOverlay) {
			lowestOverlay = newController.overlayLayer;
		}
	}
	[self showController:newController insteadOf:prevController];
}

- (Cinematroller*)popController {
	Cinematroller* oldController = self.currentController;
	oldController.parentController = nil;
	oldController.hostView = nil;
	[controllerStack removeLastObject];
	Cinematroller* newController = self.currentController;
	[oldController.overlayLayer removeFromSuperlayer];
	if (lowestOverlay == oldController.overlayLayer) {
		lowestOverlay = nil;
	}
	[self showController:newController insteadOf:oldController];
	return oldController;
}

- (NSArray*)popToController:(Cinematroller*)newController {
	NSParameterAssert(newController.hostView == self);
	
	NSMutableArray* poppeds = [NSMutableArray array];
	while (self.currentController != newController) {
		Cinematroller* popped = [self popController];
		[poppeds addObject:popped];
	}
	return poppeds;
}

- (NSArray*)popToRootController {
	Cinematroller* root = [self.controllers objectAtIndex:0];
	return [self popToController:root];
}


#pragma mark Button actions

typedef enum {
	ButtonUp,
	ButtonDown,
	ButtonLeft,
	ButtonRight,
	ButtonSelect,
	ButtonMenu
} Button;

- (void)performButton:(Button)theButton {
	preventSound = NO;
	NSString* soundEffect = TLSFXNameClick;
	switch (theButton) {
		case ButtonUp:
			[self.currentController buttonUp];
			break;
		case ButtonDown:
			[self.currentController buttonDown];
			break;
		case ButtonLeft:
			[self.currentController buttonLeft];
			break;
		case ButtonRight:
			[self.currentController buttonRight];
			break;
		case ButtonSelect:
			soundEffect = TLSFXNameClunk;
			[self.currentController buttonSelect];
			break;
		case ButtonMenu:
			soundEffect = TLSFXNameClank;
			[self.currentController buttonMenu];
			break;
	}
	
	[NSCursor setHiddenUntilMouseMoves:YES];
	if (!preventSound) {
		[[TLSFX sharedSFX] playSound:soundEffect];
	}
}

- (void)preventDefaultSound {
	preventSound = YES;
}


#pragma mark Event handling

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (void)resetCursorRects {
	[self addCursorRect:[self visibleRect]
				 cursor:[NSCursor crosshairCursor]];
}

- (void)moveLeft:(id)sender {
	(void)sender;
	[self performButton:ButtonLeft];
}

- (void)moveRight:(id)sender {
	(void)sender;
	[self performButton:ButtonRight];
}

- (void)moveUp:(id)sender {
	(void)sender;
	[self performButton:ButtonUp];
}

- (void)moveDown:(id)sender {
	(void)sender;
	[self performButton:ButtonDown];
}

- (void)performClick:(id)sender {
	(void)sender;
	[self performButton:ButtonSelect];
}

- (void)cancelOperation:(id)sender {
	(void)sender;
	[self performButton:ButtonMenu];
}

- (BOOL)performKeyEquivalent:(NSEvent*)theEvent {
	[NSCursor setHiddenUntilMouseMoves:YES];
	NSString* pressed = [theEvent charactersIgnoringModifiers];
	if ([pressed length]) {
		unichar key =  [pressed characterAtIndex:0];
		//printf("0x%x\n", key);
		switch (key) {
			case NSEnterCharacter:
			case NSCarriageReturnCharacter:
			case NSNewlineCharacter:
				[self performClick:self];
				return YES;
			case NSBackspaceCharacter:
			case NSDeleteCharacter:
			case NSDeleteFunctionKey:
			case NSMenuFunctionKey:
				[self cancelOperation:self];
				return YES;
		}
	}
	return [super performKeyEquivalent:theEvent];
}

- (void)mouseDown:(NSEvent*)theEvent {
	(void)theEvent;
	NSBeep();
}

- (void)swipeWithEvent:(NSEvent *)event {
    CGFloat x = [event deltaX];
    CGFloat y = [event deltaY];
	if (y > 0) {
		[self performButton:ButtonUp];
	}
	else if (y < 0) {
		[self performButton:ButtonDown];
	}
	else if (x > 0) {
		[self performButton:ButtonLeft];
	}
	else if (x < 0) {
		[self performButton:ButtonRight];
	}
}


#pragma mark Remote handling

- (BOOL)isRemoteActive {
	return remote.isStarted;
}

- (void)setRemoteActive:(BOOL)newRemoteActive {
	if (newRemoteActive == YES && !remote.isStarted) {
		[remote startRemoteControl:kHIDRemoteModeExclusiveAuto];
	}
	else if (newRemoteActive == NO && remote.isStarted) {
		[remote stopRemoteControl];
	}
}

- (void)initializeRemote {
	remote.delegate = self;
	remote.simulateHoldEvents = NO;
	remote.unusedButtonCodes = [NSArray arrayWithObjects:
								[NSNumber numberWithLong:kHIDRemoteButtonCodeMenu],
								[NSNumber numberWithLong:kHIDRemoteButtonCodeUpHold],
								[NSNumber numberWithLong:kHIDRemoteButtonCodeDownHold],
								[NSNumber numberWithLong:kHIDRemoteButtonCodeLeftHold],
								[NSNumber numberWithLong:kHIDRemoteButtonCodeRightHold],
								[NSNumber numberWithLong:kHIDRemoteButtonCodeCenterHold],
								[NSNumber numberWithLong:kHIDRemoteButtonCodeMenuHold],
								[NSNumber numberWithLong:kHIDRemoteButtonCodePlayHold],
								[NSNumber numberWithLong:kHIDRemoteButtonCodeIDChanged], nil];
}

- (void)hidRemote:(HIDRemote*)hidRemote
  eventWithButton:(HIDRemoteButtonCode)buttonCode
		isPressed:(BOOL)isPressed
fromHardwareWithAttributes:(NSMutableDictionary*)attributes
{
	(void)hidRemote;
	(void)attributes;
	
	// this prevents screen dimming, etc. while buttons are being pressed
	UpdateSystemActivity(UsrActivity);
	
	if (!isPressed) return;
	switch (buttonCode & (kHIDRemoteButtonCodeCodeMask | kHIDRemoteButtonCodeHoldMask)) {
		case kHIDRemoteButtonCodeUp:
			[self performButton:ButtonUp];
			break;
		case kHIDRemoteButtonCodeDown:
			[self performButton:ButtonDown];
			break;
		case kHIDRemoteButtonCodeLeft:
			[self performButton:ButtonLeft];
			break;
		case kHIDRemoteButtonCodeRight:
			[self performButton:ButtonRight];
			break;
		case kHIDRemoteButtonCodeCenter:
		case kHIDRemoteButtonCodePlay:
			[self performButton:ButtonSelect];
			break;
		case kHIDRemoteButtonCodeMenu:
			[self performButton:ButtonMenu];
			break;
		default:
			break;
	}
}

@end
