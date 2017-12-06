//
//  DatabaseViewModel.h
//  CCDebugTool
//
//  Created by CC on 2017/12/6.
//  Copyright © 2017年 CC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DatabaseViewModel : NSObject

- (NSArray *)obtainAllDatabase;

- (NSArray *)obtainAllTable:(NSString *)databasePath;

- (NSDictionary *)obtainAllColumnNameData:(NSString *)tableName;

@end
