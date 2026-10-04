//
//  MSCSession_SendRoutingInfoForSM.m
//  hlrclient
//
//  Created by Andreas Fink on 03.12.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "MSCSession_SendRoutingInfoForSM.h"
#import "MSCInstance.h"

@implementation MSCSession_SendRoutingInfoForSM

-(MSCSession_SendRoutingInfoForSM *)initWithHttpReq:(UMHTTPRequest *)hreq
                                          instance:(MSCInstance *)inst
{
    self = [super initWithHttpReq:hreq
                        operation:UMGSMMAP_Opcode_sendRoutingInfoForSM
                         instance:inst];
    if(self)
    {
        _sessionName = @"SendRoutingInfoForSM";
    }
    return self;
}

- (void)main
{
    @try
    {
        NSDictionary *p = _req.params;
        NSString *_multi_invoke_variant_string;
        SET_OPTIONAL_CLEAN_PARAMETER(p,_msisdn,@"msisdn");
        SET_OPTIONAL_CLEAN_PARAMETER(p,_smsc,@"smsc");
        SET_OPTIONAL_CLEAN_PARAMETER(p,_sm_rp_pri,@"sm-rp-pri");
        SET_OPTIONAL_CLEAN_PARAMETER(p,_gprsSupportIndicator,@"gprs-suppport-indicator");
        SET_OPTIONAL_CLEAN_PARAMETER(p,_sm_rp_mti,@"sm-rp-mti");
        SET_OPTIONAL_CLEAN_PARAMETER(p,_sm_rp_smea,@"sm-rp-smea");
        if(_multi_invoke_variant_string.length > 0)
        {
            if(![_multi_invoke_variant_string isEqualTo:@"0"])
            {
                _multi_invoke_variant = [_multi_invoke_variant_string intValue];
            }
        }
        [self handleSccpAddressesDefaultCallingSsn:@"msc"
                                  defaultCalledSsn:@"hlr"
                              defaultCallingNumber:_gInstance.instanceAddress
                               defaultCalledNumber:_msisdn
                           defaultCalledNumberPlan:SCCP_NPI_ISDN_E164];
        [self setDefaultApplicationContext:UMGSMMAP_ApplicationContextString(UMGSMMAP_ApplicationContext_shortMsgGatewayContext,3)];
        UMGSMMAP_RoutingInfoForSM_Arg *param = [[UMGSMMAP_RoutingInfoForSM_Arg alloc]init];
        param.sm_RP_PRI = [[UMASN1Boolean alloc]initAsYes];
        MSCInstance *mscInstance = (MSCInstance *)_gInstance;
        if(_msisdn.length>0)
        {
            param.msisdn = [[UMGSMMAP_ISDN_AddressString alloc]initWithString:_msisdn];
        }
        if((_smsc.length == 0) || ([_smsc isEqualToString:@"default"]))
        {
            param.serviceCentreAddress = [[UMGSMMAP_ISDN_AddressString alloc]initWithString:mscInstance.instanceAddress];
        }
        else
        {
            param.serviceCentreAddress = [[UMGSMMAP_ISDN_AddressString alloc]initWithString:_smsc];
        }
        if(_sm_rp_pri.length > 0)
        {
            param.sm_RP_PRI = [[UMASN1Boolean alloc]initWithValue:[_sm_rp_pri boolValue]];
        }
        if(_gprsSupportIndicator.length > 0)
        {
            param.gprsSupportIndicator = [_gprsSupportIndicator boolValue];
        }
        if(_sm_rp_mti.length > 0)
        {
            param.sm_RP_MTI =[[UMGSMMAP_SM_RP_MTI alloc]initWithString:_sm_rp_mti];
        }

        if(_sm_rp_smea.length > 0)
        {
            param.sm_RP_SMEA =[[UMGSMMAP_SM_RP_SMEA alloc]initWithString:_sm_rp_smea];
        }
        [self setUserInfo_MAP_Open];
        self.query = param;
        [self submit];
    }
    @catch(NSException *e)
    {
        [self webException:e];
    }
}

+ (NSString *)webForm:(int)var
{
    NSMutableString *s = NULL;

    s = [[NSMutableString alloc]init];

    [SS7GenericSession webFormStart:s title:@"SendRoutingInfoForSM"];
    [SS7GenericSession webMapTitle:s];

    
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=mandatory>msisdn</td>\n"];
    [s appendString:@"    <td class=mandatory><input name=\"msisdn\" type=text placeholder=\"+12345678\"> E.164 Number</td>\n"];
    [s appendString:@"</tr>\n"];

    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>sm-rp-pri</td>\n"];
    [s appendString:@"    <td class=optional><input name=\"sm-rp-pri\" type=text placeholder=\"\" value=\"0\"></td>\n"];
    [s appendString:@"</tr>\n"];

    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>smsc</td>\n"];
    [s appendString:@"    <td class=optional><input name=\"smsc\" type=text placeholder=\"+12345678\" value=\"default\"> E.164 Number</td>\n"];
    [s appendString:@"</tr>\n"];
    
    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>smsc-b</td>\n"];
    [s appendString:@"    <td class=optional><input name=\"smsc-b\" type=text placeholder=\"+12345678\" value=\"\"> E.164 Number</td>\n"];
    [s appendString:@"</tr>\n"];


    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>gprs-suppport-indicator</td>\n"];
    [s appendString:@"    <td class=optional><input name=\"gprs-suppport-indicator\" type=text placeholder=\"0\" value=\"\">{0 | 1}</td>\n"];
    [s appendString:@"</tr>\n"];

    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>sm-rp-mti</td>\n"];
    [s appendString:@"    <td class=optional><input name=\"sm-rp-mti\" type=text placeholder=\"\" value=\"\"></td>\n"];
    [s appendString:@"</tr>\n"];

    [s appendString:@"<tr>\n"];
    [s appendString:@"    <td class=optional>sm-rp-smea</td>\n"];
    [s appendString:@"    <td class=optional><input name=\"sm-rp-smea\" type=text placeholder=\"\" value=\"\"></td>\n"];
    [s appendString:@"</tr>\n"];

    [SS7GenericSession webDialogTitle:s];
    [SS7GenericSession webDialogOptions:s];
    [SS7GenericSession webTcapTitle:s];
    [SS7GenericSession webTcapOptions:s
                            appContext:@"04000001001403"
                        appContextName:@"(shortMsgGatewayContext-v3)"];
    [SS7GenericSession webSccpTitle:s];
    [SS7GenericSession webSccpOptions:s
                        callingComment:@"msc"
                         calledComment:@"msisdn"
                            callingSSN:@"msc"
                             calledSSN:@"hlr"];
    [SS7GenericSession webMtp3Title:s];
    [SS7GenericSession webMtp3Options:s];
    

    [SS7GenericSession webFormEnd:s];
    return s;
}

/*
-(void) sessionMAP_ReturnResult_Resp:(UMASN1Object *)param
                       userId:(UMGSMMAP_UserIdentifier *)xuserIdentifier
                       dialog:(UMGSMMAP_DialogIdentifier *)xdialogId
                  transaction:(NSString *)xtcapTransactionId
                       opCode:(UMLayerGSMMAP_OpCode *)xopcode
                     invokeId:(int64_t)xinvokeId
                     linkedId:(int64_t)xlinkedId
                         last:(BOOL)xlast
                      options:(NSDictionary *)xoptions
{
    
    UMASN1Object *param1 = [self decodeComponent:param forOperation:xopcode.operation];
    [super sessionMAP_ReturnResult_Resp:param1
                          userId:xuserIdentifier
                          dialog:xdialogId
                     transaction:xtcapTransactionId
                          opCode:xopcode
                        invokeId:xinvokeId
                        linkedId:xlinkedId
                            last:xlast
                         options:xoptions];
}
*/


-(void) MAP_InsertSubscriberData:GSMMAP_INVOKE_INDICATION_PARAMETERS
{
    [self touch];
    NSLog(@"MSCSession_SendRoutingInfoForSM: MAP_InsertSubscriberData");

    UMGSMMAP_InsertSubscriberDataRes *res = [[UMGSMMAP_InsertSubscriberDataRes alloc]init];

    [_gInstance.gsmMap executeMAP_ReturnResult_Req:res
                                      dialog:xdialogId
                                    invokeId:xinvokeId
                                    linkedId:xlinkedId
                                      opCode:xopcode
                                        last:YES
                                     options:_options];

    SccpAddress *remote=NULL;
    if(_keepOriginalSccpAddressForTcapContinue)
    {
        remote = _initialRemoteAddress;
    }
    else
    {
        remote = self.remoteAddress;
    }
    [_gInstance.gsmMap executeMAP_Delimiter_Req_Prepare:xdialogId
                                         callingAddress:NULL
                                          calledAddress:remote
                                                options:xoptions
                                                 result:NULL
                                             diagnostic:NULL];
}


@end
