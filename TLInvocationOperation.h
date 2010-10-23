//
//  TLInvocationOperation.h
//  Flowrate
//
//  Created by Nathan Vander Wilt on 12/26/09.
//  Copyright 2009 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TLInvocationOperation : NSOperation {
@private
	NSInvocation* invocation;
	id exception;
}

- (id)prepareWithTarget:(id)target;
- (NSInvocation*)invocation;
- (id)result;

@end
