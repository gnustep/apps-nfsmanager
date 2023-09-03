//
//  ImportsController.h
//  NFSManager
//
//  Created by Gregory John Casamento on 9/2/23.
//

#import <Foundation/NSObject.h>
#import <AppKit/NSTableView.h>

NS_ASSUME_NONNULL_BEGIN

@class NSButton, NSWindow;

@interface ImportsController : NSObject <NSTableViewDelegate, NSTableViewDataSource>

@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSButton *add;
@property (strong) IBOutlet NSButton *remove;
@property (strong) IBOutlet NSTableView *table;

- (IBAction) add: (id)sender;
- (IBAction) remove: (id)sender;

@end

NS_ASSUME_NONNULL_END
