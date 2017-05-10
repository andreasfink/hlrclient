//
//  MSCTransaction.m
//  hlrclient
//
//  Created by Andreas Fink on 10.05.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//


#import "MSCInstance.h"
#import "MSCTransaction.h"

@implementation MSCTransaction


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
    NSLog(@"%@: MAP_Invoke_Ind  userIdentifier:%@ dialog: %@ opcode:%d",
          self.transactionName,
          xuserIdentifier,
          xdialogId,
          (int)xopcode.operation);

    self.dialogId = xdialogId;
    self.opcode = xopcode;
    self.transactionId = xtcapTransactionId;

#define VLRTRANSACTION_INVOKE_CALL_PARAMETERS \
param \
userId:userIdentifier \
dialog:xdialogId \
transaction:xtcapTransactionId \
opCode:xopcode \
invokeId:xinvokeId \
linkedId:xlinkedId \
last:xlast \
options:xoptions

    @try
    {
        switch(xopcode.operation)
        {
            case UMGSMMAP_Opcode_mt_forwardSM:
                NSLog(@"MSCInstance: calling MAP_MT_ForwardSM");
                [self MAP_MT_ForwardSM:VLRTRANSACTION_INVOKE_CALL_PARAMETERS];
                break;
            case UMGSMMAP_Opcode_mo_forwardSM:
                NSLog(@"MSCInstance: calling MAP_MO_ForwardSM");
                [self MAP_MO_ForwardSM:VLRTRANSACTION_INVOKE_CALL_PARAMETERS];
                break;
        }
    }
    @catch(NSException *e)
    {
        NSLog(@"VLR_Instance: Sending U_Abort due to exception: %@",e);
        [gInstance.gsmMap MAP_U_Abort_Req:xuserIdentifier options:options];
    }

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

- (NSString *)description
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"MSCTransaction [%p]:\n",self];
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

-(void) MAP_MT_ForwardSM:GSMMAP_INVOKE_INDICATION_PARAMETERS
{

}

-(void) MAP_MO_ForwardSM:GSMMAP_INVOKE_INDICATION_PARAMETERS
{

}
@end
