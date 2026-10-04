//
//  MSCSession_SendRoutingInfoForSM.h
//  hlrclient
//
//  Created by Andreas Fink on 03.12.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "MSCSession.h"
@class MSCInstance;

@interface MSCSession_SendRoutingInfoForSM : MSCSession
{
    NSString *_msisdn;
    NSString *_smsc;
    NSString *_sm_rp_pri;
    NSString *_gprsSupportIndicator;
    NSString *_sm_rp_mti;
    NSString *_sm_rp_smea;
    NSString *_sm_delivery_not_intended;
    NSString *_ip_sm_gw_guidance_indicator;
    NSString *_imsi;
    NSString *_t4_trigger_indicator;
    NSString *_single_attempt_delivery;
}
+ (NSString *)webForm:(int)variant;

-(MSCSession_SendRoutingInfoForSM *)initWithHttpReq:(UMHTTPRequest *)hreq
                                          instance:(MSCInstance *)inst;

@end
