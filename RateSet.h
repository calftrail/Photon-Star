//
//  RateSet.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 12/8/09.
//  Copyright 2009 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


enum {
	RateStatusDown = -1,
	RateStatusNoChange = 0,
	RateStatusUp = 1
};
typedef int8_t RateStatus;


@interface RateSet : NSObject {
@private
	NSArray* items;
	__strong RateStatus* itemStates;
}

+ (RateSet*)rateSetWithItems:(NSArray*)theItems;

- (NSUInteger)count;
- (id)itemAtIndex:(NSUInteger)itemIdx;
- (RateStatus)itemStatusAtIndex:(NSUInteger)itemIdx;
- (void)setItemStatus:(RateStatus)newRateStatus
			  atIndex:(NSUInteger)itemIdx;
- (NSArray*)itemsWithStatus:(RateStatus)desiredStatus;

@end
