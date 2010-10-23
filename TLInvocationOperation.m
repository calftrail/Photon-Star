//
//  TLInvocationOperation.m
//  Flowrate
//
//  Created by Nathan Vander Wilt on 12/26/09.
//  Copyright 2009 Calf Trail Software, LLC. All rights reserved.
//

#import "TLInvocationOperation.h"

@interface TLInvocationOperation ()
- (void)proxySetsInvocation:(NSInvocation*)theInvocation;
@end


@interface TL_InvocationOpProxy : NSProxy {
@private
	TLInvocationOperation* operation;
	id target;
}
- (id)initForOperation:(TLInvocationOperation*)theOperation
			withTarget:(id)theTarget;
@end


@implementation TL_InvocationOpProxy

- (id)initForOperation:(TLInvocationOperation*)theOperation
			withTarget:(id)theTarget
{
	operation = [theOperation retain];
	target = [theTarget retain];
	return self;
}

- (void)dealloc {
	[operation release];
	[target release];
	[super dealloc];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector {
	return [target methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation*)anInvocation {
	[anInvocation setTarget:target];
	[operation proxySetsInvocation:anInvocation];
}

@end



@implementation TLInvocationOperation

- (void)dealloc {
	[invocation release];
	[exception release];
	[super dealloc];
}

- (id)prepareWithTarget:(id)target {
	id p = [[TL_InvocationOpProxy alloc] initForOperation:self withTarget:target];
	return [p autorelease];
}

- (void)main {
	NSAssert(invocation, @"Invocation must be prepared before operation is started");
	@try {
		[invocation invoke];
	}
	@catch (id e) {
		exception = [e retain];
		@throw;
	}
}

- (void)proxySetsInvocation:(NSInvocation*)theInvocation {
	NSAssert(!invocation, @"Operation must be prepared only once.");
	invocation = [theInvocation retain];
	[invocation retainArguments];
}

- (NSInvocation*)invocation {
	return invocation;
}

- (id)result {
	if (exception) {
		@throw exception;
	}
	if ([self isCancelled]) {
		@throw NSInvocationOperationCancelledException;
	}
	
	NSMethodSignature* sig = [invocation methodSignature];
	const char* retType = [sig methodReturnType];
	size_t retSize = [sig methodReturnLength];
	if (retSize == 0 && *retType == *@encode(void)) {
		@throw NSInvocationOperationVoidResultException;
	}
	
	id result = nil;
	if (retSize == sizeof(id) && *retType == *@encode(id)) {
		[invocation getReturnValue:&result];
	}
	else {
		void* buff = malloc(retSize);
		[invocation getReturnValue:buff];
		result = [NSValue valueWithBytes:buff objCType:retType];
		free(buff);
	}
	return result;
}

@end
