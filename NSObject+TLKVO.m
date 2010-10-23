//
//  NSObject+TLKVO.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 10/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSObject+TLKVO.h"

#include <objc/runtime.h>


NSString* const TLKVOContext = @"NSObject+TLKVO observation context";


@interface TLKVOProxy : NSObject {
@private
	__weak NSObject* observer;
	Class observerClass;
	NSString* observedKeyPath;
	void* originalObserverPtr;
}
+ (NSSet*)findProxiesForObserver:(NSObject*)anObserver
						 ofClass:(Class)theClass
						onObject:(id)observedObject
						 keyPath:(NSString*)theKeyPath;
- (id)initWithObserver:(NSObject*)theObserver
			   ofClass:(Class)theObserverClass
			  onObject:(id)observedObject
			   keyPath:(NSString*)theKeyPath;
@property (readonly) NSString* observedKeyPath;
- (void)unregister:(id)observedObject;
@end


@implementation NSObject (TLKVO)

- (void)tl_addObserver:(NSObject*)observer
			   ofClass:(Class)observerClass
			forKeyPath:(NSString*)keyPath
			   options:(NSKeyValueObservingOptions)options
{
	NSParameterAssert(observer != nil);
	NSParameterAssert(observerClass != nil);
	NSParameterAssert(keyPath != nil);
	
	NSSet* existingObservers = [TLKVOProxy findProxiesForObserver:observer
														  ofClass:observerClass
														 onObject:self
														  keyPath:keyPath];
	NSAssert1(![existingObservers count], @"Observer is already observing %@", keyPath);
	
	TLKVOProxy* proxyObserver = [[TLKVOProxy alloc] initWithObserver:observer
															 ofClass:observerClass
															onObject:self
															 keyPath:keyPath];
	[self addObserver:proxyObserver forKeyPath:keyPath options:options context:(void*)&TLKVOContext];
}

- (void)tl_removeObserver:(NSObject*)observer
				  ofClass:(Class)observerClass
			   forKeyPath:(NSString*)keyPath
{
	NSParameterAssert(observer != nil);
	NSParameterAssert(observerClass != nil);
	
	NSSet* proxyObservers = [TLKVOProxy findProxiesForObserver:observer
													   ofClass:observerClass
													  onObject:self
													   keyPath:keyPath];
	NSAssert([proxyObservers count], @"No matching observers found to remove");
	
	for (TLKVOProxy* proxyObserver in proxyObservers) {
		NSString* proxyKeyPath = [proxyObserver observedKeyPath];
		[self removeObserver:proxyObserver forKeyPath:proxyKeyPath];
		[proxyObserver unregister:self];
	}
}

@end


/* NOTE: This global variable maps weak observed objects to strong NSMutableDictionary with registered proxies.
 If an observed object disappears, we no longer need to keep its proxies around.
 So we use observed objects as weak keys so proxies automatically disappear under GC.
 (Under managed	 memory, the client is expected to remove the observer at a suitable time. */
static NSMapTable* observedObjectProxies = nil;

/* NOTE: If using garbage collection, this global variable maps weak observing objects to a helper object
 that will remove all proxy observers registered with itself as it is finalized. */
static NSMapTable* observerCleaners = nil;

typedef void (*ObserveMethod)(id, SEL, NSString*, id, NSDictionary*, void*);


@interface TLKVOCleaner : NSObject {
@private
	NSMapTable* proxyObjects;
}
- (void)addProxy:(TLKVOProxy*)newProxy forObject:(NSObject*)observedObject;
- (void)removeProxy:(TLKVOProxy*)oldProxy;
- (NSUInteger)proxyCount;
@end


@interface TLKVOProxy ()
@property (readonly) id <NSObject, NSCopying> registrationKey;
@property (readonly) void* originalObserverPtr;
@property (readonly) Class observerClass;
@end


@implementation TLKVOProxy

@synthesize observedKeyPath;
@synthesize originalObserverPtr;
@synthesize observerClass;


+ (id <NSObject, NSCopying>)proxyKeyForObserver:(NSObject*)anObserver
										ofClass:(Class)theClass
									  onKeyPath:(NSString*)theKeyPath
{
	return (theKeyPath ?
			[NSString stringWithFormat:@"%@ -> %@-%p", theKeyPath, theClass, anObserver] :
			[NSString stringWithFormat:@"%@-%p", theClass, anObserver]);
}

+ (NSSet*)findProxiesForObserver:(NSObject*)anObserver ofClass:(Class)theClass
						onObject:(id)observedObject keyPath:(NSString*)keyPath
{
	NSParameterAssert(anObserver != nil);
	NSParameterAssert(theClass != nil);
	NSParameterAssert(observedObject != nil);
	
	if (keyPath) {		// optimize the known-keyPath case
		TLKVOProxy* proxy = nil;
		id proxyKey = [self proxyKeyForObserver:anObserver ofClass:theClass onKeyPath:keyPath];
		@synchronized (self) {
			NSDictionary* proxies = [observedObjectProxies objectForKey:observedObject];
			proxy = [proxies objectForKey:proxyKey];
			[[proxy retain] autorelease];
		}
		// NOTE: proxy may act as termination sentinel
		return [NSSet setWithObjects:proxy, nil];
	}
	else {				// search for all matching proxies
		NSMutableSet* matchingProxies = [NSMutableSet set];
		id proxySuffix = [self proxyKeyForObserver:anObserver ofClass:theClass onKeyPath:nil];
		@synchronized (self) {
			NSDictionary* proxies = [observedObjectProxies objectForKey:observedObject];
			for (NSString* proxyKey in proxies) {
				if ([proxyKey hasSuffix:proxySuffix]) {
					TLKVOProxy* proxy = [proxies objectForKey:proxyKey];
					[matchingProxies addObject:proxy];
				}
			}
		}
		return matchingProxies;
	}
}

+ (void)registerProxy:(TLKVOProxy*)theProxy onObject:(id)observedObject {
	NSParameterAssert(theProxy != nil);
	NSParameterAssert(observedObject != nil);
	
	id proxyKey = [theProxy registrationKey];
	@synchronized (self) {
		if (!observedObjectProxies) {
			observedObjectProxies = [[NSMapTable mapTableWithWeakToStrongObjects] retain];
		}
		if ([NSGarbageCollector defaultCollector] && !observerCleaners) {
			observerCleaners = [[NSMapTable mapTableWithWeakToStrongObjects] retain];
		}
		
		NSMutableDictionary* proxies = [observedObjectProxies objectForKey:observedObject];
		if (!proxies) {
			proxies = [NSMutableDictionary dictionary];
			[observedObjectProxies setObject:proxies forKey:observedObject];
		}
		
		if (observerCleaners) {
			NSObject* theObserver = theProxy->observer;
			TLKVOCleaner* cleaner = [observerCleaners objectForKey:theObserver];
			if (!cleaner) {
				cleaner = [TLKVOCleaner new];
				[observerCleaners setObject:cleaner forKey:theObserver];
				[cleaner release];
			}
			[cleaner addProxy:theProxy forObject:observedObject];
		}
		
		NSAssert1(![proxies objectForKey:proxyKey], @"Observer is already observing %@", [theProxy observedKeyPath]);
		[proxies setObject:theProxy forKey:proxyKey];
		//NSLog(@"Registered '%@' - %@\n", proxyKey, observedObjectProxies);
	}
}

+ (void)unregisterProxy:(TLKVOProxy*)theProxy onObject:(id)observedObject {
	NSParameterAssert(theProxy != nil);
	NSParameterAssert(observedObject != nil);
	
	id proxyKey = [theProxy registrationKey];
	@synchronized (self) {
		NSMutableDictionary* proxies = [observedObjectProxies objectForKey:observedObject];
		NSAssert1([proxies objectForKey:proxyKey], @"Observer was not observing %@", [theProxy observedKeyPath]);
		[proxies removeObjectForKey:proxyKey];
		if (![proxies count]) {
			[observedObjectProxies removeObjectForKey:observedObject];
		}
		
		if (observerCleaners) {
			NSObject* theObserver = theProxy->observer;
			TLKVOCleaner* cleaner = [observerCleaners objectForKey:theObserver];
			[cleaner removeProxy:theProxy];
			if (![cleaner proxyCount]) {
				[observerCleaners removeObjectForKey:theObserver];
			}
		}
		//NSLog(@"Unregistered '%@' - %@\n", proxyKey, observedObjectProxies);
	}
}

- (id)initWithObserver:(NSObject*)theObserver
			   ofClass:(Class)theObserverClass
			  onObject:(id)observedObject
			   keyPath:(NSString*)theKeyPath
{
	NSParameterAssert(theObserver != nil);
	NSParameterAssert(theObserverClass != nil);
	NSParameterAssert(observedObject != nil);
	NSParameterAssert(theKeyPath != nil);
	
	self = [super init];
	if (self) {
		/* NOTE: We may need to unregister after our observer reference is zeroed by the garbage collector.
		 We keep the originalObserverPtr so that we can always create a unique but stable registrationKey. */
		observer = originalObserverPtr = theObserver;
		observerClass = theObserverClass;
		observedKeyPath = [theKeyPath copy];
		[[self class] registerProxy:self onObject:observedObject];
	}
	return self;
}

- (void)unregister:(id)observedObject {
	NSParameterAssert(observedObject != nil);
	[[self class] unregisterProxy:self onObject:observedObject];
}

- (id <NSObject, NSCopying>)registrationKey {
	return [[self class] proxyKeyForObserver:originalObserverPtr ofClass:observerClass onKeyPath:observedKeyPath];
}

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
    if (context == &TLKVOContext) {
		NSAssert2([keyPath isEqualToString:observedKeyPath],
				  @"Unexpected key path observed (Saw change for %@, instead of %@)", keyPath, observedKeyPath);
		if (!observer) {
			//NSLog(@"Observation for collected observer should be removed shortly, ignoring change");
			return;
		}
		ObserveMethod doObserve = (ObserveMethod)class_getMethodImplementation(observerClass, _cmd);
		doObserve(observer, _cmd, keyPath, object, change, context);
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end


@implementation TLKVOCleaner

- (id)init {
	NSAssert([NSGarbageCollector defaultCollector],
			 @"KVO cleanup helper should never be used without garbage collection on");
	self = [super init];
	if (self) {
		proxyObjects = (id)CFRetain([NSMapTable mapTableWithStrongToWeakObjects]);
	}
	return self;
}

- (void)dealloc {
	// this class should never be used without garbage collection on
	[self doesNotRecognizeSelector:_cmd];
	[proxyObjects release];
	[super dealloc];
}

- (void)finalize {
	for (TLKVOProxy* removedProxy in proxyObjects) {
		id observedObject = [proxyObjects objectForKey:removedProxy];
		[observedObject tl_removeObserver:[removedProxy originalObserverPtr]
								  ofClass:[removedProxy observerClass]
							   forKeyPath:[removedProxy observedKeyPath]];
	}
	CFRelease(proxyObjects);
	[super finalize];
}

- (void)addProxy:(TLKVOProxy*)newProxy forObject:(NSObject*)observedObject {
	[proxyObjects setObject:observedObject forKey:newProxy];
}

- (void)removeProxy:(TLKVOProxy*)oldProxy {
	[proxyObjects removeObjectForKey:oldProxy];
}

- (NSUInteger)proxyCount {
	return [proxyObjects count];
}

@end


// expects method name to be formatted as __func__ does
static Class ClassFromMethodName(const char* method) {
	NSString* methodString = [NSString stringWithUTF8String:method];
	NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString:@"[ ]"];
	NSArray* methodComponents = [methodString componentsSeparatedByCharactersInSet:separators];
	NSCAssert([methodComponents count] == 4, @"Must be called with properly formatted method name");
	
	NSString* className = [methodComponents objectAtIndex:1];
	return NSClassFromString(className);
}

void TLKVO_RegisterInternal(NSObject* observer, const char* method,
							NSObject* targetObject, NSString* keyPath, NSKeyValueObservingOptions options)
{
	[targetObject tl_addObserver:observer ofClass:ClassFromMethodName(method)
					  forKeyPath:keyPath options:options];
}

void TLKVO_UnregisterInternal(NSObject* observer, const char* method,
							  NSObject* targetObject, NSString* keyPath)
{
	[targetObject tl_removeObserver:observer ofClass:ClassFromMethodName(method)
						 forKeyPath:keyPath];
}
