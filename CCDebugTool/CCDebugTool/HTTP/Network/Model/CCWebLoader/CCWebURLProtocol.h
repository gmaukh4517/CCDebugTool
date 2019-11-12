//
//  CCWebURLProtocol.h
//  CCDebugTool
//
//  Created by CC on 2019/10/23.
//  Copyright © 2019 CC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCWebURLProtocol : NSURLProtocol

@end

@interface CCWebURLProtocol (WKCustomProtocol)

@property (class, nonatomic) BOOL enableWKCustomProtocol;

@end
