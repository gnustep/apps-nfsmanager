//
//  ImportsController.m
//  NFSManager
//
//  Created by Gregory John Casamento on 9/2/23.
//

#import <AppKit/NSTableColumn.h>

#import "ImportsController.h"

@implementation ImportsController

- (instancetype) init
{
    if ((self = [super init]) != nil)
    {
        _nfsImportsConfig = [self loadFstabIntoDictionary];
        _columnsArray = [NSArray arrayWithObjects: @"fs_spec",@"fs_file",@"fs_vfstype",
                         @"fs_mntops",@"fs_type",@"fs_freq",nil];
        NSLog(@"fstab = %@", _nfsImportsConfig);
    }
    return self;
}

- (void) dealloc
{
#ifdef GNUSTEP
    RELEASE(_nfsImportsConfig);
    RELEASE(_columnsArray);
    [super dealloc];
#endif
}

- (void) setupTableColumns
{
    NSEnumerator *en = [_columnsArray objectEnumerator];
    NSString *colName = nil;
    
    while(colName = [en nextObject])
    {
        NSTableColumn *tc = [[NSTableColumn alloc] initWithIdentifier: colName];
        
        [tc setTitle: colName];
        [self.table addTableColumn: tc];
    }
}

- (void) awakeFromNib
{
    [self setupTableColumns];
}

// Load
- (NSMutableArray *) loadFstabIntoDictionary
{
    NSMutableArray *fstabArray = [[NSMutableArray alloc] init];
    NSString *filePath = @"/etc/fstab";
    NSError *error = nil;
    NSString *fileContents = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    NSArray *lines = [fileContents componentsSeparatedByString:@"\n"];
    unsigned int i;
    
    if (error != nil)
    {
        NSLog(@"Error reading fstab: %@", [error localizedDescription]);
        return fstabArray;
    }
    
#ifndef GNUSTEP // Apple...
    for (i = 0; i < [lines count]; i++) {
        NSString *line = [lines objectAtIndex:i];
        
        // Ignore comments and empty lines
        if ([line length] == 0 || [line hasPrefix:@"#"]) {
            continue;
        }
        
        NSArray *components = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        components = [components filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        
        if ([components count] < 6) {
            continue;
        }
        
        NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
            [components objectAtIndex:0], @"fs_spec",
            [components objectAtIndex:1], @"fs_file",
            [components objectAtIndex:2], @"fs_vfstype",
            [components objectAtIndex:3], @"fs_mntops",
            [components objectAtIndex:4], @"fs_type",
            [components objectAtIndex:5], @"fs_freq",
            ([components count] > 6 ? [components objectAtIndex:6] : @"0"), @"fs_passno",
            nil
        ];
        
        [fstabArray addObject:entry];
    }
#elif defined(GNUSTEP)
    for (i = 0; i < [lines count]; i++) {
        NSString *line = [lines objectAtIndex:i];
        
        // Ignore comments and empty lines
        if ([line length] == 0 || [line hasPrefix:@"#"]) {
            continue;
        }
        
        NSArray *components = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        components = [components filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        
        if ([components count] < 6) {
            continue;
        }
        
        NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
            [components objectAtIndex:0], @"fs_spec",
            [components objectAtIndex:1], @"fs_file",
            [components objectAtIndex:2], @"fs_vfstype",
            [components objectAtIndex:3], @"fs_mntops",
            [components objectAtIndex:4], @"fs_dump",
            [components objectAtIndex:5], @"fs_passno",
            nil
        ];
        
        [fstabArray addObject:entry];
    }
#endif
    
    return fstabArray;
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

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *ident = [tableColumn identifier];
    NSDictionary *dict = [_nfsImportsConfig objectAtIndex: row];
    NSString *value = [dict objectForKey: ident];
    return value;
}
@end
