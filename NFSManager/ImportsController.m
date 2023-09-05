//
//  ImportsController.m
//  NFSManager
//
//  Created by Gregory John Casamento on 9/2/23.
//

#import "ImportsController.h"

@implementation ImportsController

- (instancetype) init
{
    if ((self = [super init]) != nil)
    {
        _nfsImportsConfig = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc
{
#ifdef GNUSTEP
    RELEASE(_nfsImportsConfig);
    [super dealloc];
#endif
}

// Imports portion of the delegate

- (IBAction) add: (id)sender
{
    [self.importFromServerWindow makeKeyAndOrderFront: sender];
}

- (IBAction) remove: (id)sender
{

}

// Imports Delegate/DataSource

- (IBAction)selectRetryMethod:(id)sender
{
    
}

- (IBAction)selectSetuidAction:(id)sender
{
    
}

- (IBAction)selectMountThread:(id)sender
{
    
}

- (IBAction)selectMountPermissions:(id)sender
{
    
}

- (IBAction)select:(id)sender
{
    
}

// Expert options

- (IBAction) setExpertOptions: (id)sender
{
    
}

- (IBAction) cancelExpertOptions: (id)sender
{
    
}

// Imports from NFS window

- (IBAction)okImport:(id)sender
{
    
}

- (IBAction)cancelImport:(id)sender
{
    
}

// Table Delegate

// Table Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_nfsImportsConfig count];
}

@end
