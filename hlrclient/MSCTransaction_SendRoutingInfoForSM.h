//
//  MSCTransaction_SendRoutingInfoForSM.h
//  hlrclient
//
//  Created by Andreas Fink on 10.05.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "MSCTransaction.h"
@class MSCInstance;

@interface MSCTransaction_SendRoutingInfoForSM : MSCTransaction
{
    NSString *msisdn;
    NSString *smsc;
}

+ (NSString *)webForm;
-(MSCTransaction_SendRoutingInfoForSM *)initWithHttpReq:(UMHTTPRequest *)hreq
                                               instance:(MSCInstance *)inst;

@end
