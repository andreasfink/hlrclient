//
//  MSCInstance.m
//  hlrclient
//
//  Created by Andreas Fink on 10.05.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//


#import "MSCInstance.h"
#import "MSCTransaction.h"
#import "MSCTransaction_SendRoutingInfoForSM.h"

@implementation MSCInstance

@synthesize smsForwardUrl;

- (NSString *)instancePrefix
{
    return @"M";
}

#pragma mark -
#pragma mark handle incoming components

-(void) MAP_Invoke_Ind:(UMASN1Object *)param
                userId:(NSString *)userIdentifier
                dialog:(NSString *)xdialogId
           transaction:(NSString *)tcapTransactionId
                opCode:(UMLayerGSMMAP_OpCode *)xopcode
              invokeId:(int64_t)xinvokeId
              linkedId:(int64_t)xlinkedId
                  last:(BOOL)xlast
               options:(NSDictionary *)xoptions
{
    NSLog(@"MSCInstance: MAP_Invoke_Ind  userIdentifier:%@ dialog: %@ opcode:%d", userIdentifier,xdialogId,(int)xopcode.operation);
    MSCTransaction *t = (MSCTransaction *)[self transactionById:userIdentifier];
    if(t==NULL)
    {
        NSLog(@"incoming MAP_Invoke_Ind for unknown userIdentifier %@",userIdentifier);
        return;
    }
    NSLog(@"MSCInstance: found transaction %@", [t description]);
    t.dialogId = xdialogId;
    if(t.undefinedTransaction==YES) /* we have a generic transaction, lets make it specific */
    {
        switch(xopcode.operation)
        {
            case UMGSMMAP_Opcode_mt_forwardSM:
                /* we are already in a transaction */
                NSLog(@"MSCInstance: UMGSMMAP_Opcode_mt_forwardSM");
                t = [[MSCTransaction_MT_ForwardSM alloc]initWithTransaction:t];
                break;
            case UMGSMMAP_Opcode_mo_forwardSM:
                NSLog(@"MSCInstance: UMGSMMAP_Opcode_mo_forwardSM");
                t = [[MSCTransaction_MO_ForwardSM alloc]initWithTransaction:t];
                break;

            default:
                NSLog(@"MSCInstance: unknown opcode");
        }
        t.opcode = xopcode;
        /* we have changed the transaction from a unknown generic one to a specific object */
        /* so we need to restore that type of object here */
        /* note: the undefinedTransaction is not copied so it now becomes NO if it was YES */
        [self addTransaction:t userId:userIdentifier];
    }
    [t MAP_Invoke_Ind:param
               userId:userIdentifier
               dialog:xdialogId
          transaction:tcapTransactionId
               opCode:xopcode
             invokeId:xinvokeId
             linkedId:xlinkedId
                 last:xlast
              options:xoptions];

}




- (UMHTTPAuthenticationStatus)httpAuthenticateRequest:(UMHTTPRequest *)req
                                                realm:(NSString **)realm
{
    NSDictionary *p = req.params;
    /* this is used if HTTP auth doesnt pass but &user=xxx & &pass=xxx is passed on the URL */
    NSString *user = [p[@"user"] urldecode];
    NSString *pass = [p[@"pass"] urldecode];

    if([req.path isEqualToString:@"/msc"])
    {
        return UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED;
    }
    else if([req.path isEqualToString:@"/msc/"])
    {
        return UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED;
    }
    else if([req.path isEqualToString:@"/msc/index.html"])
    {
        return UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED;
    }
    else if([req.path isEqualToString:@"/msc/index.php"])
    {
        return UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED;
    }
    else if([self authenticateUser:req.authUsername pass:req.authPassword]==YES)
    {
        return UMHTTP_AUTHENTICATION_STATUS_PASSED;
    }
    else if([self authenticateUser:user pass:pass]==YES)
    {
        req.authUsername = user;
        req.authPassword = pass;
        return UMHTTP_AUTHENTICATION_STATUS_PASSED;
    }
    return UMHTTP_AUTHENTICATION_STATUS_FAILED;
}

- (void)  httpGetPost:(UMHTTPRequest *)req
{
    @autoreleasepool
    {
        /* pages requesting auth will have UMHTTP_AUTHENTICATION_STATUS_FAILED or UMHTTP_AUTHENTICATION_STATUS_PASSED
         pages not requiring auth will have UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED */

        if(req.authenticationStatus == UMHTTP_AUTHENTICATION_STATUS_FAILED)
        {
            [req setResponsePlainText:@"not-authorization-vlr"];
            [req setRequireAuthentication];
            return;
        }
        /*
         if(![req.connection.socket.connectedRemoteAddress isEqualToString:@"ipv4:localhost"])
         {
         }
         */
        NSDictionary *p = req.params;
        int pcount=0;
        for(NSString *n in p.allKeys)
        {
            if(([n isEqualToString:@"user"])  || ([n isEqualToString:@"pass"]))
            {
                continue;
            }
            pcount++;
        }
        @try
        {
            NSString *path = req.url.relativePath;

            if([path hasSuffix:@".php"])
            {
                path = [path substringToIndex:path.length - 4];
            }
            if([path hasSuffix:@".html"])
            {
                path = [path substringToIndex:path.length - 5];
            }
            if([path hasSuffix:@"/"])
            {
                path = [path substringToIndex:path.length - 1];
            }

            if([path isEqualToStringCaseInsensitive:@"/msc/index"])
            {
                path = @"/msc";
            }

            if([path isEqualToStringCaseInsensitive:@"/msc"])
            {
                [req setResponseHtmlString:[MSCInstance webIndexForm]];
            }
            else if([path isEqualToStringCaseInsensitive:@"/msc/appcontext-test"])
            {
                if(pcount==0)
                {
                    [req setResponseHtmlString:[MSCTransaction_ApplicationContextTest webForm]];
                }
                else
                {
                    MSCTransaction_ApplicationContextTest *t = [[MSCTransaction_ApplicationContextTest alloc]initWithHttpReq:req
                                                                                                                    instance:self];
                    [self queueFromUpper:t];
                }
            }
            else if([path isEqualToStringCaseInsensitive:@"/msc/sendRoutingInfo"])
            {
                if(pcount==0)
                {
                    [req setResponseHtmlString:[MSCTransaction_SendRoutingInfo webForm]];
                }
                else
                {
                    MSCTransaction_SendRoutingInfo *t = [[MSCTransaction_SendRoutingInfo alloc]initWithHttpReq:req
                                                                                                      instance:self];
                    [self queueFromUpper:t];
                }
            }
            else if([path isEqualToStringCaseInsensitive:@"/msc/sendRoutingInfoForSM"])
            {
                if(pcount==0)
                {
                    [req setResponseHtmlString:[MSCTransaction_SendRoutingInfoForSM webForm]];
                }
                else
                {
                    MSCTransaction_SendRoutingInfoForSM *t = [[MSCTransaction_SendRoutingInfoForSM alloc]initWithHttpReq:req
                                                                                                                instance:self];
                    [self queueFromUpper:t];
                }
            }
            else if([path isEqualToStringCaseInsensitive:@"/msc/sendRoutingInfoForGprs"])
            {
                if(pcount==0)
                {
                    [req setResponseHtmlString:[MSCTransaction_SendRoutingInfoForGprs webForm]];
                }
                else
                {
                    MSCTransaction_SendRoutingInfoForGprs *t = [[MSCTransaction_SendRoutingInfoForGprs alloc]initWithHttpReq:req
                                                                                                                    instance:self];
                    [self queueFromUpper:t];
                }
            }
            else if([path isEqualToStringCaseInsensitive:@"/msc/mt-forwardSM"])
            {
                if(pcount==0)
                {
                    [req setResponseHtmlString:[MSCTransaction_MT_ForwardSM webForm]];
                }
                else
                {
                    MSCTransaction_MT_ForwardSM *t = [[MSCTransaction_MT_ForwardSM alloc]initWithHttpReq:req
                                                                                                instance:self];
                    [self queueFromUpper:t];
                }
            }
            else if([path isEqualToStringCaseInsensitive:@"/msc/mo-forwardSM"])
            {
                if(pcount==0)
                {
                    [req setResponseHtmlString:[MSCTransaction_MO_ForwardSM webForm]];
                }
                else
                {
                    MSCTransaction_MO_ForwardSM *t = [[MSCTransaction_MO_ForwardSM alloc]initWithHttpReq:req
                                                                                                instance:self];
                    [self queueFromUpper:t];
                }
            }

        }
        @catch(NSException *e)
        {

            NSMutableDictionary *d1 = [[NSMutableDictionary alloc]init];
            if(e.name)
            {
                d1[@"name"] = e.name;
            }
            if(e.reason)
            {
                d1[@"reason"] = e.reason;
            }
            if(e.userInfo)
            {
                d1[@"user-info"] = e.userInfo;
            }
            NSDictionary *d =   @{ @"error" : @{ @"exception": d1 } };
            [req setResponsePlainText:[d jsonString]];
        }
    }
}

+ (NSString *)webIndexForm
{
    static NSMutableString *s = NULL;

    if(s)
    {
        return s;
    }
    s = [[NSMutableString alloc]init];
    [GenericInstance webHeader:s title:@"MSC"];
    [s appendString:@"<a href=\"/\">main menu</a>\n"];
    [s appendString:@"<h2>MSC Menu</h2>\n"];
    [s appendString:@"<UL>\n"];

    [s appendString:@"<LI><a href=\"/msc/appcontext-test\">appcontext-test</a>\n"];
    [s appendString:@"<LI><a href=\"/msc/mt-forwardSM\">mt-forwardSM</a>\n"];
    [s appendString:@"<LI><a href=\"/msc/mo-forwardSM\">mo-forwardSM</a>\n"];
    [s appendString:@"<LI><a href=\"/msc/sendRoutingInfo\">sendRoutingInfo</a>\n"];
    [s appendString:@"<LI><a href=\"/msc/sendRoutingInfoForSM\">sendRoutingInfoForSM</a>\n"];
    [s appendString:@"<LI><a href=\"/msc/sendRoutingInfoForGprs\">sendRoutingInfoForGprs</a>\n"];
    [s appendString:@"</UL>\n"];
    [s appendString:@"</body>\n"];
    [s appendString:@"</html>\n"];
    return s;
}


-(void) setConfig:(NSDictionary *)cfg applicationContext:(id)appContext
{
    [super setConfig:cfg applicationContext:appContext];
    if ([cfg[@"sms-forward-url"] length] > 0)
    {
        smsForwardUrl = [cfg[@"sms-forward-url"] stringValue];
    }
}

- (void)handleIncomingSMS:(NSString *)raw
                       oa:(UMGSMMAP_SM_RP_OA *)oa
                       da:(UMGSMMAP_SM_RP_DA *)da
                       ui:(UMGSMMAP_SignalInfo *)ui
{
    NSString *url = self.smsForwardUrl;

    @try
    {
        url = [url stringByReplacingOccurrencesOfString:@"%r"
                                             withString:[raw urlencode]];

        NSString *source = @"undefined";
        if(oa.msisdn)
        {
            source = oa.msisdn.stringValue;
        }
        else if(oa.serviceCentreAddressOA)
        {
            source = [NSString stringWithFormat:@"smsc:%@",
                      oa.serviceCentreAddressOA.stringValue];

        }
        url = [url stringByReplacingOccurrencesOfString:@"%s"
                                             withString:[source urlencode]];


        NSString *destination = @"undefined";
        if(da.imsi)
        {
            destination = [NSString stringWithFormat:@"imsi:%@",
                           da.imsi.stringValue];

        }
        else if(da.serviceCentreAddressDA)
        {
            destination = [NSString stringWithFormat:@"smsc:%@",
                           da.serviceCentreAddressDA.stringValue];

        }
        url = [url stringByReplacingOccurrencesOfString:@"%d"
                                             withString:[destination urlencode]];

        UMSMS *sms = [[UMSMS alloc]init];
        [sms decodePdu:ui.asn1_data context:NULL];


        NSString *text = sms.text;
        url = [url stringByReplacingOccurrencesOfString:@"%t"
                                             withString:[text urlencode]];
        NSLog(@"URL: %@",url);


        @synchronized(self)
        {
            if(webClient == NULL)
            {
                webClient = [[UMHTTPClient alloc]init];
            }
        }

        UMHTTPClientRequest *xreq = [[UMHTTPClientRequest alloc]initWithURLString:url
                                                                       withChache:NO
                                                                          timeout:60.0];
        
        [webClient simpleASynchronousRequest:xreq];
    }
    @catch(NSException *e)
    {
        NSLog(@"Exception %@",e);
    }
}
@end
