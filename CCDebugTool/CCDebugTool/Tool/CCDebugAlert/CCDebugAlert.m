//
//  CCDebugAlert.m
//  CCDebugTool
//
//  Created by CC on 2019/9/12.
//  Copyright © 2019 CC. All rights reserved.
//

#import "CCDebugAlert.h"

@interface CCDebugAlert ()

@property (nonatomic, readonly) UIAlertController *_controller;
@property (nonatomic, readonly) NSMutableArray<CCDebugAlertAction *> *_actions;

@end

#define CCDebugAlertActionMutationAssertion() \
NSAssert(!self._action, @"Cannot mutate action after retreiving underlying UIAlertAction");

@interface CCDebugAlertAction ()
@property (nonatomic) UIAlertController *_controller;
@property (nonatomic) NSString *_title;
@property (nonatomic) UIAlertActionStyle _style;
@property (nonatomic) BOOL _disable;
@property (nonatomic) void (^_handler)(UIAlertAction *action);
@property (nonatomic) UIAlertAction *_action;
@end

@implementation CCDebugAlert

+ (void)showAlert:(NSString *)title message:(NSString *)message from:(UIViewController *)viewController
{
    [self makeAlert:^(CCDebugAlert *make) {
        make.title(title).message(message).button(@"Dismiss").cancelStyle();
    }
           showFrom:viewController];
}

#pragma mark Initialization

- (instancetype)initWithController:(UIAlertController *)controller
{
    self = [super init];
    if (self) {
        __controller = controller;
        __actions = [NSMutableArray new];
    }

    return self;
}

+ (UIAlertController *)make:(CCDebugAlertBuilder)block withStyle:(UIAlertControllerStyle)style
{
    // Create alert builder
    CCDebugAlert *alert = [[self alloc] initWithController:
                           [UIAlertController alertControllerWithTitle:nil
                                                               message:nil
                                                        preferredStyle:style]];

    // Configure alert
    block(alert);

    // Add actions
    for (CCDebugAlertAction *builder in alert._actions) {
        [alert._controller addAction:builder.action];
    }

    return alert._controller;
}

+ (void)make:(CCDebugAlertBuilder)block withStyle:(UIAlertControllerStyle)style showFrom:(UIViewController *)viewController
{
    UIAlertController *alert = [self make:block withStyle:style];
    [viewController presentViewController:alert animated:YES completion:nil];
}

+ (void)makeAlert:(CCDebugAlertBuilder)block showFrom:(UIViewController *)viewController
{
    [self make:block withStyle:UIAlertControllerStyleAlert showFrom:viewController];
}

+ (void)makeSheet:(CCDebugAlertBuilder)block showFrom:(UIViewController *)viewController
{
    [self make:block withStyle:UIAlertControllerStyleActionSheet showFrom:viewController];
}

+ (UIAlertController *)makeAlert:(CCDebugAlertBuilder)block
{
    return [self make:block withStyle:UIAlertControllerStyleAlert];
}

+ (UIAlertController *)makeSheet:(CCDebugAlertBuilder)block
{
    return [self make:block withStyle:UIAlertControllerStyleActionSheet];
}

#pragma mark Configuration

- (CCDebugAlertStringProperty)title
{
    return ^CCDebugAlert *(NSString *title)
    {
        if (self._controller.title) {
            self._controller.title = [self._controller.title stringByAppendingString:title];
        } else {
            self._controller.title = title;
        }
        return self;
    };
}

- (CCDebugAlertStringProperty)message
{
    return ^CCDebugAlert *(NSString *message)
    {
        if (self._controller.message) {
            self._controller.message = [self._controller.message stringByAppendingString:message];
        } else {
            self._controller.message = message;
        }
        return self;
    };
}

- (CCDebugAlertAddAction)button
{
    return ^CCDebugAlertAction *(NSString *title)
    {
        CCDebugAlertAction *action = CCDebugAlertAction.new.title(title);
        action._controller = self._controller;
        [self._actions addObject:action];
        return action;
    };
}

- (CCDebugAlertStringArg)textField
{
    return ^CCDebugAlert *(NSString *placeholder)
    {
        [self._controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = placeholder;
        }];

        return self;
    };
}

- (CCDebugAlertTextField)configuredTextField
{
    return ^CCDebugAlert *(void (^configurationHandler)(UITextField *))
    {
        [self._controller addTextFieldWithConfigurationHandler:configurationHandler];
        return self;
    };
}

@end

@implementation CCDebugAlertAction

- (CCDebugAlertActionStringProperty)title
{
    return ^CCDebugAlertAction *(NSString *title)
    {
        CCDebugAlertActionMutationAssertion();
        if (self._title) {
            self._title = [self._title stringByAppendingString:title];
        } else {
            self._title = title;
        }
        return self;
    };
}

- (CCDebugAlertActionProperty)destructiveStyle
{
    return ^CCDebugAlertAction *()
    {
        CCDebugAlertActionMutationAssertion();
        self._style = UIAlertActionStyleDestructive;
        return self;
    };
}

- (CCDebugAlertActionProperty)cancelStyle
{
    return ^CCDebugAlertAction *()
    {
        CCDebugAlertActionMutationAssertion();
        self._style = UIAlertActionStyleCancel;
        return self;
    };
}

- (CCDebugAlertActionBOOLProperty)enabled
{
    return ^CCDebugAlertAction *(BOOL enabled)
    {
        CCDebugAlertActionMutationAssertion();
        self._disable = !enabled;
        return self;
    };
}

- (CCDebugAlertActionHandler)handler
{
    return ^CCDebugAlertAction *(void (^handler)(NSArray<NSString *> *))
    {
        CCDebugAlertActionMutationAssertion();

        // Get weak reference to the alert to avoid block <--> alert retain cycle
        __weak __typeof(self._controller) weakController = self._controller;
        self._handler = ^(UIAlertAction *action) {
            // Strongify that reference and pass the text field strings to the handler
            __strong __typeof(weakController) controller = weakController;
            NSArray *strings = [controller.textFields valueForKeyPath:@"text"];
            handler(strings);
        };

        return self;
    };
}

- (UIAlertAction *)action
{
    if (self._action) {
        return self._action;
    }

    self._action = [UIAlertAction
                    actionWithTitle:self._title
                    style:self._style
                    handler:self._handler];
    self._action.enabled = !self._disable;

    return self._action;
}

@end
