//
//  ImportsController.m
//  NFSManager
//
//  Created by Gregory John Casamento on 9/2/23.
//

#import <Foundation/Foundation.h>
#import <AppKit/NSTableColumn.h>

#import "ImportsController.h"

@implementation ImportsController

- (instancetype) init
{
    if ((self = [super init]) != nil)
    {
        self.nfsImportsConfig = [self loadFstabIntoDictionary];
        self.columnsArray = [NSArray arrayWithObjects: @"fs_spec",
                                @"fs_file",@"fs_vfstype",
                                @"fs_mntops",@"fs_type",
                                @"fs_freq", @"fs_passno", nil];
        self.columnNames = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Remote Directory", @"fs_spec",
                        @"Local Directory", @"fs_file",
                        @"File System Type", @"fs_vfstype",
                        @"Mount Options", @"fs_mntops",
                        @"Version", @"fs_type",
                        @"Frequency", @"fs_freq",
                        @"Pass", @"fs_passno", nil];
        NSLog(@"fstab = %@", _nfsImportsConfig);
    }
    return self;
}

- (void) removeTableColumns
{
    while ([[self.table tableColumns] count] > 0)
    {
        [self.table removeTableColumn:
         [[self.table tableColumns] objectAtIndex:0]];
    }
}

- (void) setupTableColumns
{
    NSEnumerator *en = [_columnsArray objectEnumerator];
    NSString *ident = nil;
    
    while(ident = [en nextObject])
    {
        NSTableColumn *tc = [[NSTableColumn alloc] initWithIdentifier: ident];
        NSString *colName = [_columnNames objectForKey: ident];
        
        [tc setTitle: colName];
        [self.table addTableColumn: tc];
    }
}

- (void) awakeFromNib
{
    [self removeTableColumns];
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
    unsigned int i = 0;
    
    if (error != nil)
    {
        NSLog(@"Error reading fstab: %@", [error localizedDescription]);
        return fstabArray;
    }
    
    for (i = 0; i < [lines count]; i++)
    {
        NSString *line = [lines objectAtIndex:i];
        
        // Ignore comments and empty lines
        if ([line length] == 0 || [line hasPrefix:@"#"]) {
            continue;
        }
        
        NSArray *components = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        components = [components filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        
        if ([components count] < 6)
        {
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
        
        [fstabArray addObject: entry];

        // Only add NFS to display
        if ([[components objectAtIndex: 2] isEqualToString: @"nfs"]) // fs_vfstype
        {
            [self.displayEntries addObject:entry];
        }
    }
    
    return fstabArray;
}

- (void) refreshData
{
    [self.table reloadData];
}

- (void) addEntrySpec: (NSString *)spec
                 file: (NSString *)file
              vfsType: (NSString *)vfsType
             mountOps: (NSString *)mountOps
                 type: (NSString *)type
                 freq: (NSString *)freq
               passno: (NSString *)passno
{
    NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
                               spec, @"fs_spec",
                               file, @"fs_file",
                            vfsType, @"fs_vfstype",
                           mountOps, @"fs_mntops",
                               type, @"fs_type",
                               freq, @"fs_freq",
                             passno, @"fs_passno", nil];
    [self.nfsImportsConfig addObject: entry];
}

// Imports portion of the delegate
- (IBAction) add: (id)sender
{
    [self.importFromServerWindow makeKeyAndOrderFront: self];
}

- (IBAction) remove: (id)sender
{

}

// Imports Delegate/DataSource
- (IBAction) selectRetryMethod: (id)sender
{
    
}

- (IBAction) selectSetuidAction: (id)sender
{
    
}

- (IBAction) selectMountThread: (id)sender
{
    
}

- (IBAction) selectMountPermissions: (id)sender
{
    
}

- (IBAction) select: (id)sender
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
- (IBAction) okImport:(id)sender
{
    
}

- (IBAction) cancelImport:(id)sender
{
    
}

// Table Delegate

// Table Data Source
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [self.displayEntries count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *ident = [tableColumn identifier];
    NSDictionary *dict = [self.displayEntries objectAtIndex: row];
    NSString *value = [dict objectForKey: ident];
    return value;
}


@end
