//
//  LibraryViewController.m
//  eBookReader
//
//  Created by Andreea Danielescu on 1/23/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "LibraryViewController.h"
#import "BookCell.h"
#import "Book.h"

#import "BookViewController.h"

@interface LibraryViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) IBOutlet UICollectionView *libraryView;
@property (strong, nonatomic) IBOutlet UILabel *libraryLabel;

@property (nonatomic, strong) NSArray *libraryImages;
@property (nonatomic, strong) NSArray *libraryTitles;
@property (nonatomic, strong) NSArray *hasCoverImage;

@property (nonatomic, strong) EBookImporter *bookImporter;

@property (nonatomic, strong) NSMutableArray *books;

@property (nonatomic, strong) NSString* bookToOpen;

@end

@implementation LibraryViewController

@synthesize bookImporter;
@synthesize books;


- (void)viewDidLoad
{
    [super viewDidLoad];
    //copy the default ebook in to the document folder
    
    //initialize and book importer.
    self.bookImporter = [[EBookImporter alloc] init];
    
    //find the documents directory and start reading book.
    self.books = [bookImporter importLibrary];
    
    NSLog(@"imported all books");
    
    //set the background color to something that looks like a library.
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationPortrait ||orientation== UIInterfaceOrientationPortraitUpsideDown){
         self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bookshelf_vertical"]];
    }else{
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bookshelf_horizontal"]];
    }
    //Setup the collection view information
    NSMutableArray *firstSection = [[NSMutableArray alloc] init];
    NSMutableArray *secondSection = [[NSMutableArray alloc] init];
    NSMutableArray *hasImageSection = [[NSMutableArray alloc] init];
    //self.books = [bookImporter library];
    
    for (Book *book in books) {
        //get the title and author of the book to be displayed to the user.
        NSString *bookLabel = [[book title] stringByAppendingString:@" - "];
        bookLabel = [bookLabel stringByAppendingString:[book author]];
        
        NSString* coverImagePath = [book coverImagePath];
        UIImage *bookCover;
        NSString *hasCover = [[NSString alloc] init];
        //Create an book cover image that displays the title and author in case book has no book cover.
        if(coverImagePath == nil) {
            bookCover=[[UIImage alloc] init];
            bookCover= [UIImage imageNamed:@"cover_default"];
            hasCover=@"No";
                }
        //set the hasCover value to indicate if the book has a cover or not.
        else {
            bookCover = [[UIImage alloc] initWithContentsOfFile:[book coverImagePath]];
            hasCover=@"Yes";
        }
        [firstSection addObject:bookLabel];
        [secondSection addObject:bookCover];
        [hasImageSection addObject:hasCover];
    }
    
    self.libraryImages = [[NSArray alloc] initWithObjects:secondSection, nil];
    self.libraryTitles = [[NSArray alloc] initWithObjects:firstSection, nil];
    self.hasCoverImage = [[NSArray alloc] initWithObjects:hasImageSection, nil];
    
    
    //Use BookCell for the cells.
    [self.libraryView registerClass:[BookCell class] forCellWithReuseIdentifier:@"bookCell"];
    
    // Configure layout
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(120, 148)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.libraryView setCollectionViewLayout:flowLayout];
}

//change the background image when rotating the screen
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if(fromInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||fromInterfaceOrientation== UIInterfaceOrientationLandscapeRight)
        
    {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bookshelf_vertical"]];
    }else{
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bookshelf_horizontal"]];
    }
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if(toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||toInterfaceOrientation== UIInterfaceOrientationLandscapeRight)
    {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bookshelf_horizontal"]];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    // Dispose of any resources that can be recreated.
    self.libraryView = nil;
    self.libraryImages = nil;
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UILabel *titleText = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, 0, 20)];
    titleText.backgroundColor = [UIColor clearColor];
    [titleText setFont:[UIFont systemFontOfSize:16.0]];
    [titleText setText:@"Library"];
    self.navigationItem.titleView=titleText;
    UINavigationBar *navBar = self.navigationController.navigationBar;
   [navBar setBarStyle: UIBarStyleDefault];
   [navBar setBackgroundImage:[UIImage imageNamed:@"navigation_bar.png"] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.translucent = NO;
    
}

//Segue prep to go from LibraryViewController to BookView Controller. 
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"in preparing for segue");
     if ([segue.identifier isEqualToString:@"OpenBookSegue"]) {
    BookViewController *destination = [segue destinationViewController];
    
    destination.bookImporter = bookImporter;
    destination.bookTitle = self.bookToOpen;
    
    [destination createContentPages]; //create page content
    [destination initialPageView];    //initial page view
     }
}

#pragma mark - UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)libraryView {
    //this should be changed in the event that we end up having multiple sections.
    //Right now I'm assuming all books are in the same section.
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)libraryView numberOfItemsInSection:(NSInteger)section {
    
    NSMutableArray *sectionArray = [self.libraryImages objectAtIndex:section];
    return [sectionArray count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)libraryView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // Setup cell identifier
    static NSString *cellIdentifier = @"bookCell";
    
    /* Uncomment this block to use subclass-based cells */
    BookCell *cell = (BookCell *)[libraryView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    NSMutableArray *images = [self.libraryImages objectAtIndex:indexPath.section];
    UIImage *image = [images objectAtIndex:indexPath.row];
    [cell.coverImage setImage:image];

    NSMutableArray *titles = [self.libraryTitles objectAtIndex:indexPath.section];
    NSString *title = [titles objectAtIndex:indexPath.row];
    
    //check if the book has a cover, if not, use the default cover image and display the title
    NSMutableArray *hasCovers=[self.hasCoverImage objectAtIndex:indexPath.section];
    NSString *hasCover= [hasCovers objectAtIndex:indexPath.row];
    //here we only shows the title
    NSArray *listItems = [title componentsSeparatedByString:@"-"];
    if([hasCover isEqualToString:@"No"]){
        //the first item is the book title
        [cell.defaultTitle setText:listItems[0]];
        //second item is the book author
        [cell.defaultAuthor setText:listItems[1]];
    }
    
    
  //  [cell.coverTitle setText:title];  //hide the title
    /* end of subclass-based cells block */
    
    // Return the cell
    return cell;
    
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)libraryView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *titles = [self.libraryTitles objectAtIndex:indexPath.section];
    NSString *title = [titles objectAtIndex:indexPath.row];

    // TODO: Select Item
    self.bookToOpen = title;
    //[bookImporter importEBook:title];
    //Need to send notification to root view controller which should send a notification to bookview controller to
    //become visible and load that book.
    [self performSegueWithIdentifier: @"OpenBookSegue" sender:self];
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Deselect item
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(-6, 16, 15, 16);
}
@end
