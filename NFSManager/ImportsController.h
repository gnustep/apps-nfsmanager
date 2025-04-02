//
//  ImportsController.h
//  NFSManager
//
//  Created by Gregory John Casamento on 9/2/23.
//

#import <Foundation/NSObject.h>
#import <AppKit/NSTableView.h>

NS_ASSUME_NONNULL_BEGIN

@class NSButton;
@class NSWindow;
@class NSPopUpButton;
@class NSTextField;
@class NSMutableArray;

@interface ImportsController : NSObject <NSTableViewDelegate, NSTableViewDataSource>

// Ivars...
@property (strong) NSMutableArray *nfsImportsConfig;
@property (strong) NSArray *columnsArray;
@property (strong) NSDictionary *columnNames;
@property (strong) NSMutableArray *displayEntries;

// Imports manager outlets
@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSWindow *expertOptionsWindow;
@property (strong) IBOutlet NSWindow *importFromServerWindow;
@property (strong) IBOutlet NSPopUpButton *readWritePopup;
@property (strong) IBOutlet NSPopUpButton *mountThreadPopup;
@property (strong) IBOutlet NSPopUpButton *setuidPopup;
@property (strong) IBOutlet NSPopUpButton *retryPopup;

@property (strong) IBOutlet NSButton *add;
@property (strong) IBOutlet NSButton *remove;
@property (strong) IBOutlet NSTableView *table;

// Import From NFS Server outlets
@property (strong) IBOutlet NSTextField *serverName;
@property (strong) IBOutlet NSTextField *remoteDirectory;

// Expert options outlets
@property (strong) IBOutlet NSTextField *mountTimeout;
@property (strong) IBOutlet NSTextField *mountRetries;
@property (strong) IBOutlet NSTextField *nfsTimeout;
@property (strong) IBOutlet NSTextField *nfsRetries;
@property (strong) IBOutlet NSTextField *readBufferSize;
@property (strong) IBOutlet NSTextField *writeBufferSize;
@property (strong) IBOutlet NSTextField *serverIPPort;

// Load the raw file and convert it into our data structure...
- (NSMutableArray *) loadFstabIntoDictionary;
- (void) setupTableColumns;
- (void) removeTableColumns;
- (void) refreshData;

// Imports manager
- (IBAction) add: (id)sender;
- (IBAction) remove: (id)sender;
- (IBAction) select: (id)sender;
- (IBAction) selectMountPermissions: (id)sender;
- (IBAction) selectMountThread: (id)sender;
- (IBAction) selectSetuidAction: (id)sender;
- (IBAction) selectRetryMethod: (id)sender;

// Expert options
- (IBAction) setExpertOptions: (id)sender;
- (IBAction) cancelExpertOptions: (id)sender;

// Import
- (IBAction)cancelImport:(id)sender;
- (IBAction)okImport:(id)sender;

@end

NS_ASSUME_NONNULL_END
