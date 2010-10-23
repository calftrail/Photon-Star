//
//  Cinematroller.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 11/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CALayer;
@class HostView;

@interface Cinematroller : NSObject {
@private
	HostView* hostView;
	Cinematroller* parentController;
	CALayer* layer;
}

@property HostView* hostView;
@property Cinematroller* parentController;

@property (readonly) CALayer* layer;
- (void)layerWillAppear;
- (void)layerWillDisappear;
- (void)layerDidAppear;
- (void)layerDidDisappear;

@property (readonly) CALayer* overlayLayer;

- (void)buttonUp;
- (void)buttonDown;
- (void)buttonLeft;
- (void)buttonRight;
- (void)buttonSelect;
- (void)buttonMenu;

@end
