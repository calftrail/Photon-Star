//
//  StageController.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 12/11/09.
//  Copyright 2009 Calf Trail Software, LLC. All rights reserved.
//

#import "StageController.h"

#import <QuartzCore/QuartzCore.h>
#import "NSColor+TLExtensions.h"

#import "HostView.h"
#import "FlowController.h"
#import "InterflowController.h"
#import "MenuController.h"
#import "AppDelegate.h"

#import "RateSet.h"


static NSString* const LayerIsDockedKey = @"com_calftrail_isDocked";


@implementation StageController

@synthesize overlayLayer;

- (id)initWithItems:(NSArray*)unratedItems stages:(NSUInteger)numStages {
	NSParameterAssert(0 < numStages && numStages < 5);
	self = [super init];
	if (self) {
		numberOfStages = numStages;
		self.layer.backgroundColor = [[NSColor whiteColor] tl_CGColor];
		overlayLayer = [CALayer layer];
		overlayLayer.layoutManager = self;
		overlayLayer.shadowRadius = 10;
		overlayLayer.shadowOpacity = 1;
		
		holdCaption = [CATextLayer layer];
		holdCaption.foregroundColor = [[NSColor blackColor] tl_CGColor];
		holdCaption.alignmentMode = kCAAlignmentLeft;
		[overlayLayer addSublayer:holdCaption];
		
		promoteCaption = [CATextLayer layer];
		promoteCaption.foregroundColor = [[NSColor blackColor] tl_CGColor];
		promoteCaption.alignmentMode = (numStages < 3) ? kCAAlignmentLeft : kCAAlignmentRight;
		[overlayLayer addSublayer:promoteCaption];
		
		[overlayLayer setNeedsLayout];
		
		BOOL threeWay = (numberOfStages < 3) ? YES : NO;
		interflower = [[InterflowController alloc] initWithItems:unratedItems threeWay:threeWay];
		interflower.state = InterflowAdvancedState;
	}
	return self;
}

- (void)layoutSublayersOfLayer:(CALayer*)theLayer {
	if (theLayer != self.overlayLayer) return;
	
	CGRect target = theLayer.bounds;
	CGFloat height = target.size.height / 10;
	CGFloat width = target.size.width;
	holdCaption.frame = CGRectMake(CGRectGetMinX(target),
								   CGRectGetMinY(target),
								   width, height);
	promoteCaption.frame = CGRectMake(CGRectGetMaxX(target) - width,
									  CGRectGetMaxY(target) - height,
									  width, height);
}

- (void)proceedOmatic {
	if (interflower.state == InterflowReadyState) {
		interflower.ratePosition = flower.position;
		[self.hostView pushController:interflower];
	}
	else if (interflower.state == InterflowReturnedState) {
		interflower.state = InterflowReadyState;
		[self.hostView pushController:flower];
	}
	else if (interflower.state == InterflowAdvancedState) {
		interflower.state = InterflowReadyState;
		flower = [[FlowController alloc] initWithRateSet:interflower.rateSet];
		BOOL threeWay = YES;
		switch (numberOfStages) {
			case 1:
				interflower.stage += 3;
				interflower.lastStage = YES;
				break;
			case 2:
				interflower.stage += 2;
				if (interflower.stage > 3) interflower.lastStage = YES;
				break;
			case 3:
				interflower.stage += 1;
				if (interflower.stage > 2) interflower.lastStage = YES;
				flower.autoHold = YES;
				threeWay = NO;
				break;
			default:
				interflower.stage += 1;
				if (interflower.stage > 3) interflower.lastStage = YES;
				flower.autoHold = YES;
				threeWay = NO;
		}
		
		NSUInteger displayStage = interflower.stage;
		if (threeWay) displayStage -= 1;
		NSString* rateString = @"";
		NSUInteger stageIdx = 0;
		while (stageIdx++ < displayStage) {
			rateString = [rateString stringByAppendingString:@"★"];
		}
		holdCaption.string = rateString;
		
		NSString* promoteString = [rateString stringByAppendingString:@"★"];
		if (threeWay) {
			promoteString = [promoteString stringByAppendingString:@"★"];
			stageIdx += 1;
		}
		if (!interflower.lastStage) while (stageIdx++ < 5) {
			promoteString = [promoteString stringByAppendingString:@"☆"];
		}
		promoteCaption.string = promoteString;
		
		[self.hostView performSelector:@selector(pushController:)
							withObject:flower
							afterDelay:1.0];
	}
	else if (interflower.state == InterflowDoneState) {
		// Done.
		[self.hostView popController];
	}
}


#pragma mark Break menu handling

enum {
	BreakToggleFullscreen = 0,
	BreakNextLevel = 1,
	BreakExit = 2,
	BreakNoChoice = MenuControllerNoChoice
};

+ (NSArray*)breakChoices {
	return [NSArray arrayWithObjects:
			@"Toggle fullscreen", @"Finish this level", @"Exit rating", nil];
}

- (void)handleBreakChoice:(NSUInteger)theChoice {
	if ([[NSApp delegate] isTerminating]) return;
	switch (theChoice) {
		case BreakNoChoice:
			// carry on like nothing happened
			break;
		case BreakToggleFullscreen:
			[[NSApp delegate] toggleFullScreen];
			break;
		case BreakNextLevel:
			[self.hostView popToController:self];
			[self proceedOmatic];
			break;
		case BreakExit:
			[self.hostView popToController:self];
			interflower.lastStage = YES;
			[self proceedOmatic];
			break;
		default:
			NSAssert1(false, @"Bad break menu choice %i", theChoice);
			break;
	}
}

- (void)showBreakMenu {
	NSArray* menuChoices = [[self class] breakChoices];
	breakMenu = [[MenuController alloc] initWithChoices:menuChoices];
	[self.hostView pushController:breakMenu];
}

- (void)checkBreakMenu {
	if (breakMenu) {
		[self handleBreakChoice:breakMenu.chosenIndex];
		breakMenu = nil;
	}
}

- (void)layerDidAppear {
	if ([[NSApp delegate] isTerminating]) return;
	if (!breakMenu) [self proceedOmatic];
}

- (void)buttonMenu {
	[NSObject cancelPreviousPerformRequestsWithTarget:self.hostView
											 selector:@selector(pushController:)
											   object:flower];
	[self.hostView popController];
}

@end
