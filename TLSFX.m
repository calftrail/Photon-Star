//
//  TLSFX.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 2/3/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "TLSFX.h"


NSString* const TLSFXNameClick = @"clickSound";
NSString* const TLSFXNameClunk = @"clunkSound";
NSString* const TLSFXNameClank = @"clankSound";
NSString* const TLSFXNameDown = @"downSound";
NSString* const TLSFXNameUp = @"upSound";
NSString* const TLSFXNameNeutral = @"mehSound";


/* NOTE: it's best to use higher-level for overhead reasons described 
 in the AudioServices.h header and for accessibility reasons described in
 http://developer.apple.com/mac/library/technotes/tn2002/tn2102.html
 
 TN2102 refers to deprecated SystemSoundGetActionID / SystemSoundPlay API, but
 the replacement AudioServicesCreateSystemSoundID / AudioServicesPlaySystemSound are
 available even in Cocoa Touch */
#import <AudioToolbox/AudioToolbox.h>


@implementation TLSFX

+ (NSURL*)soundURLWithIdentifier:(id)soundID {
	NSURL* soundURL = nil;
	if ([soundID isKindOfClass:[NSString class]]) {
		NSString* path = [[NSBundle mainBundle] pathForSoundResource:soundID];
		if (path) {
			soundURL = [NSURL fileURLWithPath:path isDirectory:NO];
		}
	}
	else if ([soundID isKindOfClass:[NSURL class]]) {
		soundURL = soundID;
	}
	return soundURL;
}

- (id)initWithSoundEffects:(NSDictionary*)theEffects {
	self = [super init];
	if (self) {
		NSMutableDictionary* theIdentifiers = [NSMutableDictionary dictionary];
		for (NSString* name in theEffects) {
			id soundID = [theEffects objectForKey:name];
			NSURL* soundURL = [[self class] soundURLWithIdentifier:soundID];
			SystemSoundID fxID;
			OSStatus err = AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &fxID);
			NSAssert4(!err, @"Error %i creating sound effect '%@' with resource %@ (from %@)",
					  err, name, soundURL, soundID);
			UInt32 continuePlayback = 1;
			err = AudioServicesSetProperty(kAudioServicesPropertyCompletePlaybackIfAppDies,
										   sizeof(SystemSoundID), &fxID,
										   sizeof(UInt32), &continuePlayback);
			NSAssert1(!err, @"Error %i setting playback property of sound effect", err);
			[theIdentifiers setObject:[NSNumber numberWithInt:fxID] forKey:name];
		}
		fxIdentifiers = [theIdentifiers copy];
	}
	return self;
}

- (void)disposeSFX {
	for (NSString* name in fxIdentifiers) {
		SystemSoundID fxID = [[fxIdentifiers objectForKey:name] intValue];
		AudioServicesDisposeSystemSoundID(fxID);
	}
}

- (void)finalize {
	[self disposeSFX];
	[super finalize];
}

- (void)dealloc {
	[self disposeSFX];
	[super dealloc];
}


+ (id)sharedSFX {
	NSAssert([NSThread isMainThread], @"Main thread only.");
	static id sharedSFX = nil;
	if (!sharedSFX) {
		NSDictionary* soundEffects = [NSDictionary dictionaryWithObjectsAndKeys:
									  @"click", TLSFXNameClick,
									  @"clank", TLSFXNameClank,
									  @"clunk", TLSFXNameClunk,
									  @"meh", TLSFXNameNeutral,
									  @"down", TLSFXNameDown,
									  @"up", TLSFXNameUp, nil];
		sharedSFX = [[TLSFX alloc] initWithSoundEffects:soundEffects];
	}
	return sharedSFX;
}

- (SystemSoundID)effectForName:(NSString*)name {
	SystemSoundID fxID = kUserPreferredAlert;
	if (name) {
		fxID = [[fxIdentifiers objectForKey:name] intValue];
	}
	return fxID;
}

- (void)playSound:(NSString*)soundName {
	AudioServicesPlaySystemSound([self effectForName:soundName]);
}

- (void)playAlert:(NSString*)alertName {
	AudioServicesPlayAlertSound([self effectForName:alertName]);
}

@end
