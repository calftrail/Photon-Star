//
//  MenuController.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 1/19/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "MenuController.h"

#import "HostView.h"

#import "CALayer+TLExtensions.h"
#import "NSColor+TLExtensions.h"
#import "NSObject+TLKVO.h"

#import <QuartzCore/QuartzCore.h>

@interface MenuController ()
@property (readonly) NSArray* choices;
@end


@implementation MenuController

@synthesize chosenIndex;
@synthesize choices;

- (id)initWithChoices:(NSArray*)theChoices {
	self = [super init];
	if (self) {
		choices = [theChoices copy];
		
		selectorLayer = [CALayer layer];
		selectorLayer.borderWidth = 1;
		[self.layer addSublayer:selectorLayer];
		
		groupLayer = [CALayer layer];
		for (NSString* choice in self.choices) {
			CATextLayer* l = [CATextLayer layer];
			l.font = @"Futura";
			l.foregroundColor = [[NSColor blackColor] tl_CGColor];
			l.alignmentMode = kCAAlignmentCenter;
			l.truncationMode = kCATruncationEnd;
			l.string = choice;
			[groupLayer addSublayer:l];
		}
		[self.layer addSublayer:groupLayer];
		
		[self.layer setNeedsLayout];
		
		self.layer.backgroundColor = [[NSColor whiteColor] tl_CGColor];
		
		TLKVORegisterSelf(self, @"chosenIndex", NSKeyValueObservingOptionNew);
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object
						change:(NSDictionary*)change context:(void*)context
{
    if (context == &TLKVOContext) {
		if ([keyPath isEqualToString:@"chosenIndex"]) {
			[self.layer setNeedsLayout];
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object
							   change:change context:context];
	}
}


- (void)layoutSublayersOfLayer:(CALayer*)theLayer {
	NSAssert(theLayer == self.layer, @"Layout own layer only");
	
	// hide in case self.choiceIdx == MenuControllerNoChoice
	selectorLayer.hidden = YES;
	
	CGRect base = self.layer.bounds;
	CGRect target = CGRectInset(base,
								base.size.width / 8,
								base.size.height / 8);
	CGFloat height = target.size.height / MAX(6, [self.choices count]);
	groupLayer.frame = target;
	
	target = groupLayer.bounds;
	NSUInteger lIdx = 0;
	for (CATextLayer* l in groupLayer.sublayers) {
		CGRect frame = CGRectMake(CGRectGetMinX(target),
								  CGRectGetMaxY(target) - (lIdx + 1) * height,
								  target.size.width, height);
		l.frame = [groupLayer tl_pixelAlignRect:frame];
		l.fontSize = height * 0.7f;
		if (lIdx == self.chosenIndex) {
			selectorLayer.frame = [self.layer convertRect:l.frame
												fromLayer:groupLayer];
			selectorLayer.hidden = NO;
		}
		++lIdx;
	}
}


#pragma mark Event handling

- (void)buttonUp {
	if (self.chosenIndex > 0) {
		self.chosenIndex -= 1;
	}
}

- (void)buttonDown {
	if (self.chosenIndex + 1 < [self.choices count]) {
		self.chosenIndex += 1;
	}
}

- (void)buttonSelect {
	[self.hostView popController];
}

- (void)buttonMenu {
	self.chosenIndex = MenuControllerNoChoice;
	[self.hostView popController];
}

@end
