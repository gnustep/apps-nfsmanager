//
//  ExportsController.h
//  NFSManager
//
//  Created by Gregory John Casamento on 9/2/23.
//

#import <Foundation/Foundation.h>
#import <AppKit/NSTableView.h>

@class NSButton;
@class NSBrowser;
@class NSWindow;
@class NSPopUpButton;

NS_ASSUME_NONNULL_BEGIN

@interface ExportsController : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSTableView *table;
@property (strong) IBOutlet NSBrowser *readOnlyBrowser;
@property (strong) IBOutlet NSBrowser *readWriteBrowser;
@property (weak) IBOutlet NSBrowser *rootAccessBrowser;
@property (strong) IBOutlet NSButton *allowUnknownUsers;
@property (strong) IBOutlet NSPopUpButton *unknownUsersPopup;

- (IBAction)addReadOnly:(id)sender;
- (IBAction)removeReadOnly:(id)sender;
- (IBAction)removeReadWrite:(id)sender;
- (IBAction)addReadWrite:(id)sender;
- (IBAction)removeRootAccess:(id)sender;
- (IBAction)addRootAccess:(id)sender;
- (IBAction)allowUnknownUsers:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)revert:(id)sender;
@end

NS_ASSUME_NONNULL_END
