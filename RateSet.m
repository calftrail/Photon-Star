//
//  RateSet.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 12/8/09.
//  Copyright 2009 Calf Trail Software, LLC. All rights reserved.
//

#import "RateSet.h"


@implementation RateSet

- (id)initWithItems:(NSArray*)theItems {
	self = [super init];
	if (self) {
		items = [theItems copy];
		size_t statesSize = [items count] * sizeof(RateStatus);
		itemStates = NSAllocateCollectable(statesSize, 0);
		bzero(itemStates, statesSize);
	}
	return self;
}

+ (RateSet*)rateSetWithItems:(NSArray*)theItems {
	RateSet* rs = [[RateSet alloc] initWithItems:theItems];
	return [rs autorelease];
}


- (NSUInteger)count {
	return [items count];
}

- (id)itemAtIndex:(NSUInteger)itemIdx {
	return [items objectAtIndex:itemIdx];
}

- (RateStatus)itemStatusAtIndex:(NSUInteger)itemIdx {
	NSAssert2(itemIdx < [items count],
			  @"Index out of range (%lu >= %lu)", itemIdx, [items count]);
	return itemStates[itemIdx];
}

- (void)setItemStatus:(RateStatus)newRateStatus
			  atIndex:(NSUInteger)itemIdx
{
	NSAssert2(itemIdx < [items count],
			  @"Index out of range (%lu >= %lu)", itemIdx, [items count]);
	itemStates[itemIdx] = newRateStatus;
}

- (NSArray*)itemsWithStatus:(RateStatus)desiredStatus {
	NSMutableArray* filteredItems = [NSMutableArray array];
	NSUInteger itemIdx = 0;
	for (id item in items) {
		if (itemStates[itemIdx] == desiredStatus) {
			[filteredItems addObject:item];
		}
		++itemIdx;
	}
	return filteredItems;
}

@end
