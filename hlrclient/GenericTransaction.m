//
//  GenericTransaction.m
//  hlrclient
//
//  Created by Andreas Fink on 10.05.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "GenericInstance.h"
#import "GenericTransaction.h"

@implementation GenericTransaction

@synthesize gInstance;
@synthesize userIdentifier;
@synthesize query;
@synthesize operation;
@synthesize localAddress;
@synthesize remoteAddress;
@synthesize req;
@synthesize startTime;
@synthesize options;
@synthesize applicationContext;
@synthesize incomingDialogPortion;
@synthesize incomingApplicationContext;
@synthesize sccp_sent;
@synthesize sccp_received;
@synthesize sccpDebugEnabled;
@synthesize sccpTracefileEnabled;
@synthesize timeoutValue;
@synthesize timeoutTime;
@synthesize userInfo;
@synthesize dialogProtocolVersion;
@synthesize incomingUserInfo;
@synthesize dialogId;
@synthesize opcode;
@synthesize tcapVariant;
@synthesize incomingOptions;
@synthesize transactionId;
@synthesize remoteTransactionId;
@synthesize outputFormat;
@synthesize doEnd;
@synthesize pcap;
@synthesize nowait;
@synthesize undefinedTransaction;
@synthesize transactionName;

- (UMMTP3Variant)mtp3Variant
{
    return gInstance.gsmMap.tcap.attachedLayer.variant;
}

#define VERIFY_MAP(a,b)\
if( a != b) \
{ \
NSLog(@"ERROR: got MAP=%@ but was expecting MAP=%@",a,b);\
return;\
}

#define VERIFY_TRANSACTION(a,b)\
if(a==NULL) \
{   \
a = b; \
}\
else \
{\
if(![a isEqualToString:b]) \
{ \
NSLog(@"ERROR: got TransactionID=%@ but was expecting TransactionID=%@",a,b);\
return;\
}\
}

#define VERIFY_DIALOG(a,b)\
if(a==NULL) \
{   \
a = b; \
}\
else \
{\
if(![a isEqualToString:b]) \
{ \
NSLog(@"ERROR: got DialogID=%@ but was expecting DialogID=%@",a,b);\
return;\
}\
}

#define VERIFY_UID(a,b)\
if(a==NULL) \
{   \
a = b; \
}\
else \
{\
if(![a isEqualToString:b]) \
{ \
NSLog(@"ERROR: got UserIdentifier=%@ but was expecting UserIdentifier=%@",a,b);\
return;\
}\
}

- (NSString *)getNewUserIdentifier
{
    return NULL;
}

#pragma mark -
#pragma mark initializer handling


-(GenericTransaction *)initWithHttpReq:(UMHTTPRequest *)xreq
                             operation:(int64_t)op
                              instance:(GenericInstance *)inst
{
    self = [super init];
    if(self)
    {
        userIdentifier = [inst getNewUserIdentifier];
        _components = [[UMSynchronizedArray alloc]init];
        req  = xreq;
        operation = op;
        if(operation != UMGSMMAP_Opcode_noOpcode)
        {
            opcode = [[UMLayerGSMMAP_OpCode alloc]initWithOperationCode:operation];
        }
        gInstance = inst;
        options = [[NSMutableDictionary alloc]init];
        [self setTimeouts];
        [self setOptions];
        undefinedTransaction = NO; /* we get called for overrided object here */
        transactionName = [[self class] description];
        name = transactionName; /* umtask name */
        firstInvokeId = AUTO_ASSIGN_INVOKE_ID;
        timeoutValue = 90;

        NSDictionary *p = req.params;
        NSString *to = [p[@"timeout"]urldecode];
        if(to.length > 0)
        {
            timeoutValue = [to doubleValue];
        }
        [req makeAsyncWithTimeout:timeoutValue delegate:gInstance];
    }
    return self;
}

- (GenericTransaction *)initWithQuery:(UMASN1Object *)xquery
                       userIdentifier:(NSString *)uid
                                  req:(UMHTTPRequest *)xreq
                            operation:(int64_t) xop
                       callingAddress:(SccpAddress *)src
                        calledAddress:(SccpAddress *)dst
                             instance:(GenericInstance *)xInstance
                   applicationContext:(UMTCAP_asn1_objectIdentifier *)xapplicationContext
                             userInfo:(UMTCAP_asn1_userInformation *)xuserInfo
                              options:(NSDictionary *) xoptions
{
    self = [super init];
    if(self)
    {
        localAddress = src;
        remoteAddress = dst;
        req  = xreq;
        operation = xop;
        gInstance = xInstance;
        applicationContext = xapplicationContext;
        userInfo = xuserInfo;
        if(xoptions)
        {
            options = [xoptions mutableCopy];
        }
        else
        {
            options = [[NSMutableDictionary alloc]init];
        }
        [self setTimeouts];
        [self setOptions];
    }
    return self;
}

- (GenericTransaction *)initWithTransaction:(GenericTransaction *)ot
{
    self = [super init];
    if(self)
    {
        userIdentifier = ot.userIdentifier;
        query = ot.query;
        opcode = ot.opcode;
        gInstance = ot.gInstance;
        localAddress = ot.localAddress;
        remoteAddress = ot.remoteAddress;
        req = ot.req;
        startTime = ot.startTime;
        options = [ot.options mutableCopy];
        applicationContext = ot.applicationContext;
        incomingApplicationContext = ot.incomingApplicationContext;
        sccp_sent = ot.sccp_sent;
        sccp_received = ot.sccp_received;
        sccpDebugEnabled = ot.sccpDebugEnabled;
        sccpTracefileEnabled = ot.sccpTracefileEnabled;
        pcap = ot.pcap;
        timeoutValue = ot.timeoutValue;
        timeoutTime = ot.timeoutTime;
        userInfo = ot.userInfo;
        incomingUserInfo = ot.incomingUserInfo;
        dialogId = ot.dialogId;
        doEnd = ot.doEnd;
        tcapVariant = ot.tcapVariant;
        transactionId = ot.transactionId;
        remoteTransactionId = ot.remoteTransactionId;
        incomingOptions = ot.incomingOptions;
        _components = ot.components;
        outputFormat = ot.outputFormat;
        nowait = ot.nowait;
        undefinedTransaction = NO; /* we get called for overrided object here */
    }
    return self;
}


#pragma mark -
#pragma mark handle incoming components

-(void) MAP_Invoke_Ind:(UMASN1Object *)param
                userId:(NSString *)xuserIdentifier
                dialog:(NSString *)xdialogId
           transaction:(NSString *)xtcapTransactionId
                opCode:(UMLayerGSMMAP_OpCode *)xopcode
              invokeId:(int64_t)xinvokeId
              linkedId:(int64_t)xlinkedId
                  last:(BOOL)xlast
               options:(NSDictionary *)xoptions
{
    /* this should be overriden */
}

-(void) MAP_Invoke_Ind_Log:(UMASN1Object *)param
                    userId:(NSString *)xuserIdentifier
                    dialog:(NSString *)xdialogId
               transaction:(NSString *)xtcapTransactionId
                    opCode:(UMLayerGSMMAP_OpCode *)xopcode
                  invokeId:(int64_t)xinvokeId
                  linkedId:(int64_t)xlinkedId
                      last:(BOOL)xlast
                   options:(NSDictionary *)xoptions
{
    UMSynchronizedSortedDictionary *info_sub = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *info = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *comp = [[UMSynchronizedSortedDictionary alloc]init];
    info_sub[@"invokeId"] =  @(xinvokeId);
    if(xlinkedId != TCAP_UNDEFINED_LINKED_ID)
    {
        info_sub[@"linkedId"] = @(xlinkedId);
    }

    if(param.objectName)
    {
        info_sub[param.objectName] =  param.objectValue;
    }

    info[@"invoke"] = info_sub;
    comp[@"rx"] = info;
    [_components addObject:comp];
}

- (void) MAP_ReturnResult_Log:(UMASN1Object *)xparam
                       dialog:(NSString *)dialogId
                     invokeId:(int64_t)xinvokeId
                     linkedId:(int64_t)xlinkedId
                       opCode:(UMLayerGSMMAP_OpCode *)xopcode
                         last:(int64_t)xlast
                      options:(NSDictionary *)xoptions
{
    UMSynchronizedSortedDictionary *info_sub = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *info = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *comp = [[UMSynchronizedSortedDictionary alloc]init];
    info_sub[@"invokeId"] =  @(xinvokeId);
    if(xlinkedId != TCAP_UNDEFINED_LINKED_ID)
    {
        info_sub[@"linkedId"] = @(xlinkedId);
    }

    if(xparam.objectName)
    {
        info_sub[xparam.objectName] =  xparam.objectValue;
    }
    if(xlast)
    {
        info[@"ReturnResultLast"] = info_sub;
    }
    else
    {
        info[@"ReturnResultNotLast"] = info_sub;
    }
    comp[@"tx"] = info;
    [_components addObject:comp];
}

-(void) MAP_ReturnResult_Resp:(UMASN1Object *)param
                       userId:(NSString *)xuserIdentifier
                       dialog:(NSString *)xdialogId
                  transaction:(NSString *)xtcapTransactionId
                       opCode:(UMLayerGSMMAP_OpCode *)xopcode
                     invokeId:(int64_t)xinvokeId
                     linkedId:(int64_t)xlinkedId
                         last:(BOOL)xlast
                      options:(NSDictionary *)xoptions
{
    VERIFY_UID(userIdentifier,xuserIdentifier);
    VERIFY_DIALOG(dialogId,xdialogId);
    VERIFY_TRANSACTION(transactionId,xtcapTransactionId);

    UMSynchronizedSortedDictionary *info_sub = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *info = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *comp = [[UMSynchronizedSortedDictionary alloc]init];
    info_sub[@"invokeId"] =  @(xinvokeId);
    if(xlinkedId != TCAP_UNDEFINED_LINKED_ID)
    {
        info_sub[@"linkedId"] = @(xlinkedId);
    }

    if(param.objectName)
    {
        info_sub[param.objectName] =  param.objectValue;
    }

    if(xlast)
    {
        info[@"ReturnResultLast"] = info_sub;
    }
    else
    {
        info[@"ReturnResult"] = info_sub;
    }
    if(_components==NULL)
    {
        _components = [[UMSynchronizedArray alloc]init];
    }
    comp[@"rx"] = info;
    [_components addObject:comp];
    //NSString *opcodeString = [xopcode description];
    //NSLog(@"GenericTransaction: MAP_ReturnResult_Resp for opcode %@: %@",opcodeString,info);
}

- (void) MAP_ReturnError_Resp:(UMASN1Object *)param
                       userId:(NSString *)xuserIdentifier
                       dialog:(NSString *)xdialogId
                  transaction:(NSString *)xtcapTransactionId
                       opCode:(UMLayerGSMMAP_OpCode *)xopcode
                     invokeId:(int64_t)xinvokeId
                     linkedId:(int64_t)xlinkedId
                    errorCode:(int64_t)err
                      options:(NSDictionary *)xoptions
{
    VERIFY_UID(userIdentifier,xuserIdentifier);
    VERIFY_DIALOG(dialogId,xdialogId);
    VERIFY_TRANSACTION(transactionId,xtcapTransactionId);

    if(_components==NULL)
    {
        _components = [[UMSynchronizedArray alloc]init];
    }
    UMSynchronizedSortedDictionary *info_sub = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *info = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *comp = [[UMSynchronizedSortedDictionary alloc]init];
    info_sub[@"invokeId"] =  @(xinvokeId);
    if(xlinkedId != TCAP_UNDEFINED_LINKED_ID)
    {
        info_sub[@"linkedId"] = @(xlinkedId);
    }

    if(param.objectName)
    {
        info_sub[param.objectName] =  param.objectValue;
    }
    info_sub[@"tcap-error"] =  @(err);
    NSString *errString = [UMLayerGSMMAP decodeError:(int)err];
    if(errString)
    {
        info_sub[@"error-description"] =  errString;
    }

    info[@"ReturnError"] = info_sub;
    comp[@"rx"] = info;
    [_components addObject:comp];
    //NSString *opcodeString = [xopcode description];
    //NSLog(@"MAP_ReturnError_Resp for opcode %@: %@",opcodeString,info);
    [self MAP_Close_Ind:xuserIdentifier options:options];
}

- (void) MAP_Reject_Resp:(UMASN1Object *)param
                  userId:(NSString *)xuserIdentifier
                  dialog:(NSString *)xdialogId
             transaction:(NSString *)xtcapTransactionId
                  opCode:(UMLayerGSMMAP_OpCode *)xopcode
                invokeId:(int64_t)xinvokeId
                linkedId:(int64_t)xlinkedId
               errorCode:(int64_t)err
                 options:(NSDictionary *)xoptions
{
    VERIFY_UID(userIdentifier,xuserIdentifier);
    VERIFY_DIALOG(dialogId,xdialogId);
    VERIFY_TRANSACTION(transactionId,xtcapTransactionId);

    UMSynchronizedSortedDictionary *info_sub = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *info = [[UMSynchronizedSortedDictionary alloc]init];
    UMSynchronizedSortedDictionary *comp = [[UMSynchronizedSortedDictionary alloc]init];
    info_sub[@"invokeId"] =  @(xinvokeId);
    if(xlinkedId != TCAP_UNDEFINED_LINKED_ID)
    {
        info_sub[@"linkedId"] = @(xlinkedId);
    }

    if(param.objectName)
    {
        info_sub[param.objectName] =  param.objectValue;
    }

    info[@"Reject"] = info_sub;
    comp[@"rx"] = info;
    [_components addObject:comp];
    //NSString *opcodeString = [xopcode description];
    //NSLog(@"MAP_Reject_Resp for opcode %@: %@",opcodeString,info);
    [self MAP_Close_Ind:xuserIdentifier options:options];
}

#pragma mark -
#pragma mark Session Handling

- (void) MAP_Open_Ind:(NSString *)xuserIdentifier
               dialog:(NSString *)xdialogId
          transaction:(NSString *)tcapTransactionId
    remoteTransaction:(NSString *)tcapRemoteTransactionId
                  map:(id<UMLayerGSMMAP_ProviderProtocol>)map
              variant:(UMTCAP_Variant)xvariant
       callingAddress:(SccpAddress *)src
        calledAddress:(SccpAddress *)dst
      dialoguePortion:(UMTCAP_asn1_dialoguePortion *)xdialoguePortion
              options:(NSDictionary *)xoptions
{
    userIdentifier = xuserIdentifier;
    remoteAddress = src;
    localAddress = dst;
    startTime = [NSDate date];
    dialogId = xdialogId;
    tcapVariant = xvariant;
    transactionId = tcapTransactionId;
    remoteTransactionId = tcapRemoteTransactionId;
    incomingOptions = xoptions;
}

- (void) MAP_Open_Resp:(NSString *)userIdentifier
                dialog:(NSString *)dialogId
           transaction:(NSString *)tcapTransactionId
     remoteTransaction:(NSString *)tcapremoteTransactionId
                   map:(id<UMLayerGSMMAP_ProviderProtocol>)map
               variant:(UMTCAP_Variant)xvariant
        callingAddress:(SccpAddress *)src
         calledAddress:(SccpAddress *)dst
       dialoguePortion:(UMTCAP_asn1_dialoguePortion *)xdialoguePortion
               options:(NSDictionary *)options
{

}

-(void)MAP_Delimiter_Ind:(NSString *)userIdentifier
                  dialog:(NSString *)dialogId
          callingAddress:(SccpAddress *)src
           calledAddress:(SccpAddress *)dst
         dialoguePortion:(UMTCAP_asn1_dialoguePortion *)xdialoguePortion
           transactionId:(NSString *)localTransactionId
     remoteTransactionId:(NSString *)remoteTransactionId
                 options:(NSDictionary *)options
{
    remoteAddress = src;
    localAddress = dst;
    /*FIXME */
}

-(void)MAP_Continue_Ind:(NSString *)userIdentifier
         callingAddress:(SccpAddress *)src
          calledAddress:(SccpAddress *)dst
        dialoguePortion:(UMTCAP_asn1_dialoguePortion *)xdialoguePortion
          transactionId:(NSString *)localTransactionId
    remoteTransactionId:(NSString *)remoteTransactionId
                options:(NSDictionary *)options
{
    localAddress = dst;
    remoteAddress = src;
    NSLog(@"we got a MAP_Continue_Ind");
}

-(void)MAP_Unidirectional_Ind:(NSDictionary *)options
               callingAddress:(SccpAddress *)src
                calledAddress:(SccpAddress *)dst
              dialoguePortion:(UMTCAP_asn1_dialoguePortion *)xdialoguePortion
                transactionId:(NSString *)localTransactionId
          remoteTransactionId:(NSString *)remoteTransactionId
{

}


-(void) MAP_Close_Ind:(NSString *)xuserIdentifier
              options:(NSDictionary *)xoptions
{
    @synchronized(self)
    {
        VERIFY_UID(userIdentifier,xuserIdentifier);
        //NSLog(@"GenericTransaction: MAP_Close_Ind: backtrace: %@",UMBacktrace(NULL,0));

        /* now we can finish the HTTP request */

        UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
        dict[@"query"] =  query.objectValue;
        if(_components)
        {
            dict[@"responses"] = _components;
        }
        else
        {
            dict[@"responses"] = [[NSArray alloc]init];
        }

        UMSynchronizedSortedDictionary *sccp_info = [[UMSynchronizedSortedDictionary alloc]init];
        if(remoteAddress)
        {
            sccp_info[@"sccp-remote-address"] = remoteAddress.objectValue;
        }
        if(localAddress)
        {
            sccp_info[@"sccp-local-address"] = localAddress.objectValue;
        }
        dict[@"sccp-info"] = sccp_info;

        if((sccpDebugEnabled) && (xoptions[@"sccp-pdu"]))
        {
            [sccp_received addObject:xoptions[@"sccp-pdu"]];
        }
        if((sccpTracefileEnabled) && (xoptions[@"sccp-pdu"]))
        {
            [pcap writePdu:[xoptions[@"sccp-pdu"] unhexedData]];
        }

        dict[@"user-identifier"] = userIdentifier;
        dict[@"map-dialog-id"] = dialogId;
        dict[@"tcap-transaction-id"] = transactionId;
        dict[@"tcap-end-indicator"] = @(YES);
        [self outputResult2:dict];
        [self markForTermination];
    }
}

- (void)markForTermination
{
    [gInstance markTransactionForTermination:self];
}

- (void)outputResult2:(UMSynchronizedSortedDictionary *)dict
{
    if(sccpDebugEnabled)
    {
        dict[@"sccp-sent" ]       = sccp_sent;
        dict[@"sccp-received"]    = sccp_received;
    }
    if(sccpTracefileEnabled)
    {
        NSData *data = [pcap dataAndClose];
        [req setResponseHeader:@"Content-Type" withValue:@"application/octet-stream"];
        [req setResponseHeader:@"Content-Disposition" withValue:@"attachment; filename=trace.pcap"];
        [req setResponseData:data];
    }
    else
    {
        NSString *json;
        @try
        {
            json = [dict jsonString];
        }
        @catch(id err)
        {
            NSLog(@"%@",err);
        }
        if(!json)
        {
            json = [NSString stringWithFormat:@"json-encoding problem %@",dict];
        }
        [req setResponsePlainText:json];
    }
    [req resumePendingRequest];
}

-(void) MAP_U_Abort_Req:(NSString *)userIdentifier
                options:(NSDictionary *)options
{

}

-(void)MAP_U_Abort_Ind:(NSString *)xuserIdentifier
        callingAddress:(SccpAddress *)src
         calledAddress:(SccpAddress *)dst
       dialoguePortion:(UMTCAP_asn1_dialoguePortion *)xdialoguePortion
         transactionId:(NSString *)xlocalTransactionId
   remoteTransactionId:(NSString *)xremoteTransactionId
               options:(NSDictionary *)xoptions
{
    @synchronized (self)
    {
        VERIFY_UID(userIdentifier,xuserIdentifier);
        /***/

        /* now we can finish the HTTP request */

        UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
        dict[@"query"] =  query.objectValue;
        if(_components)
        {
            dict[@"MAP_U_Abort_Ind"] = _components;
        }
        else
        {
            dict[@"MAP_U_Abort_Ind"] = @(YES);

        }
        UMSynchronizedSortedDictionary *sccp_info = [[UMSynchronizedSortedDictionary alloc]init];
        if(remoteAddress)
        {
            sccp_info[@"sccp-remote-address"] = remoteAddress.objectValue;
        }
        if(localAddress)
        {
            sccp_info[@"sccp-local-address"] = localAddress.objectValue;
        }
        dict[@"sccp-info"] = sccp_info;

        if((sccpDebugEnabled) && (xoptions[@"sccp-pdu"]))
        {
            [sccp_received addObject:xoptions[@"sccp-pdu"]];
        }
        if((sccpTracefileEnabled) && (xoptions[@"sccp-pdu"]))
        {
            [pcap writePdu:[xoptions[@"sccp-pdu"] unhexedData]];
        }

        dict[@"user-identifier"] = userIdentifier;
        dict[@"map-dialog-id"] = dialogId;
        if(xlocalTransactionId)
        {
            if(transactionId==NULL)
            {
                transactionId = xlocalTransactionId;
            }
            dict[@"tcap-transaction-id"] = xlocalTransactionId;
        }
        if(xremoteTransactionId)
        {
            if(remoteTransactionId==NULL)
            {
                remoteTransactionId = xremoteTransactionId;
            }
            dict[@"tcap-remote-transaction-id"] = xremoteTransactionId;
        }
        [self outputResult2:dict];

        [self markForTermination];
        NSLog(@"MAP_U_Abort_Ind");
    }
}


-(void) MAP_P_Abort_Ind:(NSString *)xuserIdentifier
         callingAddress:(SccpAddress *)src
          calledAddress:(SccpAddress *)dst
        dialoguePortion:(UMTCAP_asn1_dialoguePortion *)xdialoguePortion
          transactionId:(NSString *)xlocalTransactionId
    remoteTransactionId:(NSString *)xremoteTransactionId
                options:(NSDictionary *)xoptions
{
    @synchronized(self)
    {
        VERIFY_UID(userIdentifier,xuserIdentifier);
        /***/

        /* now we can finish the HTTP request */

        UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
        if(query)
        {
            dict[@"query"] =  query.objectValue;
        }
        if(_components)
        {
            dict[@"MAP_P_Abort_Ind"] = _components;
        }
        else
        {
            dict[@"MAP_P_Abort_Ind"] = @"YES";
        }
        UMSynchronizedSortedDictionary *sccp_info = [[UMSynchronizedSortedDictionary alloc]init];
        if(remoteAddress)
        {
            sccp_info[@"sccp-remote-address"] = remoteAddress.objectValue;
        }
        if(localAddress)
        {
            sccp_info[@"sccp-local-address"] = localAddress.objectValue;
        }
        dict[@"sccp-info"] = sccp_info;

        if((sccpDebugEnabled) && (xoptions[@"sccp-pdu"]))
        {
            [sccp_received addObject:xoptions[@"sccp-pdu"]];
        }
        if((sccpTracefileEnabled) && (xoptions[@"sccp-pdu"]))
        {
            [pcap writePdu:[xoptions[@"sccp-pdu"] unhexedData]];
        }

        dict[@"user-identifier"] = userIdentifier;
        dict[@"map-dialog-id"] = dialogId;
        if(xlocalTransactionId)
        {
            if(transactionId==NULL)
            {
                transactionId = xlocalTransactionId;
            }
            dict[@"tcap-transaction-id"] = xlocalTransactionId;
        }
        if(xremoteTransactionId)
        {
            if(remoteTransactionId==NULL)
            {
                remoteTransactionId = xremoteTransactionId;
            }
            dict[@"tcap-remote-transaction-id"] = xremoteTransactionId;
        }
        [self outputResult2:dict];

        [self markForTermination];
        NSLog(@"MAP_P_Abort_Ind");
    }
}

-(void) MAP_Notice_Ind:(NSString *)userIdentifier
               options:(NSDictionary *)options
{

}

-(void) MAP_Notice_Ind:(NSString *)userIdentifier
     tcapTransactionId:(NSString *)localTransactionId
                reason:(SCCP_ReturnCause)reason
               options:(NSDictionary *)options
{
    NSLog(@"VLR: MAP_Notice_Ind");
}

#pragma mark -
#pragma mark helper methods
- (UMSynchronizedSortedDictionary *)decodeSmsObject:(NSData *)pdu
                                            context:(id)context
{
    return NULL;
}

- (void)sccpTraceSentPdu:(NSData *)data
                 options:(NSDictionary *)options
{

}

- (void)sccpTraceReceivedPdu:(NSData *)data
                     options:(NSDictionary *)options
{

}

- (void) handleSccpAddressesDefaultCallingSsn:(NSString *)defaultCallingSsn
                             defaultCalledSsn:(NSString *)defaultCalledSsn
                         defaultCallingNumber:(NSString *)defaultCalling
                          defaultCalledNumber:(NSString *)defaultCalled
                      defaultCalledNumberPlan:(int)numberplan
{
    NSDictionary *p = req.params;

    NSString *calling_ssn     = [p[@"calling-ssn"]urldecode];
    NSString *called_ssn      = [p[@"called-ssn"]urldecode];
    NSString *calling_address = [p[@"calling-address"]urldecode];
    NSString *called_address  = [p[@"called-address"]urldecode];
    NSString *calling_tt      = [p[@"calling-tt"]urldecode];
    NSString *called_tt       = [p[@"called-tt"]urldecode];
    NSString *opc = [p[@"opc"]urldecode];
    NSString *dpc = [p[@"dpc"]urldecode];

    if([calling_ssn isEqualToString:@"default"])
    {
        calling_ssn = NULL;
    }
    if([called_ssn isEqualToString:@"default"])
    {
        called_ssn = NULL;
    }
    if([calling_address isEqualToString:@"default"])
    {
        calling_address = NULL;
    }
    if([called_address isEqualToString:@"default"])
    {
        called_address = NULL;
    }
    if([calling_tt isEqualToString:@"default"])
    {
        calling_tt = NULL;
    }
    if([called_tt isEqualToString:@"default"])
    {
        called_tt = NULL;
    }


    if(([opc isEqualToString:@"default"]) || (opc.length == 0))
    {
        opc = NULL;
        _opc = NULL;
    }
    else
    {
        _opc = opc;
    }

    if(([dpc isEqualToString:@"default"])  || (dpc.length == 0))
    {
        dpc = NULL;
        _dpc = NULL;
    }
    else
    {
        _dpc = dpc;
    }

    if(calling_address.length > 0)
    {
        self.localAddress = [[SccpAddress alloc]initWithHumanReadableString:calling_address variant:self.mtp3Variant];
    }
    else
    {
        self.localAddress = [[SccpAddress alloc]initWithHumanReadableString:defaultCalling variant:self.mtp3Variant];
    }
    if(called_address.length > 0)
    {
        self.remoteAddress  = [[SccpAddress alloc]initWithHumanReadableString:called_address variant:self.mtp3Variant];
    }
    else
    {
        self.remoteAddress  = [[SccpAddress alloc]initWithHumanReadableString:defaultCalled variant:self.mtp3Variant];
        self.remoteAddress.npi.npi = numberplan;
    }
    self.localAddress.ai.nationalReservedBit=NO;
    self.localAddress.ai.subSystemIndicator = YES;
    if(calling_ssn.length==0)
    {
        if(defaultCallingSsn==0)
        {
            self.localAddress.ssn=[[SccpSubSystemNumber alloc]initWithInt:SCCP_SSN_VLR];
        }
        else
        {
            self.localAddress.ssn = [[SccpSubSystemNumber alloc]initWithName:defaultCallingSsn];
        }
    }
    else
    {
        self.localAddress.ssn=[[SccpSubSystemNumber alloc]initWithName:calling_ssn];

    }
    self.localAddress.tt.tt = 0;


    self.remoteAddress.ai.nationalReservedBit=NO;
    self.remoteAddress.ai.globalTitleIndicator = SCCP_GTI_ITU_NAI_TT_NPI_ENCODING;
    self.remoteAddress.ai.subSystemIndicator = YES;
    self.remoteAddress.ssn.ssn=SCCP_SSN_HLR;
    if(called_ssn.length==0)
    {
        if(defaultCalledSsn==0)
        {
            self.remoteAddress.ssn = [[SccpSubSystemNumber alloc]initWithInt:SCCP_SSN_HLR];
        }
        else
        {
            self.remoteAddress.ssn = [[SccpSubSystemNumber alloc]initWithName:defaultCalledSsn];
        }
    }
    else
    {
        self.remoteAddress.ssn=[[SccpSubSystemNumber alloc]initWithName:called_ssn];
    }
    if(calling_tt.length > 0)
    {
        self.localAddress.tt = [[SccpTranslationTableNumber alloc]initWithInt:[calling_tt intValue]];
    }
    else
    {
        self.localAddress.tt = [[SccpTranslationTableNumber alloc]initWithInt:0];
    }
    if(called_tt.length > 0)
    {
        self.remoteAddress.tt = [[SccpTranslationTableNumber alloc]initWithInt:[called_tt intValue]];
    }
    else
    {
        self.remoteAddress.tt = [[SccpTranslationTableNumber alloc]initWithInt:0];
    }
}

- (void)setDefaultApplicationContext:(NSString *)def
{
    NSDictionary *p = req.params;

    NSString *context = def;
    if (p[@"application-context"])
    {
        context = [p[@"application-context"] stringValue];
    }
    else if([context length]==0)
    {
        context =  NULL;
    }
    else if([context isEqualToString:@"default"])
    {
        context = def;
    }
    applicationContext =  [[UMTCAP_asn1_objectIdentifier alloc]initWithString:context];
}

- (void)setUserInfo_MAP_Open
{
    NSDictionary *p = req.params;

    NSString *mapopen_origination_imsi;
    NSString *mapopen_origination_msisdn;
    NSString *mapopen_destination_imsi;
    NSString *mapopen_destination_msisdn;

    SET_OPTIONAL_PARAMETER(p,mapopen_destination_imsi,@"map-open-destination-imsi");
    SET_OPTIONAL_PARAMETER(p,mapopen_destination_msisdn,@"map-open-destination-msisdn");

    SET_OPTIONAL_PARAMETER(p,mapopen_origination_imsi,@"map-open-origination-imsi");
    SET_OPTIONAL_PARAMETER(p,mapopen_origination_msisdn,@"map-open-origination-msisdn");

    /** MAP OPEN **/
    userInfo = [[UMTCAP_asn1_userInformation alloc]init];
    userInfo.external = [[UMTCAP_asn1_external alloc]init];
    userInfo.external.objectIdentifier = [[UMTCAP_asn1_objectIdentifier alloc]initWithString:@"04000001010101"];
    UMGSMMAP_MAP_DialoguePDU *map_dialog = [[UMGSMMAP_MAP_DialoguePDU alloc]init];

    if((mapopen_destination_imsi.length == 0) &&
       (mapopen_destination_msisdn.length == 0) &&
       (mapopen_origination_imsi.length == 0) &&
       (mapopen_origination_msisdn.length == 0))

    {
        userInfo = NULL;
    }

    map_dialog.map_open = [[UMGSMMAP_MAP_OpenInfo alloc]init];
    if(mapopen_destination_imsi.length>0)
    {
        map_dialog.map_open.destinationReference = [[UMGSMMAP_AddressString alloc]initWithImsi:mapopen_destination_imsi];
    }
    else if(mapopen_destination_msisdn.length>0)
    {
        map_dialog.map_open.destinationReference = [[UMGSMMAP_AddressString alloc]initWithString:mapopen_destination_msisdn];
    }

    if(mapopen_origination_imsi.length>0)
    {
        map_dialog.map_open.originationReference = [[UMGSMMAP_AddressString alloc]initWithImsi:mapopen_origination_imsi];
    }
    else if(mapopen_origination_msisdn.length>0)
    {
        map_dialog.map_open.originationReference = [[UMGSMMAP_AddressString alloc]initWithString:mapopen_origination_msisdn];
    }

    userInfo.external.externalObject = map_dialog;

}

-(void) setTimeouts
{
    timeoutValue = 90;
    NSDictionary *p = req.params;

    NSString *to = [p[@"timeout"]urldecode];

    if(to.length > 0)
    {
        timeoutValue = [to doubleValue];
    }
    timeoutTime = [NSDate dateWithTimeInterval:timeoutValue sinceDate:[NSDate date]];
}

- (void) setOptions
{
    NSDictionary *p = req.params;
    if(options==NULL)
    {
        @throw(@"options not initialized!");
    }

    if (p[@"tcap-handshake"])
    {
        if([p[@"tcap-handshake"] boolValue])
        {
            options[@"tcap-handshake"] = @(YES);
        }
    }
    if (p[@"sccp-xudt"])
    {
        if([p[@"sccp-xudt"] boolValue])
        {
            options[@"sccp-xudt"] = @(YES);
        }
    }
    if (p[@"sccp-segment"])
    {
        if([p[@"sccp-segment"] boolValue])
        {
            options[@"sccp-segment"] = @(YES);
        }
    }
    if (p[@"sccp-debug"])
    {
        options[@"sccp-debug"] = @([p[@"sccp-debug"] boolValue]);
    }
    if (p[@"sccp-trace"])
    {
        options[@"sccp-trace"] = @([p[@"sccp-trace"] boolValue]);
    }

    if (p[@"invoke-count"])
    {
        int i = [p[@"invoke-count"] intValue];
        options[@"invoke-count"] = @(i);
    }

    if(_opc)
    {
        options[@"opc"] = _opc;
    }

    if(_dpc)
    {
        options[@"dpc"] = _dpc;
    }

    if (p[@"output-format"])
    {
        NSString *s = [p[@"output-format"] stringValue];
        if([s isEqualToString:@"json"])
        {
            outputFormat = OutputFormat_json;
        }
        else if([s isEqualToString:@"dict"])
        {
            outputFormat = OutputFormat_dict;
        }
        else if([s isEqualToString:@"none"])
        {
            outputFormat = OutputFormat_none;
        }
        else if([s isEqualToString:@"xml"])
        {
            outputFormat = OutputFormat_xml;
        }
        else if([s isEqualToString:@"rest"])
        {
            outputFormat = OutputFormat_rest;
        }
    }

    if(p[@"nowait"]!=NULL)
    {
        nowait = [p[@"nowait"] intValue];
    }
}

- (void)submit
{
    if(nowait)
    {
        [req setResponsePlainText:@"Sent"];
        [req resumePendingRequest];
    }
    else
    {
        [req makeAsyncWithTimeout:timeoutValue];
    }
    if(_opc)
    {
        options[@"opc"] = _opc;
    }
    if(_dpc)
    {
        options[@"dpc"] = _dpc;
    }
    dialogId =  [gInstance.gsmMap MAP_Open_Req_forUser:self
                                               variant:TCAP_VARIANT_DEFAULT
                                        callingAddress:localAddress
                                         calledAddress:remoteAddress
                                    applicationContext:applicationContext
                                              userInfo:userInfo
                                        userIdentifier:userIdentifier
                                               options:options];
    [gInstance addTransaction:self userId:userIdentifier];
    if([options[@"tcap-handshake"] boolValue])
    {
        [gInstance.gsmMap MAP_Delimiter_Req:dialogId
                                    options:options];
        [gInstance.gsmMap MAP_Invoke_Req:query
                                  dialog:dialogId
                                invokeId:AUTO_ASSIGN_INVOKE_ID
                                linkedId:TCAP_UNDEFINED_LINKED_ID
                                  opCode:opcode
                                    last:YES
                                 options:options];

    }
    else
    {
        [gInstance.gsmMap MAP_Invoke_Req:query
                                  dialog:dialogId
                                invokeId:AUTO_ASSIGN_INVOKE_ID
                                linkedId:TCAP_UNDEFINED_LINKED_ID
                                  opCode:opcode
                                    last:YES
                                 options:options];
        [gInstance.gsmMap MAP_Delimiter_Req:dialogId
                                    options:options];
    }
}

- (void)submitApplicationContextTest
{
    if(nowait)
    {
        [req setResponsePlainText:@"Sent"];
        [req resumePendingRequest];
    }
    else
    {
        [req makeAsyncWithTimeout:timeoutValue];
    }
    if(options==NULL)
    {

    }
    dialogId =  [gInstance.gsmMap MAP_Open_Req_forUser:self
                                               variant:TCAP_VARIANT_DEFAULT
                                        callingAddress:localAddress
                                         calledAddress:remoteAddress
                                    applicationContext:applicationContext
                                              userInfo:userInfo
                                        userIdentifier:userIdentifier
                                               options:options];
    [gInstance addTransaction:self userId:userIdentifier];

    [gInstance.gsmMap MAP_Delimiter_Req:dialogId
                                options:options];
}

- (void)webException:(NSException *)e
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
    NSString *errString = [d jsonString];
    [gInstance logMinorError:errString];
    [req setResponsePlainText:errString];
    [req resumePendingRequest];
}

- (NSString *)description
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"GenericTransaction [%p]:\n",self];
    [s appendFormat:@"{\n"];
    [s appendFormat:@"\ttransactionName: %@\n",transactionName];
    [s appendFormat:@"\tuserIdentifier: %@\n",userIdentifier];
    [s appendFormat:@"\tdialogId: %@\n",dialogId];
    [s appendFormat:@"\ttransactionId: %@\n",transactionId];
    [s appendFormat:@"\tremoteTransactionId: %@\n",remoteTransactionId];
    [s appendFormat:@"\tgInstance: '%@'\n",gInstance.layerName];
    [s appendFormat:@"\topcode %d\n",(int)opcode.operation];
    [s appendFormat:@"\tlocalAddress %@\n",localAddress.description];
    [s appendFormat:@"\tremoteAddress %@\n",remoteAddress.description];
    [s appendFormat:@"\thttp request %p\n",req];
    [s appendFormat:@"\tundefinedTransaction %@\n",undefinedTransaction ? @"YES" : @"NO"];
    [s appendFormat:@"}\n"];
    return s;
}


- (void)logWebtransaction
{
    if(gInstance.logLevel <= UMLOG_DEBUG)
    {
        NSString *s = [NSString stringWithFormat:@"%@: %@",transactionName,req.params ];
        [gInstance logDebug:s];
    }
}

+ (void)webFormStart:(NSMutableString *)s title:(NSString *)t
{
    [GenericInstance webHeader:s title:t];
    [s appendString:@"\n"];
    [s appendString:@"<a href=\"index.php\">menu</a>\n"];
    [s appendFormat:@"<h2>%@</h2>\n",t];
    [s appendString:@"<form method=\"get\">\n"];
    [s appendString:@"<table>\n"];

}

+ (void)webFormEnd:(NSMutableString *)s
{
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td>&nbsp</td>\n"];
    [s appendString:@"    <td><input type=submit></td>\n"];
    [s appendString:@"</tr>\n"];
    [s appendString:@"</table>\n"];
    [s appendString:@"</form>\n"];
    [s appendString:@"</body>\n"];
    [s appendString:@"</html>\n"];
    [s appendString:@"\n"];
}

+ (void)webMapTitle:(NSMutableString *)s
{
    [s appendString:@"<tr><td colspan=2 class=subtitle>GSMMAP Parameters:</td></tr>\n"];
}

+ (void)webDialogTitle:(NSMutableString *)s
{
    [s appendString:@"<tr><td colspan=2 class=subtitle>Dialogue Parameters:</td></tr>\n"];
}

+ (void)webDialogOptions:(NSMutableString *)s
{
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>map-open-destination-msisdn</td>\n"];
    [s appendString:@"    <td class=optional><input name=\"map-open-destination-msisdn\" type=text placeholder=\"+12345678\"> msisdn in map-open destination reference</td>\n"];
    [s appendString:@"</tr>\n"];
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>map-open-destination-imsi</td>\n"];
    [s appendString:@"    <td class=optional><input name=\"map-open-destination-imsi\" type=text> imsi in map-open destination reference</td>\n"];
    [s appendString:@"</tr>\n"];
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>map-open-origination-msisdn</td>\n"];
    [s appendString:@"    <td class=optional><input name=\"map-open-origination-msisdn\" type=text placeholder=\"+12345678\"> msisdn in map-open origination reference</td>\n"];
    [s appendString:@"</tr>\n"];
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>map-open-origination-imsi</td>\n"];
    [s appendString:@"    <td class=optional><input name=\"map-open-origination-imsi\" type=text> imsi in map-open origination reference</td>\n"];
    [s appendString:@"</tr>\n"];
}

+ (void)webTcapTitle:(NSMutableString *)s
{
    [s appendString:@"<tr><td colspan=2 class=subtitle>TCAP Parameters:</td></tr>\n"];
}

+ (void)webTcapOptions:(NSMutableString *)s
            appContext:(NSString *)ac
        appContextName:(NSString *)acn
{
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>tcap-handshake</td>\n"];
    [s appendString:@"    <td class=optional><input name=\"tcap-handshake\" type=\"text\" value=\"0\"> 0 |&nbsp;1</td>\n"];
    [s appendString:@"</tr>\n"];
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>timeout</td>\n"];
    [s appendString:@"    <td class=optional><input name=\"timeout\" type=\"text\" value=\"30\"> timeout in seconds</td>\n"];
    [s appendString:@"</tr>\n"];
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>application-context</td>\n"];
    [s appendFormat:@"    <td class=optional><input name=\"application-context\" type=\"text\" value=\"%@\"> %@</td>\n",ac,acn];
    [s appendString:@"</tr>\n"];
}

+ (void)webSccpTitle:(NSMutableString *)s
{
    [s appendString:@"<tr><td colspan=2 class=subtitle>SCCP Parameters:</td></tr>\n"];
}

+ (void)webSccpOptions:(NSMutableString *)s
        callingComment:(NSString *)callingComment
         calledComment:(NSString *)calledComment
            callingSSN:(NSString *)callingSSN
             calledSSN:(NSString *)calledSSN
{
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>calling-address</td>\n"];
    [s appendFormat:@"    <td class=optional><input name=\"calling-address\" type=\"text\" placeholder=\"+12345678\" value=\"default\"> %@</td>\n",callingComment];
    [s appendString:@"</tr>\n"];
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>called-address</td>\n"];
    [s appendFormat:@"    <td class=optional><input name=\"called-address\" type=\"text\" placeholder=\"+12345678\" value=\"default\"> %@</td>\n",calledComment];
    [s appendString:@"</tr>\n"];
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>calling-ssn</td>\n"];
    [s appendFormat:@"    <td class=optional><input name=\"calling-ssn\" type=\"text\" value=\"%@\"></td>\n",callingSSN];
    [s appendString:@"</tr>\n"];
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>called-ssn</td>\n"];
    [s appendFormat:@"    <td class=optional><input name=\"called-ssn\" type=\"text\" value=\"%@\"></td>\n",calledSSN];
    [s appendString:@"</tr>\n"];
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>calling-tt</td>\n"];
    [s appendString:@"    <td class=optional><input name=\"calling-tt\" type=\"text\" value=\"0\"></td>\n"];
    [s appendString:@"</tr>\n"];
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>called-tt</td>\n"];
    [s appendString:@"    <td class=optional><input name=\"called-tt\" type=\"text\" value=\"0\"></td>\n"];
    [s appendString:@"</tr>\n"];
    [s appendString:@"<tr><td colspan=2 class=subtitle>SCCP Debugging</td></tr><tr>\n"];
    [s appendString:@"	<td class=optional>sccp-debug</td>\n"];
    [s appendString:@"	<td class=optional><input name=\"sccp-debug\" value=0></td>\n"];
    [s appendString:@"</tr>\n"];
    [s appendString:@"<tr>\n"];
    [s appendString:@"	<td class=optional>sccp-trace</td>\n"];
    [s appendString:@"	<td class=optional><input name=\"sccp-trace\" value=0></td>\n"];
    [s appendString:@"</tr>\n"];
}

+ (void)webMtp3Title:(NSMutableString *)s
{
    [s appendString:@"<tr><td colspan=2 class=subtitle>MTP3 Parameters:</td></tr>\n"];
}

+ (void)webMtp3Options:(NSMutableString *)s
{
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>opc</td>\n"];
    [s appendFormat:@"    <td class=optional><input name=\"opc\" type=\"text\" placeholder=\"0-000-0\" value=\"default\">originating pointcode</td>\n"];
    [s appendString:@"</tr>\n"];
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>dpc</td>\n"];
    [s appendFormat:@"    <td class=optional><input name=\"dpc\" type=\"text\" placeholder=\"0-000-0\" value=\"default\">destination pointcode</td>\n"];
    [s appendString:@"</tr>\n"];
}


@end

