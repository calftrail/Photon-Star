//
//  NSColor+TLExtensions.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 11/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSColor+TLExtensions.h"

#include "CFType+TLExtensions.h"


@implementation NSColor (TLExtensions)

- (CGColorRef)tl_CGColor {
	NSAssert([self numberOfComponents] == [[self colorSpace] numberOfColorComponents] + 1,
			 @"Mismatched number of color components");
	CGFloat* components = malloc([self numberOfComponents] * sizeof(CGFloat));
	[self getComponents:components];
	CGColorRef quartzColor = CGColorCreate([[self colorSpace] CGColorSpace], components);
	free(components);
	return (CGColorRef)tlCFAutorelease(quartzColor);
}

@end
