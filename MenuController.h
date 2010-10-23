//
//  MenuController.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 1/19/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Cinematroller.h"


#define MenuControllerNoChoice NSUIntegerMax

@interface MenuController : Cinematroller {
@private
	NSUInteger chosenIndex;
	NSArray* choices;
	
	CALayer* selectorLayer;
	CALayer* groupLayer;
}

- (id)initWithChoices:(NSArray*)theChoices;

@property NSUInteger chosenIndex;

@end
