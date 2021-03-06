//
//  TagViewController.m
//  OpenPhoto
//
//  Created by Patrick Santana on 11/08/11.
//  Copyright 2011 OpenPhoto. All rights reserved.
//
#import "TagViewController.h"


@implementation TagViewController

@synthesize tags, service;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
        self.tableView.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"BackgroundUpload.png"]];
        
        // create the service
        self.service = [[WebService alloc]init];
        [service setDelegate:self];
        
        
        // initialize the object tags
        self.tags = [[NSMutableArray alloc]init];    
        
        readOnly = NO;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void) dealloc{
    [tags release];
    [service release];
    [super dealloc];
}
- (void) setReadOnly{
    readOnly = YES;
}

// this method return only the tag's name.
- (NSArray*) getSelectedTags{
    NSMutableArray *array = [NSMutableArray array];
    
    for (id object in self.tags) {
        Tag *tag = (Tag*) object;
        if (tag.selected == YES){
            [array addObject:tag.tagName];  
        }
    }
    
    return array;
}

// this method return the tag's name but in the format to send to openphoto server
- (NSString *) getSelectedTagsInJsonFormat{  
    NSMutableString *result = [NSMutableString string];
    
    NSArray *array = [self getSelectedTags];
    int counter = 1;
    
    if (array != nil && [array count]>0){
        for (id string in array) {
            [result appendFormat:@"%@",string];
            
            // add the ,
            if ( counter < [array count]){
                [result appendFormat:@", "];
            }
            
            counter++;
        }
    }
    
    return result;
}

#pragma mark - View lifecycle
-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    // wanna add new tag name
    if (readOnly == YES){
        UIBarButtonItem *addNewTagButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewTag)];          
        self.navigationItem.rightBarButtonItem = addNewTagButton;
        [addNewTagButton release];
    }
    
    // load all tags
    [service getTags];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // set the tile of the table
    self.title=@"Tags";     
}

-(void) addNewTag{
    NSLog(@"Add new tag");
    TSAlertView* av = [[TSAlertView alloc] initWithTitle:@"Enter new tag name" message:nil delegate:self
                                       cancelButtonTitle:@"Cancel"
                                       otherButtonTitles:@"OK",nil];
    av.style = TSAlertViewStyleInput;
    [av show];
    [av release];
}

// after animation
- (void) alertView: (TSAlertView *) alertView didDismissWithButtonIndex: (NSInteger) buttonIndex{
    // cancel
    if( buttonIndex == 0 || alertView.inputTextField.text == nil || alertView.inputTextField.text.length==0)
        return;
    
    // add the new tag in the list and select it
    Tag *newTag = [[Tag alloc]initWithTagName:alertView.inputTextField.text Quantity:0];
    newTag.selected = YES;
    [tags addObject:newTag];
    
    // we don't need it anymore.
    [newTag release];
    [self.tableView reloadData];
}

#pragma mark - Delegate for bring the tags from the server
- (void) receivedResponse:(NSDictionary*) response{
    // check if message is valid
    if (![WebService isMessageValid:response]){
        NSString* message = [WebService getResponseMessage:response];
        NSLog(@"Invalid response = %@",message);
        
        // show alert to user
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Response Error" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        [alert release];
        
        return;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSArray *tagsResult = [response objectForKey:@"result"];
    [tags removeAllObjects];
    if ([tagsResult class] != [NSNull class]) {
        // Loop through each entry in the dictionary and create an array Tags
        for (NSDictionary *tagDetails in tagsResult){
            // tag name       
            NSString *name = [tagDetails objectForKey:@"id"];
            name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            // how many images
            NSString *qtd = [tagDetails objectForKey:@"count"];
            
            // create a tag and add to the list
            Tag *tag = [[Tag alloc]initWithTagName:name Quantity:[qtd integerValue]];
            [tags addObject:tag];
            
            // we don't need it anymore.
            [tag release];
        }}
    
    [self.tableView reloadData];
    
#ifdef TEST_FLIGHT_ENABLED
    [TestFlight passCheckpoint:@"Tags received from the website"];
#endif
    
}

- (void) notifyUserNoInternet{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    // problem with internet, show message to user
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Internet error" message:@"Couldn't reach the server. Please, check your internet connection" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
    [alert release];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return tags.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
    NSUInteger row = [indexPath row];
    
    Tag *tag = [tags objectAtIndex:row];
    cell.textLabel.text=tag.tagName;
    if (readOnly == NO){
        cell.detailTextLabel.text=[NSString stringWithFormat:@"%d", tag.quantity];
    }else{
        // check if it selected or not
        if(tag.selected == YES){
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // get the tag
    NSUInteger row = [indexPath row];
    Tag *tag = [tags objectAtIndex:row];
    
    if (tag.quantity >0 && readOnly == NO){
        // open the gallery with a tag that contains at least one picture.
        GalleryViewController *galleryController = [[GalleryViewController alloc]initWithTagName:tag.tagName];
        [self.navigationController pushViewController:galleryController animated:YES];
        [galleryController release];
    }
    
    if (readOnly == YES){
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        NSUInteger row = [indexPath row];
        Tag *tag = [tags objectAtIndex:row];
        
        if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            tag.selected = NO;
        } else {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            tag.selected = YES;
        }
    }
}

@end
