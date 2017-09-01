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

static NSString *const kCCDebugLogCellIdentifier = @"kCCDebugLogCellIdentifier";

@interface CCDebugDataSource ()


@end

@implementation CCDebugDataSource

- (void)refilter
{
    _dataArr = [CCDebugFluencyHelper obtainFluencyLogs];
    if (_sourceType == CCDebugDataSourceTypeCrash)
        _dataArr = [CCDebugCrashHelper obtainCrashLogs];
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
    cell.textLabel.text = [dic objectForKey:@"ErrDate"];
    cell.detailTextLabel.text = [dic objectForKey:@"ErrCause"];
    
    return cell;
}

@end
