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
    return UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED;
}

- (void)  httpGetPost:(UMHTTPRequest *)req
{
    @autoreleasepool
    {
        NSDictionary *p = req.params;
        int pcount= (int)[p.allKeys count];
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
    [s appendString:@"<LI><a href=\"/msc/sendRoutingInfoForSM\">sendRoutingInfoForSM</a>\n"];
    [s appendString:@"</UL>\n"];
    [s appendString:@"</body>\n"];
    [s appendString:@"</html>\n"];
    return s;
}


-(void) setConfig:(NSDictionary *)cfg applicationContext:(id)appContext
{
    [super setConfig:cfg applicationContext:appContext];
}



- (void) MAP_Open_Ind:(NSString *)userIdentifier
               dialog:(NSString *)dialogId
          transaction:(NSString *)tcapTransactionId
    remoteTransaction:(NSString *)tcapRemoteTransactionId
                  map:(id<UMLayerGSMMAP_ProviderProtocol>)map
              variant:(UMTCAP_Variant)xvariant
       callingAddress:(SccpAddress *)src
        calledAddress:(SccpAddress *)dst
      dialoguePortion:(UMTCAP_asn1_dialoguePortion *)xdialoguePortion
              options:(NSDictionary *)options
{

}

- (void) MAP_Open_Resp:(NSString *)uidstr
                dialog:(NSString *)dialogId
           transaction:(NSString *)tcapTransactionId
     remoteTransaction:(NSString *)tcapRemoteTransactionId
                   map:(id<UMLayerGSMMAP_ProviderProtocol>)map
               variant:(UMTCAP_Variant)xvariant
        callingAddress:(SccpAddress *)src
         calledAddress:(SccpAddress *)dst
       dialoguePortion:(UMTCAP_asn1_dialoguePortion *)xdialoguePortion
               options:(NSDictionary *)xoptions
{
    
}
@end
