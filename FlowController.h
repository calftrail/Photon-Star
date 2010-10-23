//
//  FlowController.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 11/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Cinematroller.h"


@class RateSet, ItemDisplay;

@interface FlowController : Cinematroller {
@private
	RateSet* rateSet;
	ItemDisplay* itemDisplay;
	BOOL autoHold;
}

@property BOOL autoHold;
@property (readonly) NSUInteger position;

- (id)initWithRateSet:(RateSet*)theRateSet;

@end
