//
//  GenericInstance.m
//  hlrclient
//
//  Created by Andreas Fink on 10.05.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "GenericInstance.h"
#import "GenericTransaction.h"

@implementation GenericInstance
@synthesize instanceAddress;
@synthesize gsmMap;
@synthesize httpUser;
@synthesize httpPass;

- (GenericInstance *)initWithNumber:(NSString *)xmscAddress
{
    self = [super init];
    if(self)
    {
        instanceAddress = xmscAddress;
        transactions = [[UMSynchronizedDictionary alloc]init];
    }
    return self;
}

- (GenericInstance *)init
{
    self = [super init];
    if(self)
    {
        transactions = [[UMSynchronizedDictionary alloc]init];
        timeoutInSeconds = 60;
    }
    return self;
}

- (GenericInstance *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq
{
    self = [super initWithTaskQueueMulti:tq];
    if(self)
    {
        transactions = [[UMSynchronizedDictionary alloc]init];
        timeoutInSeconds = 60;
    }
    return self;
}

-(void) setConfig:(NSDictionary *)cfg applicationContext:(id)appContext
{
    [self readLayerConfig:cfg];

    timeoutInSeconds = 90;
    if (cfg[@"timeout"])
    {
        timeoutInSeconds =[cfg[@"timeout"] doubleValue];
    }
    if (cfg[@"number"])
    {
        instanceAddress =[cfg[@"number"] stringValue];
    }
    if(cfg[@"http-user"])
    {
        httpUser = [cfg[@"http-user"]stringValue];
    }
    if(cfg[@"http-password"])
    {
        httpPass = [cfg[@"http-password"]stringValue];
    }
}

- (void)startUp
{
}

- (NSString *)instancePrefix
{
    return @"G";
}

- (NSString *)getNewUserIdentifier
{
    @synchronized (self)
    {
        static int64_t lastUserId =1;
        int64_t uid;
        @synchronized(self)
        {
            lastUserId = (lastUserId + 1 ) % 0x7FFFFFFF;
            uid = lastUserId;
        }
        NSString *uidstr =  [NSString stringWithFormat:@"%@%08llX",self.instancePrefix,(long long)uid];
        return uidstr;
    }
}

- (GenericTransaction *)transactionById:(NSString *)userId
{
    return transactions[userId];
}

- (void)addTransaction:(GenericTransaction *)t userId:(NSString *)uidstr
{
    transactions[uidstr] = t;
}


- (void) markTransactionForTermination:(GenericTransaction *)t
{
    [transactions removeObjectForKey:t.userIdentifier];
}

#pragma mark -
#pragma mark handle incoming sessions


-(void)MAP_Delimiter_Ind:(NSString *)userIdentifier
                  dialog:(NSString *)dialogId
          callingAddress:(SccpAddress *)src
           calledAddress:(SccpAddress *)dst
         dialoguePortion:(UMTCAP_asn1_dialoguePortion *)xdialoguePortion
           transactionId:(NSString *)localTransactionId
     remoteTransactionId:(NSString *)remoteTransactionId
                 options:(NSDictionary *)options
{
    GenericTransaction *t = [self transactionById:userIdentifier];
    if(t==NULL)
    {
        NSLog(@"incoming MAP_Delimiter_Ind for unknown userIdentifier %@",userIdentifier);
        return;
    }
    [t MAP_Delimiter_Ind:userIdentifier
                  dialog:dialogId
          callingAddress:src
           calledAddress:dst
         dialoguePortion:xdialoguePortion
           transactionId:localTransactionId
     remoteTransactionId:remoteTransactionId
                 options:options];
}

-(void) MAP_Close_Ind:(NSString *)userIdentifier
              options:(NSDictionary *)options
{
    GenericTransaction *t = [self transactionById:userIdentifier];
    if(t==NULL)
    {
        NSLog(@"incoming MAP_Close_Ind for unknown userIdentifier %@",userIdentifier);
        return;
    }
    [t MAP_Close_Ind:userIdentifier
             options:options];
    [self markTransactionForTermination:t];
}


-(void) MAP_U_Abort_Req:(NSString *)userIdentifier
                options:(NSDictionary *)options
{
    GenericTransaction *t = [self transactionById:userIdentifier];
    if(t==NULL)
    {
        NSLog(@"incoming MAP_U_Abort_Req for unknown userIdentifier %@",userIdentifier);
        return;
    }
    [t MAP_U_Abort_Req:userIdentifier
               options:options];
    [self markTransactionForTermination:t];
}

-(void)MAP_U_Abort_Ind:(NSString *)userIdentifier
        callingAddress:(SccpAddress *)src
         calledAddress:(SccpAddress *)dst
       dialoguePortion:(UMTCAP_asn1_dialoguePortion *)xdialoguePortion
         transactionId:(NSString *)localTransactionId
   remoteTransactionId:(NSString *)remoteTransactionId
               options:(NSDictionary *)options
{
    GenericTransaction *t = [self transactionById:userIdentifier];
    if(t==NULL)
    {
        NSLog(@"incoming MAP_U_Abort_Ind for unknown userIdentifier %@",userIdentifier);
        return;
    }
    [t MAP_U_Abort_Ind:userIdentifier
        callingAddress:src
         calledAddress:dst
       dialoguePortion:xdialoguePortion
         transactionId:localTransactionId
   remoteTransactionId:remoteTransactionId
               options:options];
    [self markTransactionForTermination:t];
}

-(void) MAP_P_Abort_Ind:(NSString *)userIdentifier
         callingAddress:(SccpAddress *)src
          calledAddress:(SccpAddress *)dst
        dialoguePortion:(UMTCAP_asn1_dialoguePortion *)xdialoguePortion
          transactionId:(NSString *)localTransactionId
    remoteTransactionId:(NSString *)remoteTransactionId
                options:(NSDictionary *)options
{
    GenericTransaction *t = [self transactionById:userIdentifier];
    if(t==NULL)
    {
        NSLog(@"incoming MAP_P_Abort_Ind for unknown userIdentifier %@",userIdentifier);
        return;
    }
    [t MAP_P_Abort_Ind:userIdentifier
        callingAddress:src
         calledAddress:dst
       dialoguePortion:xdialoguePortion
         transactionId:localTransactionId
   remoteTransactionId:remoteTransactionId
               options:options];
    [self markTransactionForTermination:t];
}


-(void) MAP_Notice_Ind:(NSString *)userIdentifier
     tcapTransactionId:(NSString *)localTransactionId
                reason:(SCCP_ReturnCause)reason
               options:(NSDictionary *)options
{
    GenericTransaction *t = [self transactionById:userIdentifier];
    if(t==NULL)
    {
        NSLog(@"incoming MAP_Notice_Ind for unknown userIdentifier %@",userIdentifier);
        return;
    }
    [t MAP_Notice_Ind:userIdentifier
    tcapTransactionId:localTransactionId
               reason:reason
              options:options];
    [self markTransactionForTermination:t];
}

-(void)MAP_Continue_Ind:(NSString *)userIdentifier
         callingAddress:(SccpAddress *)src
          calledAddress:(SccpAddress *)dst
        dialoguePortion:(UMTCAP_asn1_dialoguePortion *)xdialoguePortion
          transactionId:(NSString *)localTransactionId
    remoteTransactionId:(NSString *)remoteTransactionId
                options:(NSDictionary *)options;
{
    GenericTransaction *t = [self transactionById:userIdentifier];
    if(t==NULL)
    {
        NSLog(@"incoming MAP_Continue_Ind for unknown userIdentifier %@",userIdentifier);
        return;
    }
    [t MAP_Continue_Ind:userIdentifier
         callingAddress:src
          calledAddress:dst
        dialoguePortion:xdialoguePortion
          transactionId:localTransactionId
    remoteTransactionId:remoteTransactionId
                options:options];
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
    NSLog(@"overload-me");
}

-(void) MAP_ReturnResult_Resp:(UMASN1Object *)param
                       userId:(NSString *)userIdentifier
                       dialog:(NSString *)dialogId
                  transaction:(NSString *)tcapTransactionId
                       opCode:(UMLayerGSMMAP_OpCode *)xopcode
                     invokeId:(int64_t)xinvokeId
                     linkedId:(int64_t)xlinkedId
                         last:(BOOL)xlast
                      options:(NSDictionary *)xoptions
{
    GenericTransaction *t = [self transactionById:userIdentifier];
    if(t==NULL)
    {
        NSLog(@"incoming MAP_ReturnResult_Resp for unknown userIdentifier %@",userIdentifier);
        return;
    }
    [t MAP_ReturnResult_Resp:param
                      userId:userIdentifier
                      dialog:dialogId
                 transaction:tcapTransactionId
                      opCode:xopcode
                    invokeId:xinvokeId
                    linkedId:xlinkedId
                        last:xlast
                     options:xoptions];
}

- (void) MAP_ReturnError_Resp:(UMASN1Object *)param
                       userId:(NSString *)userIdentifier
                       dialog:(NSString *)dialogId
                  transaction:(NSString *)tcapTransactionId
                       opCode:(UMLayerGSMMAP_OpCode *)xopcode
                     invokeId:(int64_t)xinvokeId
                     linkedId:(int64_t)xlinkedId
                    errorCode:(int64_t)err
                      options:(NSDictionary *)xoptions
{
    GenericTransaction *t = [self transactionById:userIdentifier];
    if(t==NULL)
    {
        NSLog(@"incoming MAP_ReturnError_Resp for unknown userIdentifier %@",userIdentifier);
        return;
    }
    [t MAP_ReturnError_Resp:param
                     userId:userIdentifier
                     dialog:dialogId
                transaction:tcapTransactionId
                     opCode:xopcode
                   invokeId:xinvokeId
                   linkedId:xlinkedId
                  errorCode:err
                    options:xoptions];
}

- (void) MAP_Reject_Resp:(UMASN1Object *)param
                  userId:(NSString *)userIdentifier
                  dialog:(NSString *)dialogId
             transaction:(NSString *)tcapTransactionId
                  opCode:(UMLayerGSMMAP_OpCode *)xopcode
                invokeId:(int64_t)xinvokeId
                linkedId:(int64_t)xlinkedId
               errorCode:(int64_t)err
                 options:(NSDictionary *)xoptions
{
    GenericTransaction *t = [self transactionById:userIdentifier];
    if(t==NULL)
    {
        NSLog(@"incoming MAP_Reject_Resp for unknown userIdentifier %@",userIdentifier);
        return;
    }
    [t MAP_Reject_Resp:param
                userId:userIdentifier
                dialog:dialogId
           transaction:tcapTransactionId
                opCode:xopcode
              invokeId:xinvokeId
              linkedId:xlinkedId
             errorCode:err
               options:xoptions];
}

-(void)MAP_Unidirectional_Ind:(NSDictionary *)options
               callingAddress:(SccpAddress *)src
                calledAddress:(SccpAddress *)dst
              dialoguePortion:(UMTCAP_asn1_dialoguePortion *)xdialoguePortion
                transactionId:(NSString *)localTransactionId
          remoteTransactionId:(NSString *)remoteTransactionId
{
    NSLog(@"MAP_Unidirectional_Ind");
}


- (UMSynchronizedSortedDictionary *)decodeSmsObject:(NSData *)pdu
                                            context:(id)context
{
    return NULL;
}

- (BOOL)authenticateUser:(NSString *)user pass:(NSString *)pass
{
    if([user isEqualToString:httpUser] &&  [pass isEqualToString:httpPass])
    {
        return YES;
    }
    return NO;
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
            if([path hasSuffix:@"/msc/index.php"])
            {
                path = @"/msc";
            }
            else if([path hasSuffix:@"/msc/"])
            {
                path = @"/msc";
            }
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

            if([path isEqualToString:@"/msc"])
            {
                [req setResponseHtmlString:[GenericInstance webIndexForm]];
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

- (void)httpRequestTimeout:(UMHTTPRequest *)req
{
    NSDictionary *d = @{ @"error" : @"timeout" };
    [req setResponsePlainText:[d jsonString]];
}

- (NSString *)status
{
    return [NSString stringWithFormat:@"IS:%lu",[transactions count]];
}

+ (NSString *)webIndexForm
{
    static NSMutableString *s = NULL;

    if(s)
    {
        return s;
    }
    s = [[NSMutableString alloc]init];
    [GenericInstance webHeader:s title:@"GSM-API Main Menu"];
    [s appendString:@"<h2>Generic Menu</h2>\n"];
    [s appendString:@"<UL>\n"];
    /*
     [s appendString:@"<LI><a href=\"/msc/updateLocation.php\">updateLocation</a>\n"];
     [s appendString:@"<LI><a href=\"/vlr/processUnstructuredSS-Request.php\">processUnstructuredSS-Request</a>\n"];
     [s appendString:@"<LI><a href=\"/vlr/unstructuredSS-Request.php\">unstructuredSS-Request</a>\n"];
     [s appendString:@"<LI><a href=\"/vlr/unstructuredSS-Notify.php\">unstructuredSS-Notify</a>\n"];
     */
    [s appendString:@"</UL>\n"];
    [s appendString:@"</body>\n"];
    [s appendString:@"</html>\n"];
    return s;
}


+ (void)webHeader:(NSMutableString *)s title:(NSString *)t
{
    [s appendString:@"<html>\n"];
    [s appendString:@"<header>\n"];
    [s appendString:@"    <link rel=\"stylesheet\" href=\"/css/style.css\" type=\"text/css\">\n"];
    [s appendFormat:@"    <title>%@</title>\n",t];
    [s appendString:@"</header>\n"];
    [s appendString:@"<body>\n"];
}


@end
