//
//  StageController.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 12/11/09.
//  Copyright 2009 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Cinematroller.h"

@class CATextLayer;
@class FlowController, InterflowController, MenuController;


@interface StageController : Cinematroller {
@private
	CALayer* overlayLayer;
	CATextLayer* holdCaption;
	CATextLayer* promoteCaption;
	FlowController* flower;
	InterflowController* interflower;
	MenuController* breakMenu;
	NSUInteger numberOfStages;
}

- (id)initWithItems:(NSArray*)unratedItems
			 stages:(NSUInteger)numStages;

- (void)showBreakMenu;
- (void)checkBreakMenu;

@end
