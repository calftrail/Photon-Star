//
//  TLSFX.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 2/3/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TLSFX : NSObject {
@private
	NSDictionary* fxIdentifiers;
}

+ (id)sharedSFX;

- (void)playSound:(NSString*)soundName;
- (void)playAlert:(NSString*)alertName;

@end

extern NSString* const TLSFXNameClick;
extern NSString* const TLSFXNameClunk;
extern NSString* const TLSFXNameClank;

extern NSString* const TLSFXNameDown;
extern NSString* const TLSFXNameUp;
extern NSString* const TLSFXNameNeutral;

