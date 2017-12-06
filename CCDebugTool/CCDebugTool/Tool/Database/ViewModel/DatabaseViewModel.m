//
//  DatabaseViewModel.m
//  CCDebugTool
//
//  Created by CC on 2017/12/6.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "DatabaseViewModel.h"
#import "DatabaseManager.h"

@implementation DatabaseViewModel

- (NSArray *)obtainAllDatabase
{
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSArray *databaseDirectorys = @[ documents, resourcePath ];

    NSMutableArray *databaseArray = [NSMutableArray array];
    for (NSString *directory in databaseDirectorys) {
        NSArray *dirList = [[[NSFileManager defaultManager] subpathsAtPath:directory] pathsMatchingExtensions:@[ @"sqlite", @"SQLITE", @"db", @"DB" ]];
        for (int i = 0; i < dirList.count; i++) {
            NSString *suffix = [dirList[ i ] lastPathComponent];
            [databaseArray addObject:@{ @"name" : suffix,
                                        @"path" : [directory stringByAppendingPathComponent:suffix] }];
        }

        if ([directory hasSuffix:@"sqlite"] || [directory hasSuffix:@"SQLITE"] ||
            [directory hasSuffix:@"db"] || [directory hasSuffix:@"DB"]) {
            [databaseArray addObject:@{ @"name" : directory.lastPathComponent,
                                        @"path" : directory }];
        }
    }
    return databaseArray;
}

- (NSArray *)obtainAllTable:(NSString *)databasePath
{
    [[DatabaseManager sharedManager] openDatabase:databasePath];
    NSArray *tableArr = [[DatabaseManager sharedManager] allTables];
    return tableArr ?: @[];
}

- (NSDictionary *)obtainAllColumnNameData:(NSString *)tableName
{
    if (![DatabaseManager sharedManager].db) {
        return @{};
    }

    NSString *sql = [NSString stringWithFormat:@"select * from %@", tableName];
    NSArray *columnArr = [[DatabaseManager sharedManager] infoForTable:tableName];
    NSArray *dataArr = [[DatabaseManager sharedManager] getTableData:nil sql:sql tableName:tableName];
    
    return @{ @"columnArr" : columnArr,
              @"dataArr" : dataArr };
}

@end
