//
//  InterflowController.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 1/9/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Cinematroller.h"


enum {
	InterflowReadyState = 0,
	InterflowReturnedState,
	InterflowAdvancedState,
	InterflowDoneState
};
typedef NSUInteger InterflowState;


@class RateSet, ItemDisplay, CATextLayer;

@interface InterflowController : Cinematroller {
@private
	RateSet* rateSet;
	NSUInteger ratePosition;
	BOOL threeWay;
	
	InterflowState state;
	NSUInteger stage;
	BOOL lastStage;
	
	NSArray* ratedItems1;
	NSArray* ratedItems2;
	NSArray* promotedItems;
	
	CATextLayer* proceedText;
	ItemDisplay* promoteDisplay;
	ItemDisplay* rateDisplay2;
	ItemDisplay* rateDisplay1;
	NSTimer* timer;
}

- (id)initWithItems:(NSArray*)unratedItems
		  threeWay:(BOOL)isThreeWay;

@property (readonly) RateSet* rateSet;
@property NSUInteger ratePosition;	// if set, only rate preceding items

@property InterflowState state;
@property NSUInteger stage;
@property (getter=isLastStage) BOOL lastStage;

@end
