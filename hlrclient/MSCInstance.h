//
//  MSCInstance.h
//  hlrclient
//
//  Created by Andreas Fink on 10.05.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "GenericInstance.h"

@interface MSCInstance : GenericInstance
{
    UMHTTPClient *webClient;
}
@end
