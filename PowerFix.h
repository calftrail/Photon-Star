/*
 *  PowerFix.h
 *  Flowrate
 *
 *  Created by Nathan Vander Wilt on 1/21/10.
 *  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
 *
 */

#if __LP64__

#ifndef TLPOWERFIX
#define TLPOWERFIX

/* NOTE: these definitions are yoinked from from Power.h
 They must have been erroneously excluded in the 64-bit 10.5 SDK, because they are
 again present for 64-bit in the 10.6 SDK.
 See http://developer.apple.com/mac/library/qa/qa2004/qa1160.html
 and also: http://lists.apple.com/archives/Carbon-dev/2007/Nov/msg00624.html */



/* System Activity Selectors */
/* Notes:  The IdleActivity selector is not available unless the hasAggressiveIdling PMFeatures bit is set. */
/*         Use IdleActivity where you used to use OverallAct if necessary.  OverallAct will only            */
/*         delay power cycling if it's enabled, and will delay sleep by a small amount when                 */
/*         hasAggressiveIdling is set.  Don't use IdleActivity unless hasAggressiveIdling is set; when      */
/*         hasAggressiveIdling is not set, the use of IdleActivity is undefined, and well do different      */
/*         things depending on which Power Manager is currently running.                                    */
enum {
	OverallAct                    = 0,    /* Delays idle sleep by small amount                 */
	UsrActivity                   = 1,    /* Delays idle sleep and dimming by timeout time          */
	NetActivity                   = 2,    /* Delays idle sleep and power cycling by small amount         */
	HDActivity                    = 3,    /* Delays hard drive spindown and idle sleep by small amount  */
	IdleActivity                  = 4     /* Delays idle sleep by timeout time                 */
};

/*
 *  UpdateSystemActivity()
 *  
 *  Summary:
 *    You can use the UpdateSystemActivity function to notify the Power
 *    Manager that activity has taken place .
 *  
 *  Discussion:
 *    The UpdateSystemActivity function is used to notify the Power
 *    Manager that activity has taken place and the timers used to
 *    measure idle time should be updated to the time of this call.
 *    This function can be used by device drivers to prevent the
 *    computer from entering a low-power mode while critical activity
 *    is taking place on a particular device. The function is passed a
 *    parameter indicating the type of activity that has
 *    occurred.
 *    
 *    This function is slightly different from DelaySystemIdle, which
 *    should be used to prevent sleep or idle during a critical
 *    section. UpdateSystemActivity simply updates the tick count for
 *    the activity type selected. Conversely, DelaySystemIdle actually
 *    moves the counter to some number of ticks into the future, which
 *    allows the caller to go off and do somethingwithout fear of
 *    idling.
 *    
 *    The valid types of activity are:
 *    Value Name       Value        Description
 *    OverallAct       0            general type of activity
 *    UsrActivity      1            user activity (i.e.keyboard or mouse)
 *    NetActivity      2            interaction with network(s)
 *    HDActivity       3            hard disk or storage device in use
 *  
 *  Parameters:
 *    
 *    activity:
 *      The type of activity which has occurred.
 *  
 *  Availability:
 *    Mac OS X:         in version 10.0 and later in CoreServices.framework
 *    CarbonLib:        in CarbonLib 1.0 and later
 *    Non-Carbon CFM:   in PowerMgrLib 1.0 and later
 */
extern OSErr 
UpdateSystemActivity(UInt8 activity)                          AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER;

#endif /* TLPOWERFIX */

#endif /* __LP64__ */
