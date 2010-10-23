//
//  NSObject+TLKVO.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 10/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


// the context for all observations registered through these extensions will == &TLKVOContext
extern NSString* const TLKVOContext;


@interface NSObject (TLKVO)

- (void)tl_addObserver:(NSObject*)observer
			   ofClass:(Class)observerClass
			forKeyPath:(NSString*)keyPath
			   options:(NSKeyValueObservingOptions)options;

- (void)tl_removeObserver:(NSObject*)observer
				  ofClass:(Class)observerClass
			   forKeyPath:(NSString*)keyPath;

@end


// NOTE: these are private functions for use by the public convenience macros below
extern void TLKVO_RegisterInternal(NSObject* observer, const char* method,
								   NSObject* targetObject, NSString* keyPath, NSKeyValueObservingOptions options);
extern void TLKVO_UnregisterInternal(NSObject* observer, const char* method,
									 NSObject* targetObject, NSString* keyPath);

// these may be used within a method to register an instance of the method's class as a KVO observer
#define TLKVORegisterSelf(object, keyPath, options) TLKVO_RegisterInternal(self, __func__, object, keyPath, options)
#define TLKVOUnregisterSelf(object, keyPath) TLKVO_UnregisterInternal(self, __func__, object, keyPath)

// thanks to http://zathras.de/angelweb/blog-safe-key-value-coding.htm
#define TLKVOProperty(propName)    NSStringFromSelector(@selector(propName))
//#define TLKVOProperty(propName)    @#propName
