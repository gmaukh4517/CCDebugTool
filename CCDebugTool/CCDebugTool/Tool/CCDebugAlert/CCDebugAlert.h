//
//  CCDebugAlert.h
//  CCDebugTool
//
//  Created by CC on 2019/9/12.
//  Copyright © 2019 CC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CCDebugAlert, CCDebugAlertAction;

typedef void (^CCDebugAlertReveal)();
typedef void (^CCDebugAlertBuilder)(CCDebugAlert *make);
typedef CCDebugAlert *(^CCDebugAlertStringProperty)(NSString *);
typedef CCDebugAlert *(^CCDebugAlertStringArg)(NSString *);
typedef CCDebugAlert *(^CCDebugAlertTextField)(void(^configurationHandler)(UITextField *textField));
typedef CCDebugAlertAction *(^CCDebugAlertAddAction)(NSString *title);
typedef CCDebugAlertAction *(^CCDebugAlertActionStringProperty)(NSString *);
typedef CCDebugAlertAction *(^CCDebugAlertActionProperty)();
typedef CCDebugAlertAction *(^CCDebugAlertActionBOOLProperty)(BOOL);
typedef CCDebugAlertAction *(^CCDebugAlertActionHandler)(void(^handler)(NSArray<NSString *> *strings));

@interface CCDebugAlert : NSObject

/// Shows a simple alert with one button which says "Dismiss"
+ (void)showAlert:(NSString *)title message:(NSString *)message from:(UIViewController *)viewController;

/// Construct and display an alert
+ (void)makeAlert:(CCDebugAlertBuilder)block showFrom:(UIViewController *)viewController;
/// Construct and display an action sheet-style alert
+ (void)makeSheet:(CCDebugAlertBuilder)block showFrom:(UIViewController *)viewController;

/// Construct an alert
+ (UIAlertController *)makeAlert:(CCDebugAlertBuilder)block;
/// Construct an action sheet-style alert
+ (UIAlertController *)makeSheet:(CCDebugAlertBuilder)block;

/// Set the alert's title.
///
/// Call in succession to append strings to the title.
@property (nonatomic, readonly) CCDebugAlertStringProperty title;
/// Set the alert's message.
///
/// Call in succession to append strings to the message.
@property (nonatomic, readonly) CCDebugAlertStringProperty message;
/// Add a button with a given title with the default style and no action.
@property (nonatomic, readonly) CCDebugAlertAddAction button;
/// Add a text field with the given (optional) placeholder text.
@property (nonatomic, readonly) CCDebugAlertStringArg textField;
/// Add and configure the given text field.
///
/// Use this if you need to more than set the placeholder, such as
/// supply a delegate, make it secure entry, or change other attributes.
@property (nonatomic, readonly) CCDebugAlertTextField configuredTextField;

@end

@interface CCDebugAlertAction : NSObject

/// Set the action's title.
///
/// Call in succession to append strings to the title.
@property (nonatomic, readonly) CCDebugAlertActionStringProperty title;
/// Make the action destructive. It appears with red text.
@property (nonatomic, readonly) CCDebugAlertActionProperty destructiveStyle;
/// Make the action cancel-style. It appears with a bolder font.
@property (nonatomic, readonly) CCDebugAlertActionProperty cancelStyle;
/// Enable or disable the action. Enabled by default.
@property (nonatomic, readonly) CCDebugAlertActionBOOLProperty enabled;
/// Give the button an action. The action takes an array of text field strings.
@property (nonatomic, readonly) CCDebugAlertActionHandler handler;
/// Access the underlying UIAlertAction, should you need to change it while
/// the encompassing alert is being displayed. For example, you may want to
/// enable or disable a button based on the input of some text fields in the alert.
/// Do not call this more than once per instance.
@property (nonatomic, readonly) UIAlertAction *action;

@end
