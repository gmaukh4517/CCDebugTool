//
//  CCDebugDataSource.m
//  CCKit
//
// Copyright (c) 2015 CC ( https://github.com/gmaukh4517/CCKit )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "CCDebugDataSource.h"
#import "CCDebugCrashHelper.h"
#import "CCDebugFluencyHelper.h"
#import "CCDebugTool.h"
#import "CCLogMonitoring.h"
#import "CCWebLogMonitoring.h"

static NSString *const kCCDebugLogCellIdentifier = @"kCCDebugLogCellIdentifier";

@interface CCDebugDataSource ()


@end

@implementation CCDebugDataSource

- (void)refilter
{
    switch (_sourceType) {
        case CCDebugDataSourceTypeCrash:
            _dataArr = [CCDebugCrashHelper obtainCrashLogs];
            break;
        case CCDebugDataSourceTypeFluency:
            _dataArr = [CCDebugFluencyHelper obtainFluencyLogs];
            break;
        case CCDebugDataSourceTypeLog: {
            NSMutableArray *dataArray = [NSMutableArray arrayWithArray:[CCLogMonitoring obtainLogs]];
            [dataArray addObjectsFromArray:[CCWebLogMonitoring obtainWebLogs]];
            _dataArr = [dataArray sortedArrayWithOptions:NSSortStable
                                         usingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
                NSString *obj1FileName = [[obj1 objectForKey:@"fileName"] stringByReplacingOccurrencesOfString:@"App - " withString:@""];
                obj1FileName = [obj1FileName stringByReplacingOccurrencesOfString:@"Web - " withString:@""];

                NSString *obj2FileName = [[obj2 objectForKey:@"fileName"] stringByReplacingOccurrencesOfString:@"App - " withString:@""];
                obj2FileName = [obj2FileName stringByReplacingOccurrencesOfString:@"Web - " withString:@""];

                NSComparisonResult result = [obj1FileName localizedStandardCompare:obj2FileName];
                return result == NSOrderedAscending;
            }];
            break;
        }
        default:
            break;
    }
}

- (void)setSourceType:(CCDebugDataSourceType)sourceType
{
    BOOL sourceTypeChanged = sourceType != _sourceType;
    _sourceType = sourceType;

    if (sourceTypeChanged)
        [self refilter];
}

#pragma mark -
#pragma mark :. UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCCDebugLogCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCCDebugLogCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = [CCDebugTool manager].mainColor;
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:19];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    }

    NSDictionary *dic = [self.dataArr objectAtIndex:indexPath.row];

    NSString *title, *detail;
    if (_sourceType == CCDebugDataSourceTypeLog) {
        title = [dic objectForKey:@"fileName"];
    } else {
        title = [dic objectForKey:@"ErrDate"];
        detail = [dic objectForKey:@"ErrCause"];
    }

    cell.textLabel.text = title;
    cell.detailTextLabel.text = detail;

    return cell;
}

@end
