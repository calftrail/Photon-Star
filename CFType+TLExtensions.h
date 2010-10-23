/*
 *  CFType+TLExtensions.h
 *  Flowrate
 *
 *  Created by Nathan Vander Wilt on 12/7/09.
 *  Copyright 2009 Calf Trail Software, LLC. All rights reserved.
 *
 */


#ifndef __CFTYPE_TLEXTENSIONS__
#define __CFTYPE_TLEXTENSIONS__


#define tlCFAutorelease(obj) ([(id)CFMakeCollectable(obj) autorelease])

/* // Static analyzer does not like us to use this
 static inline CFTypeRef tlCFAutorelease(CFTypeRef obj) {
 return [(id)CFMakeCollectable(obj) autorelease];
 }
 */

CFTypeRef tl_CFAutoreleaseHelper(CFTypeRef obj);
#define tlCFAutoreleaseC(obj) (tl_CFAutoreleaseHelper(obj), CFMakeCollectable(obj))

#endif /* __CFTYPE_TLEXTENSIONS__ */
