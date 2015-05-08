//
//  ContentViewController.m
//  eBookReader
//
//  Created by Shang Wang on 3/19/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "ContentViewController.h"
#import "UIMenuItem+CXAImageSupport.h"
#import "OCDaysView.h"
#import "WebBrowserViewController.h"
#import "NoteViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "BookViewController.h"
#import "HighlightParser.h"
#import "HighLightWrapper.h"
#import "GDataXMLNode.h"
#import "HighLight.h"
#import "ThumbNailIcon.h"
#import "ThumbNailIconParser.h"
#import "ThumbNailIconWrapper.h"
#import "LSHorizontalScrollTabViewDemoViewController.h"
#import "SampleViewController.h"
#import "ZYQSphereView.h"
#import "AWCollectionViewDialLayout.h"
// for the "quick help" feature, we haven't decided what interaction we want to add after user clicks the button so we define this array to display some default word.
#define kStringArray [NSArray arrayWithObjects:@"YES", @"NO",@"Wiki",@"Google",@"Concept Map", nil]
#define H_CONTROL_ORIGIN CGPointMake(200, 300)
 

@interface ContentViewController ()
@end

static NSString *cellId = @"cellId";
static NSString *cellId2 = @"cellId2";

@implementation ContentViewController{
    NSMutableDictionary *thumbnailCache;
    BOOL showingSettings;
    UIView *settingsView;
    UILabel *radiusLabel;
    UISlider *radiusSlider;
    UILabel *angularSpacingLabel;
    UISlider *angularSpacingSlider;
    UILabel *xOffsetLabel;
    UISlider *xOffsetSlider;
    UISegmentedControl *exampleSwitch;
    AWCollectionViewDialLayout *dialLayout;
    
    int type;
}
@synthesize webView;
@synthesize SplitwebView;
@synthesize isMenuShow;
@synthesize pageNum;
@synthesize totalpageNum;
@synthesize parent_BookViewController;
@synthesize child_BookViewController;
@synthesize highlightTextArray;
@synthesize fliteController;
@synthesize slt;
@synthesize knowledge_module;
@synthesize thumbNailController;
@synthesize logFileController;
@synthesize bookHighLight;
@synthesize bookthumbNailIcon;
@synthesize bookTitle;
@synthesize ThumbScrollViewLeft;
@synthesize lmGenerator;
@synthesize syn;
@synthesize CmapStart;
@synthesize bulbImageView;
@synthesize conceptNamesArray;
@synthesize linkCollectionView;
@synthesize linkItems;
@synthesize isCollectionShow;
@synthesize ThumbScrollViewRight;
@synthesize isleftThumbShow;
@synthesize firstRespondConcpet;
@synthesize cmapView;
@synthesize isSplit;
@synthesize QAWebview;
@synthesize QAAskWebViewBar;
@synthesize QAAskWebview;
@synthesize SecondScreenView;
@synthesize popUpViewPanArea;
//initial methods for the open ears tts instance
- (FliteController *)fliteController { if (fliteController == nil) {
    fliteController = [[FliteController alloc] init]; }
    return fliteController;
}
//initial methods for the open ears tts instance
- (Slt *)slt {
    if (slt == nil) {
        slt = [[Slt alloc] init]; }
    return slt;
}

-(void)viewDidAppear:(BOOL)animated{
    //[super viewWillAppear:animated];
    if(cmapView.isFinishLoadMap){
        [cmapView loadConceptMap:nil];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [webView setDelegate:self];
    //[SplitwebView setDelegate:self];//remove maybe
    [linkCollectionView setDataSource:self];
    [linkCollectionView setDelegate:self];
    linkCollectionView.backgroundColor = [UIColor colorWithWhite:255 alpha:0.1];
    [linkCollectionView setHidden:YES];
    conceptNamesArray=[[NSMutableArray alloc] init];
    isCollectionShow=NO;
    //disable the bounce animation in the webview
    UIScrollView* sv = [webView scrollView];
    //UIScrollView* sv2 = [SplitwebView scrollView];
    [sv setShowsHorizontalScrollIndicator:NO];
    [sv setShowsVerticalScrollIndicator:NO];
    sv.delegate=self;
    //[sv2 setShowsHorizontalScrollIndicator:NO];
    //[sv2 setShowsVerticalScrollIndicator:NO];
    //sv2.delegate=self;
    isMenuShow=NO;
    syn=[[AVSpeechSynthesizer alloc]init];
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(oneFingerOneTaps:)];
    [singleTap setNumberOfTapsRequired:1];
    singleTap.delegate=self;
    //[webView addGestureRecognizer:singleTap];
    //[SplitwebView addGestureRecognizer:singleTap];
    
    //initialize the knowledge module
    knowledge_module=[ [KnowledgeModule alloc] init ];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handlePan:)];
    [panGesture setDelegate:self];
    [panGesture setMaximumNumberOfTouches:1];
    
    UISwipeGestureRecognizer *gestureRecognizerUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandler:)];
    UISwipeGestureRecognizer *gestureRecognizerDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandler:)];
  
    [gestureRecognizerUp setDirection:(UISwipeGestureRecognizerDirectionUp)];
    [gestureRecognizerDown setDirection:(UISwipeGestureRecognizerDirectionDown)];
    
    [gestureRecognizerDown setNumberOfTouchesRequired:2];
    [gestureRecognizerUp setNumberOfTouchesRequired:2];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapped:)];
    [doubleTap setNumberOfTapsRequired:2];
    doubleTap.delegate=self;
    [webView addGestureRecognizer:doubleTap];
    //[SplitwebView addGestureRecognizer:doubleTap];
    //set up menu items, icons and methods
    [self setingUpMenuItem];

    //specify the javascript file path
    NSString *filePath  = [[NSBundle mainBundle] pathForResource:@"JavaScriptFunctions" ofType:@"js" inDirectory:@""];
    if(filePath==nil){
        NSLog(@"Javascript file path null!");
    }
    NSData *fileData    = [NSData dataWithContentsOfFile:filePath];
    NSString *jsString  = [[NSMutableString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
    [webView stringByEvaluatingJavaScriptFromString:jsString];
    [SplitwebView stringByEvaluatingJavaScriptFromString:jsString];
    NSLog(@"Load Java script file.\n");
   // [webView loadHTMLString:_dataObject baseURL:_url];
    thumbNailController= [[ThumbNailController alloc]
                              initWithNibName:@"ThumbNailController" bundle:nil];
    logFileController= [[LogFileController alloc]
                          initWithNibName:@"LogFileController" bundle:nil];
    //load page highlights
    
    [webView loadHTMLString:_dataObject baseURL:_url];
    [SplitwebView loadHTMLString:_dataObject baseURL:_url];
    ThumbScrollViewLeft.showsHorizontalScrollIndicator=NO;
    ThumbScrollViewLeft.showsVerticalScrollIndicator=NO;
    ThumbScrollViewLeft.pagingEnabled=YES;
    ThumbScrollViewLeft.delegate=self;
    ThumbScrollViewLeft.contentSize = CGSizeMake(40, self.view.frame.size.height*2);
    ThumbScrollViewLeft.tag=1;
    ThumbScrollViewLeft.scrollEnabled=NO;
    
    [self.currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",pageNum, totalpageNum]];
    //[self loadThumbNailIcon];
    [self loadThumbNailIcon:firstRespondConcpet];
    
  //  UIBarButtonItem *conceptButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:nil];
   // self.parentViewController. navigationItem.rightBarButtonItem=conceptButton;
    UIImage* image3 = [UIImage imageNamed:@"idea"];
    CGRect frameimg = CGRectMake(0, 0, 40, 40);
    UIButton *someButton = [[UIButton alloc] initWithFrame:frameimg];
    [someButton setBackgroundImage:image3 forState:UIControlStateNormal];
    [someButton addTarget:self action:@selector(ConceptCloud:)
         forControlEvents:UIControlEventTouchUpInside];
    [someButton setShowsTouchWhenHighlighted:YES];
    
    UIBarButtonItem *mailbutton =[[UIBarButtonItem alloc] initWithCustomView:someButton];
    self.parent_BookViewController.navigationItem.rightBarButtonItem=mailbutton;
    
    QAWebview=[[UIWebView alloc]initWithFrame:CGRectMake(0, 28,512 ,740)];
    
    NSString* url =  [NSString stringWithFormat:@"http://2sigma.asu.edu/qa/index.php?qa=questions&qa_1=chapter-1&qa_2=page-%d", pageNum];
    QAWebview.backgroundColor=[UIColor whiteColor];
    NSURL* nsUrl = [NSURL URLWithString:url];
    NSURLRequest* request = [NSURLRequest requestWithURL:nsUrl cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30];
    
    [QAWebview loadRequest:request];
    
    //QAAskWebview
    SecondScreenView = [[UIView alloc]initWithFrame:CGRectMake(522, 0, 512, 768)];
    [SecondScreenView setBackgroundColor:[UIColor redColor]];
    [SecondScreenView addGestureRecognizer:gestureRecognizerUp];
    [SecondScreenView addGestureRecognizer:gestureRecognizerDown];
    
    [SplitwebView setFrame:CGRectMake(0, 0, 512, 768)];
    [SecondScreenView addSubview:SplitwebView];
    
    QAAskWebview =[[UIWebView alloc]initWithFrame:CGRectMake(0, 0,512 ,768)];
    QAAskWebViewBar = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 440, 580)];
    [QAAskWebViewBar setBackgroundColor:[UIColor lightGrayColor]];
    
    popUpViewPanArea = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 440, 30)];
    [popUpViewPanArea setBackgroundColor:[UIColor redColor]];
    [popUpViewPanArea addGestureRecognizer:panGesture];
    
    NSString* Askurl = [NSString stringWithFormat:@"http://2sigma.asu.edu/qa/index.php?qa=ask&cat=%d", (pageNum+2)];
    QAAskWebview.backgroundColor=[UIColor whiteColor];
    NSURL* nsAskUrl = [NSURL URLWithString:Askurl];
    NSURLRequest* Askrequest = [NSURLRequest requestWithURL:nsAskUrl cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30];
    
    [QAAskWebview loadRequest:Askrequest];
    
    [self.view addSubview:SecondScreenView];
    [SecondScreenView addSubview:QAWebview];
    [SecondScreenView setHidden:YES];
    [QAWebview setHidden:NO];
    
    cmapView=[[CmapController alloc] initWithNibName:@"CmapView" bundle:nil];
    cmapView.parent_ContentViewController=self;
    cmapView.dataObject=_dataObject;
    cmapView.showType=1;
    cmapView.url=_url;
    cmapView.bookHighlight=bookHighLight;
    cmapView.bookThumbNial=bookthumbNailIcon;
    cmapView.bookTitle=bookTitle;
    [cmapView.view setFrame:CGRectMake(0, -768, 512, 740)];
    [SecondScreenView addSubview:cmapView.view];
    [cmapView.view setHidden:YES];
    
    if( ([[UIApplication sharedApplication] statusBarOrientation]==UIInterfaceOrientationLandscapeLeft)||([[UIApplication sharedApplication] statusBarOrientation]==UIInterfaceOrientationLandscapeRight)){
        isSplit=YES;
        [ThumbScrollViewLeft setHidden:YES];
        [ThumbScrollViewRight setHidden:YES];
        [QAWebview setHidden:NO]; //
        [SplitwebView setHidden:YES]; // set yes to the view you want to be the default split screen view
        [SecondScreenView setHidden:NO];
        [cmapView.view setHidden:YES];
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//after the webview loads page, load highlight content
-(void)webViewDidFinishLoad:(UIWebView *)m_webView{
    [self loadHghLight];
    if( ([[UIApplication sharedApplication] statusBarOrientation]==UIInterfaceOrientationLandscapeLeft)||([[UIApplication sharedApplication] statusBarOrientation]==UIInterfaceOrientationLandscapeRight)){
        CGRect rec=CGRectMake(0, webView.frame.origin.y, 512, 768);
        [webView setFrame:rec];
        [SplitwebView setFrame:CGRectMake(0, 0, 512, 768)];
    }
}



//refresh the book page
-(void) refresh{
    [webView loadHTMLString:_dataObject baseURL:_url];
    [SplitwebView loadHTMLString:_dataObject baseURL:_url];
    [self.currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",pageNum, totalpageNum]];
}

-(void) setingUpMenuItem{ //set the menu items in the content view
    // use notification to check if the menu is showing
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowEditMenu:) name:UIMenuControllerWillShowMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowEditMenu:) name:UIMenuControllerDidShowMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didHideEditMenu:) name:UIMenuControllerDidHideMenuNotification object:nil];
    
    // Menu Controller, controls the manu list which will pop up when the user click a selected word or string
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    
    //add menu items to the menu list
    CXAMenuItemSettings *markIconSettingSpeak = [CXAMenuItemSettings new];
    markIconSettingSpeak.image = [UIImage imageNamed:@"speak"];
    markIconSettingSpeak.shadowDisabled = NO;
    markIconSettingSpeak.shrinkWidth = 4; //set menu item size and picture.
    
    CXAMenuItemSettings *markIconSettingsPopUp = [CXAMenuItemSettings new];
    markIconSettingsPopUp.image = [UIImage imageNamed:@"question"];
    markIconSettingsPopUp.shadowDisabled = NO;
    markIconSettingsPopUp.shrinkWidth = 4; //set menu item size and picture.
    
    CXAMenuItemSettings *markIconSettingsConcpet = [CXAMenuItemSettings new];
    markIconSettingsConcpet.image = [UIImage imageNamed:@"bb"];
    markIconSettingsConcpet.shadowDisabled = NO;
    markIconSettingsConcpet.shrinkWidth = 4; //set menu item size and picture
    
    CXAMenuItemSettings *markIconSettingsYelow = [CXAMenuItemSettings new];
    markIconSettingsYelow.image = [UIImage imageNamed:@"highlight_yellow"];
    markIconSettingsYelow.shadowDisabled = NO;
    markIconSettingsYelow.shrinkWidth = 4; //set menu item size and picture.
    
    CXAMenuItemSettings *markIconSettingsGreeen = [CXAMenuItemSettings new];
    markIconSettingsGreeen.image = [UIImage imageNamed:@"highlight_green"];
    markIconSettingsGreeen.shadowDisabled = NO;
    markIconSettingsGreeen.shrinkWidth = 4; //set menu item size and picture.
    
    CXAMenuItemSettings *markIconSettingsBlue = [CXAMenuItemSettings new];
    markIconSettingsBlue.image = [UIImage imageNamed:@"highlight_blue"];
    markIconSettingsBlue.shadowDisabled = NO;
    markIconSettingsBlue.shrinkWidth = 4; //set menu item size and picture.
    
    CXAMenuItemSettings *markIconSettingsPurple = [CXAMenuItemSettings new];
    markIconSettingsPurple.image = [UIImage imageNamed:@"highlight_purple"];
    markIconSettingsPurple.shadowDisabled = NO;
    markIconSettingsPurple.shrinkWidth = 4; //set menu item size and picture.
    
    CXAMenuItemSettings *markIconSettingsRed = [CXAMenuItemSettings new];
    markIconSettingsRed.image = [UIImage imageNamed:@"highlight_red"];
    markIconSettingsRed.shadowDisabled = NO;
    markIconSettingsRed.shrinkWidth = 4; //set menu item size and picture.
    
    CXAMenuItemSettings *underLineSet = [CXAMenuItemSettings new];
    underLineSet.image = [UIImage imageNamed:@"underline2"];
    underLineSet.shadowDisabled = NO;
    underLineSet.shrinkWidth = 4; //set menu item size and picture.
    
    CXAMenuItemSettings *undoSet = [CXAMenuItemSettings new];
    undoSet.image = [UIImage imageNamed:@"undo"];
    undoSet.shadowDisabled = NO;
    undoSet.shrinkWidth = 4; //set menu item size and picture.
    
    
    CXAMenuItemSettings *takeNoteSetting = [CXAMenuItemSettings new];
    takeNoteSetting.image = [UIImage imageNamed:@"take_note"];
    takeNoteSetting.shadowDisabled = NO;
    takeNoteSetting.shrinkWidth = 4; //set menu item size and picture.
    
    CXAMenuItemSettings *showQA = [CXAMenuItemSettings new];
    showQA.image = [UIImage imageNamed:@"QAicon"];
    showQA.shadowDisabled = NO;
    showQA.shrinkWidth = 4; //set menu item size and picture.
    
    
    UIMenuItem *getHighlightString = [[UIMenuItem alloc] initWithTitle: @"Pop" action: @selector(popUp:)];
    [getHighlightString cxa_setSettings:markIconSettingsPopUp];
    
    UIMenuItem *concept = [[UIMenuItem alloc] initWithTitle: @"concept" action: @selector(dragAndDrop:)];
    [concept cxa_setSettings:markIconSettingsConcpet];
    
    UIMenuItem *markHighlightedStringYellow = [[UIMenuItem alloc] initWithTitle: @"mark yellow" action: @selector(markHighlightedStringInYellow:)];
    [markHighlightedStringYellow cxa_setSettings:markIconSettingsYelow];
    
    UIMenuItem *markHighlightedStringGreen = [[UIMenuItem alloc] initWithTitle: @"mark green" action: @selector(markHighlightedStringInGreen:)];
    [markHighlightedStringGreen cxa_setSettings:markIconSettingsGreeen];
    
    UIMenuItem *markHighlightedStringBlue = [[UIMenuItem alloc] initWithTitle: @"mark blue" action: @selector(markHighlightedStringInBlue:)];
    [markHighlightedStringBlue cxa_setSettings:markIconSettingsBlue];
    
    UIMenuItem *markHighlightedStringPurple = [[UIMenuItem alloc] initWithTitle: @"mark purple" action: @selector(markHighlightedStringInPurple:)];
    [markHighlightedStringPurple cxa_setSettings:markIconSettingsPurple];
    
    UIMenuItem *markHighlightedStringRed = [[UIMenuItem alloc] initWithTitle: @"mark red" action: @selector(markHighlightedStringInRed:)];
    [markHighlightedStringRed cxa_setSettings:markIconSettingsRed];
    
    UIMenuItem *underLineItem = [[UIMenuItem alloc] initWithTitle: @"underline" action: @selector(underLine:)];
    [underLineItem cxa_setSettings:underLineSet];
    
   UIMenuItem *undoItem = [[UIMenuItem alloc] initWithTitle: @"undo" action: @selector(removeFormat:)];
    [undoItem cxa_setSettings:undoSet];
    
    UIMenuItem *takeNoteItem = [[UIMenuItem alloc] initWithTitle: @"take note" action: @selector(takeNote:)];
    [takeNoteItem cxa_setSettings:takeNoteSetting];
    
    
    UIMenuItem *speakItem = [[UIMenuItem alloc] initWithTitle: @"speak" action: @selector(speak:)];
    [speakItem cxa_setSettings:markIconSettingSpeak];
    
    UIMenuItem *showQAitem = [[UIMenuItem alloc] initWithTitle: @"QA" action: @selector(displayQA:)];
    [showQAitem cxa_setSettings:showQA];
    
    [menuController setMenuItems: [NSArray arrayWithObjects:getHighlightString,concept,markHighlightedStringYellow,markHighlightedStringGreen, markHighlightedStringBlue,
                                   markHighlightedStringPurple,markHighlightedStringRed,underLineItem,undoItem,takeNoteItem,speakItem, showQAitem, nil]];
    
    //[menuController setMenuItems: [NSArray arrayWithObjects:showQAitem, nil]];
    
    [menuController setMenuVisible:YES animated:YES];
    
}


- (IBAction)ConceptCloud : (id)sender
{
    
    SampleViewController* conceptCloud= [[SampleViewController alloc]init];
    conceptCloud.view.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed:@"blurWallPaper"] ];
     [self.navigationController pushViewController:conceptCloud animated:YES];
     [self.parentViewController.navigationController setNavigationBarHidden: NO animated:YES];
     self.parentViewController.navigationController.navigationBar.translucent = YES;
}

- (IBAction)linkCollection : (id)sender
{
    /*
    if (YES==isCollectionShow){
        [linkCollectionView setHidden:YES];
        isCollectionShow=NO;
        //[webView setFrame:CGRectMake(webView.frame.origin.x-60, webView.frame.origin.y, webView.frame.size.width, webView.frame.size.height)];
        //[ThumbScrollView setFrame:CGRectMake(ThumbScrollView.frame.origin.x-80, ThumbScrollView.frame.origin.y, ThumbScrollView.frame.size.width, ThumbScrollView.frame.size.height)];
    }else if (NO==isCollectionShow){
        [linkCollectionView setHidden:NO];
        isCollectionShow=YES;
        //[webView setFrame:CGRectMake(webView.frame.origin.x+60, webView.frame.origin.y, webView.frame.size.width, webView.frame.size.height)];
        //[ThumbScrollView setFrame:CGRectMake(ThumbScrollView.frame.origin.x+80, ThumbScrollView.frame.origin.y, ThumbScrollView.frame.size.width, ThumbScrollView.frame.size.height)];
    }*/
    
}


// invoke when user tap with one finger once
- (void)oneFingerOneTaps:(UITapGestureRecognizer *)tap
{
    pvPoint = [tap locationInView:self.view];//track the last click position in order to show the popUp view
    if(!isMenuShow){  //is the menu bar is showing, disable the gesture action
        //set navigation bar animation, which uses the QuartzCore framework.
        self.parentViewController.navigationController.navigationBar.translucent = YES;
         [ self.parentViewController.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        CATransition *navigationBarAnimation = [CATransition animation];
        navigationBarAnimation.duration = 0.6;
        navigationBarAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];;
        navigationBarAnimation.type = kCATransitionMoveIn;
        navigationBarAnimation.subtype = kCATransitionFromBottom;
        navigationBarAnimation.removedOnCompletion = YES;
        [self.parentViewController.navigationController.navigationBar.layer addAnimation:navigationBarAnimation forKey:nil];
        //click with one finger to show or hind the navigaion bar.
        BOOL navBarState = [self.parentViewController.navigationController isNavigationBarHidden];
        if(!navBarState ){
            [self.parentViewController.navigationController setNavigationBarHidden: YES animated:YES];
        }else {
            [self.parentViewController.navigationController setNavigationBarHidden: YES animated:YES];
        }
    }else{
        [self.parentViewController.navigationController setNavigationBarHidden: YES animated:YES];
    }
    
}

//invoke when user double tap with one finger
- (void)doubleTapped:(UITapGestureRecognizer *)tap
{
    pvPoint = [tap locationInView:self.view];
    pv = [PopoverView showPopoverAtPoint:pvPoint
                                  inView:self.view
                               withTitle:@"Need help?"
                         withStringArray:kStringArray
                                delegate:self];
}

//invoke when user select one item in the PopOver menu.
- (void)popoverView:(PopoverView *)popoverView didSelectItemAtIndex:(NSInteger)index
{
    NSLog(@"%s item:%d", __PRETTY_FUNCTION__, index);
    NSString *selection = [webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"];
    
    // Figure out which string was selected, store in "string"
    NSString *string = [kStringArray objectAtIndex:index];
    // Show a success image, with the string from the array
    if(0==index){
        NSString* h_text=[webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"];
        [self createConceptIcon:pvPoint NoteText:h_text isWriteToFile:YES];
        //firstRespondConcpet=h_text;
    }else if(1==index){
        [popoverView showImage:[UIImage imageNamed:@"error"] withMessage:string];
    }else if(2==index){
        NSString *wikiLink=@"http://en.wikipedia.org/wiki/";
        wikiLink=[wikiLink stringByAppendingString:selection];
        wikiLink= [wikiLink stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        NSURL *url = [NSURL URLWithString:wikiLink];
        NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
        //create a new UIwebview to display the wiki page
        WebBrowserViewController *webBroser= [[WebBrowserViewController alloc]
                                              initWithNibName:@"WebBrowserViewController" bundle:nil];
        webBroser.isNew=YES;
        webBroser.requestObj=requestObj;
        webBroser.parent_View_Controller=self;
        webBroser.pvPoint=pvPoint;
        //push the controller to the navigation bar
        [self.parentViewController.navigationController setNavigationBarHidden: NO animated:YES];
        self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
        [self.navigationController pushViewController:webBroser animated:YES];
    }else if (3==index){
        NSString *googleLink=@"https://www.google.com/search?q=";
        googleLink=[googleLink stringByAppendingString:selection];
        //replace the " " character in the url with "%20" in order to connect the seperate words for search
        googleLink= [googleLink stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        NSLog(@"Url Link afterf replacing %@",googleLink);
        NSURL *url = [NSURL URLWithString:googleLink];
        NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
        
        WebBrowserViewController *webBroser= [[WebBrowserViewController alloc]
                                              initWithNibName:@"WebBrowserViewController" bundle:nil];
        webBroser.parent_View_Controller=self;
        webBroser.requestObj=requestObj;
         webBroser.pvPoint=pvPoint;
        [self.parentViewController.navigationController setNavigationBarHidden: NO animated:YES];
        self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
        [self.navigationController pushViewController:webBroser animated:YES];
    }
    else if (4==index){//starting concetp map
        CmapController *cmapView2=[[CmapController alloc] initWithNibName:@"CmapView" bundle:nil];
        cmapView2.dataObject=_dataObject;
        cmapView2.url=_url;
        cmapView2.showType=0;
        cmapView2.bookHighlight=bookHighLight;
        cmapView2.bookThumbNial=bookthumbNailIcon;
        cmapView2.bookTitle=bookTitle;
        cmapView2.parent_ContentViewController=self;
        [self.navigationController pushViewController:cmapView2 animated:YES];
    }
    // Dismiss the PopoverView after 0.5 seconds
    [popoverView performSelector:@selector(dismiss) withObject:nil afterDelay:0.5f];
}


//Need to add this function to enable web view to recognize gesture.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

//give permission to show the menu item we added
- (BOOL) canPerformAction:(SEL)action withSender:(id)sender
{
    if (  action == @selector(markHighlightedString:)
        ||action==@selector(dragAndDrop:)
        ||action==@selector(popUp:)
        ||action == @selector(markHighlightedStringInYellow:)
        ||action == @selector(markHighlightedStringInGreen:)
        ||action==@selector(speak:)
        ||action == @selector(markHighlightedStringInBlue:)
        ||action == @selector(markHighlightedStringInPurple:)
        ||action == @selector(markHighlightedStringInRed:)
        ||action == @selector(underLine:)
        ||action==@selector(takeNote:)
        ||action==@selector(ConceptCloud:)
        ||action==@selector(displayQA:)
        ||action == @selector(removeFormat:))
    {
        return YES;
    }
    return NO;
}

- (void)dragAndDrop:(id)sender{
    if(YES==isSplit){
        [cmapView createNodeFromBook:CGPointMake(200, 200) withName:[webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"] BookPos:pvPoint];
    }
    if(NO==isSplit){
        [self createConceptThumb:[webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"]];
    }
}

-(void)createConceptThumb: (NSString*)name{
    NodeCell *node=[[NodeCell alloc]initWithNibName:@"NodeCell" bundle:nil];
    node.nodeType=1;
    node.isInitialed=YES;
    node.text.enabled=NO;
    int y=[thumbNailController getIconPos:pvPoint type:1];
    [node.view setFrame:CGRectMake(6, y,node.view.frame.size.width, node.view.frame.size.height)];
    [self addChildViewController:node];
    [ThumbScrollViewRight addSubview: node.view ];
    node.text.text=name;
    node.text.disableEditting=YES;//disable editting

}

- (void)highlightStringWithColor:(NSString*)color{
    // Invoke the javascript function
    NSString *startSearch   = [NSString stringWithFormat:@"highlightStringWithColor(\""];
    startSearch=[startSearch stringByAppendingString:color];
    startSearch=[startSearch stringByAppendingString:@"\")"];
    [webView stringByEvaluatingJavaScriptFromString:startSearch];
    //[SplitwebView stringByEvaluatingJavaScriptFromString:startSearch];
}

- (void)callJavaScriptMethod:(NSString*)method{
    // Invoke the javascript function
    NSString *startSearch   = [NSString stringWithFormat:@""];
    startSearch=[startSearch stringByAppendingString:method];
    startSearch=[startSearch stringByAppendingString:@"()"];
    [webView stringByEvaluatingJavaScriptFromString:startSearch];
    //[SplitwebView stringByEvaluatingJavaScriptFromString:startSearch];
}


//calling the function in HighlightedString.js to highlight the text in yellow
- (IBAction)markHighlightedStringInYellow : (id)sender {
    [self saveHighlightToXML:@"#ffffcc" ];
    [self highlightStringWithColor:@"#FFFFCC"];
    //shake the bulb image to indicate that there is new conpcet detected in the highlighted content
    if([self searchConceptCount]>0){
    [self shakeImage:nil];
    }
}

//calling the function in HighlightedString.js to highlight the text in green
- (IBAction)markHighlightedStringInGreen : (id)sender {
    [self saveHighlightToXML:@"#C5FCD6" ];
    [self highlightStringWithColor:@"#C5FCD6"];
    if([self searchConceptCount]>0){
        [self shakeImage:nil];
    }
}


//calling the function in HighlightedString.js to highlight the text in blue
- (IBAction)markHighlightedStringInBlue : (id)sender {
    [self saveHighlightToXML:@"#C2E3FF"];
      [self highlightStringWithColor:@"#C2E3FF"];
    if([self searchConceptCount]>0){
        [self shakeImage:nil];
    }
}

//calling the function in HighlightedString.js to highlight the text in purple
- (IBAction)markHighlightedStringInPurple : (id)sender {
    [self saveHighlightToXML:@"#E8CDFA"];
    [self highlightStringWithColor:@"#E8CDFA"];
    if([self searchConceptCount]>0){
        [self shakeImage:nil];
    }
}

//calling the function in HighlightedString.js to highlight the text in red
- (IBAction)markHighlightedStringInRed : (id)sender {
    [self saveHighlightToXML:@"#FFBABA"];
    [self highlightStringWithColor:@"#FFBABA"];
    if([self searchConceptCount]>0){
        [self shakeImage:nil];
    }
}

//calling the function in HighlightedString.js to underline the text
- (IBAction)underLine : (id)sender {
    [self callJavaScriptMethod:@"underlineText"];
    if([self searchConceptCount]>0){
        [self shakeImage:nil];
    }
}

//calling the function in HighlightedString.js to remove all the format
- (IBAction)removeFormat : (id)sender {
    [self callJavaScriptMethod:@"clearFormat"];
    if([self searchConceptCount]>0){
        [self shakeImage:nil];
    }
}


-(void)showPageAtINdex:(int)pageNumber{
    if(isSplit)
    {
        [parent_BookViewController showFirstPage:pageNumber+1];
        
        if (pageNumber == totalpageNum) {
            //add code to display a blank white page if the second page reaches the last page
        }
        else
        {
            [child_BookViewController showFirstPage:pageNumber+2];
        }
    }
    else
    {
        [parent_BookViewController showFirstPage:pageNumber];
    
        if (pageNumber == totalpageNum) {
        //add code to display a blank white page if the second page reaches the last page
        }
        else
        {
            [child_BookViewController showFirstPage:pageNumber+1];
        }
    }
    
}

//shows the popup view
- (IBAction)popUp : (UITapGestureRecognizer *)tap {
    NSString *selection = [webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"];
    NSLog(@" %@",selection);
    NSString *definition=@"Textbook Definition: ";
    NSString *textBookDefinition= [knowledge_module getTextBookDefinition:selection];
    definition=[definition stringByAppendingString: textBookDefinition];
    NSString *wikiLink=@"See wikipedia definition.";
    NSString *googleLink=@"Search Google.";
    NSArray *popUpContent=[NSArray arrayWithObjects:selection, definition,wikiLink,googleLink, nil];
    pv = [PopoverView showPopoverAtPoint:pvPoint
                                  inView:self.view
                               withTitle:@"Need help?"
                         withStringArray:popUpContent
                                delegate:self];
}


//pan gesture handles popup qa view
-(void)handlePan: (UIPanGestureRecognizer*) recognizer
{

    CGPoint translation = [recognizer translationInView:QAAskWebViewBar];
    
    QAAskWebViewBar.center=CGPointMake(QAAskWebViewBar.center.x+translation.x, QAAskWebViewBar.center.y+translation.y);
    
    [recognizer setTranslation:CGPointMake(0, 0)inView:QAAskWebViewBar];
    
    //CGPoint translation = [recognizer translationInView:recognizer.view];
   
    //recognizer.view.center = CGPointMake(recognizer.view.center.x+translation.x, recognizer.view.center.y+translation.y);
    
    //[recognizer setTranslation:CGPointMake(0, 0) inView:recognizer.view];
    
    
}

-(void)swipeHandler:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"Swipe Second Screen received.");
    
    if(recognizer.direction == UISwipeGestureRecognizerDirectionUp)
    {
        if(QAWebview.hidden == YES)
        {
            [QAWebview setHidden:NO];
            
            NSLog(@"gets to qaview if");
            
            [UIView animateWithDuration:0.33f
                                  delay:0.0f
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 //[SecondScreenView setFrame:QAWebview.frame];
                                 [cmapView.view setFrame:CGRectMake(0.0, -768, 512, 740)];
                                 [QAWebview setFrame:CGRectMake(0.0, 28, 512, 740)];
                             }
                             completion:^(BOOL finished){
                                 // do whatever post processing you want (such as resetting what is "current" and what is "next")
                             }];
            [cmapView.view setHidden:YES];
        }
        else if(cmapView.view.hidden == YES)
        {
            [cmapView.view setHidden:NO];
            
            NSLog(@"gets to cmap if");
            [UIView animateWithDuration:0.33f
                                  delay:0.0f
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 //[SecondScreenView setFrame:cmapView.view.frame];
                                 [QAWebview setFrame:CGRectMake(0.0, -768, 512, 740)];
                                 [cmapView.view setFrame:CGRectMake(0.0, 28, 512, 740)];
                             }
                             completion:^(BOOL finished){
                                 // do whatever post processing you want (such as resetting what is "current" and what is "next")
                             }];
            [QAWebview setHidden:YES];
        }

        
    }
    if(recognizer.direction == UISwipeGestureRecognizerDirectionDown)
    {
        if(QAWebview.hidden == YES)
        {
            [QAWebview setHidden:NO];
            
            NSLog(@"gets to qaview if");
            
            [UIView animateWithDuration:0.33f
                                  delay:0.0f
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 //[SecondScreenView setFrame:QAWebview.frame];
                                 [cmapView.view setFrame:CGRectMake(0.0, -768, 512, 740)];
                                 [QAWebview setFrame:CGRectMake(0.0, 28, 512, 740)];
                             }
                             completion:^(BOOL finished){
                                 // do whatever post processing you want (such as resetting what is "current" and what is "next")
                             }];
            [cmapView.view setHidden:YES];
        }
        else if(cmapView.view.hidden == YES)
        {
            [cmapView.view setHidden:NO];
            
            NSLog(@"gets to cmap if");
            [UIView animateWithDuration:0.33f
                                  delay:0.0f
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 //[SecondScreenView setFrame:cmapView.view.frame];
                                 [QAWebview setFrame:CGRectMake(0.0, -768, 512, 740)];
                                 [cmapView.view setFrame:CGRectMake(0.0, 28, 512, 740)];
                             }
                             completion:^(BOOL finished){
                                 // do whatever post processing you want (such as resetting what is "current" and what is "next")
                             }];
            [QAWebview setHidden:YES];
        }
    }
}

-(IBAction)displayQA:(UITapGestureRecognizer *)tap
 {
 
     QAAskWebViewBar.center=CGPointMake(400, 400);
     [self.view addSubview:QAAskWebViewBar];
     [QAAskWebViewBar addSubview:QAAskWebview];
     [QAAskWebViewBar addSubview:popUpViewPanArea];
     
     UIButton *closeQAAskWebViewButton = [UIButton buttonWithType:UIButtonTypeCustom];
     closeQAAskWebViewButton.frame=CGRectMake(390, -35, 100, 100);
     [closeQAAskWebViewButton addTarget:self action:@selector(closeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
     [closeQAAskWebViewButton setImage:[UIImage imageNamed:@"error.png"] forState:UIControlStateNormal];
     
     [QAAskWebViewBar addSubview:closeQAAskWebViewButton];
     [QAAskWebview setHidden:YES];
     
     
     //add how to turn of page flips while popup is displayed to be able to move view around easily
     //without interuption of page attempting to flip
     //also add Shangs fixes to limit page flipping to book only in split screen mode
     //[BookViewController ];
    
    /*
     add a subview that displays a close button on top right hand corner of the qaaskwebview
     and given selector @closeQA
     [self.view addSubview:]
     */
    
    if( ([[UIApplication sharedApplication] statusBarOrientation]==UIInterfaceOrientationLandscapeLeft)||([[UIApplication sharedApplication] statusBarOrientation]==UIInterfaceOrientationLandscapeRight)){
        
        [QAAskWebview setHidden:YES];  //made change
        [QAAskWebViewBar setHidden:YES];
        isSplit=YES;
        /*
         [ThumbScrollViewLeft setHidden:YES];
         [ThumbScrollViewRight setHidden:YES];*/
    
    }
    else
    {
        
        CGRect rec=CGRectMake(1, 30, 438, 549);
        [QAAskWebview setFrame:rec];
        //QAAskWebview.center=CGPointMake(400, 400);
        [QAAskWebview setHidden:NO];
        [QAAskWebViewBar setHidden:NO];
    }

}

-(IBAction)closeButtonClicked:(id)sender{
    
    [QAAskWebViewBar setHidden:YES];
     //hide the close button
    
    NSLog(@"gets to close button");
    
}


-(void)saveHighlightToXML:(NSString*)color_string {
    NSString* h_text=[webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"];
    int s_Container=[[webView stringByEvaluatingJavaScriptFromString:@"myGetNodeCount(document.body,window.getSelection().getRangeAt(0).startContainer)"] intValue];
    int e_Container= [[webView stringByEvaluatingJavaScriptFromString:@"myGetNodeCount(document.body,window.getSelection().getRangeAt(0).endContainer)"] intValue];
    int s_offSet= [[webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().getRangeAt(0).startOffset"] intValue];
    int e_offSet= [[webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().getRangeAt(0).endOffset"] intValue];
    HighLight *temp_highlight = [[HighLight alloc] initWithName:h_text pageNum:pageNum count:1 color:color_string startContainer:s_Container startOffset:s_offSet endContainer:e_Container endOffset:e_offSet bookTitle:bookTitle];
    if([self ifHighlightCollapse:temp_highlight]!=-1){
    [bookHighLight addHighlight:temp_highlight];
    }
    [HighlightParser saveHighlight:bookHighLight];
}


//handle situations when two hihglights collapse with each other
-(int)ifHighlightCollapse: (HighLight*) temp_highlight{
    if (bookHighLight != nil) {
        for (HighLight *highLightText in bookHighLight.highLights) {
            if(highLightText.startContainer==temp_highlight.startContainer&& highLightText.endContainer==(temp_highlight.endContainer-1)&&highLightText.page==pageNum){
                temp_highlight.endContainer--;
                int temp=highLightText.startOffset;
                highLightText.startOffset+=temp_highlight.endOffset;
                temp_highlight.endOffset+=temp;
                return 0;
            }
            
            else if(highLightText.startContainer==(temp_highlight.startContainer-1)&& highLightText.endContainer==(temp_highlight.endContainer-2)&&highLightText.page==pageNum){
                temp_highlight.startContainer++;
                
                int temp=highLightText.endOffset;
                int temp_startOffset=temp_highlight.startOffset;
                highLightText.endOffset=highLightText.startOffset+ temp_highlight.startOffset;
                temp_highlight.startOffset=0;
                temp_highlight.endOffset+=temp-highLightText.startOffset-temp_startOffset;
                return 0;
            }
        if (highLightText.startContainer==temp_highlight.startContainer&&highLightText.endContainer<temp_highlight.endContainer&&highLightText.page==pageNum) {
            highLightText.text=temp_highlight.text;
            highLightText.startOffset=temp_highlight.startOffset;
            highLightText.endOffset+=temp_highlight.endOffset;
            highLightText.color=temp_highlight.color;
            temp_highlight=nil;
                return -1;
            }
        }
    }
    return 0;
}


//use the tts engine to speak the selected text
- (IBAction)speak : (id)sender {
    
     //get the selected text
     NSString *selection = [webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"];
    AVSpeechUtterance *utterance_English= [[AVSpeechUtterance alloc]initWithString:selection];
    utterance_English.rate = AVSpeechUtteranceMaximumSpeechRate/7;
    utterance_English.voice=[AVSpeechSynthesisVoice voiceWithLanguage:@"es-us"];
    [syn speakUtterance:utterance_English];
}

- (IBAction)takeNote : (id)sender {
    NSString *selection = [webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"];
    firstRespondConcpet=selection;
    NSArray *popUpContent=[NSArray arrayWithObjects:@"NoteTaking", nil];
    pv = [PopoverView showPopoverAtPoint:pvPoint
                                  inView:self.view
                               withTitle:@"Take Note"
                         withStringArray:popUpContent
                                delegate:self];
    pv.parent_View_Controller=self;
    pv.showPoint=pvPoint;
    pv.parentViewController=self;
}


-(void)createWebNote : (CGPoint) show_at_point URL:(NSURLRequest*) urlrequest isWriteToFile:(BOOL)iswrite isNewIcon: (BOOL)isNew  {
 NSString *selection = [webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"];
    firstRespondConcpet=selection;
    WebMarkController *note= [[WebMarkController alloc]
                              initWithNibName:@"WebMarkController" bundle:nil];
    note.web_requestObj=urlrequest;
    note.pvPoint=show_at_point;
    note.parentController=self;
    CGPoint newPos;
    newPos.x=show_at_point.x;
    newPos.y=[thumbNailController getIconPos:show_at_point type:0];
    note.iconPoint=newPos;
    [self addChildViewController:note];
    [ThumbScrollViewLeft addSubview:note.view];

    NSString *urlString= [[urlrequest URL] absoluteString];

    if([firstRespondConcpet isEqualToString:@""]){
        firstRespondConcpet=@"Cell";
    }
    ThumbNailIcon *temp_thumbnail = [[ThumbNailIcon alloc] initWithName: 2 Text: @"" URL:urlString showPoint:show_at_point pageNum:pageNum bookTitle:bookTitle relatedConcept:firstRespondConcpet];
    if(iswrite){
        [bookthumbNailIcon addthumbnail:temp_thumbnail];
        [ThumbNailIconParser saveThumbnailIcon:bookthumbNailIcon];
    }
}


-(NoteViewController*)createNote : (CGPoint) show_at_point NoteText:(NSString*) m_note_text isWriteToFile:(BOOL)iswrite  {
    NoteViewController *note= [[NoteViewController alloc]
                               initWithNibName:@"NoteView" bundle:nil];
    note.note_text= m_note_text;
    note.pvPoint=show_at_point;
    note.parentController=self;
    CGPoint newPos;
    newPos.x=show_at_point.x;
    newPos.y=[thumbNailController getIconPos:show_at_point type: 0];
    note.iconPoint=newPos;
    [self addChildViewController:note];
    [ThumbScrollViewLeft addSubview: note.view ];
    
    if([firstRespondConcpet isEqualToString:@""]){
        firstRespondConcpet=@"Cell";
    }
    ThumbNailIcon *temp_thumbnail = [[ThumbNailIcon alloc] initWithName: 1 Text: m_note_text URL:@"" showPoint:show_at_point pageNum:pageNum bookTitle:bookTitle relatedConcept:firstRespondConcpet];
    if(iswrite){
         NSLog(@"True Node");
        [bookthumbNailIcon addthumbnail:temp_thumbnail];
        [bookthumbNailIcon printAllThumbnails];
        
        [ThumbNailIconParser saveThumbnailIcon:bookthumbNailIcon];
    }
    return note;
}


-(ConceptViewController*)createConceptIcon : (CGPoint) show_at_point NoteText:(NSString*) m_note_text isWriteToFile:(BOOL)iswrite  {

  
    
    ConceptViewController *note= [[ConceptViewController alloc]
                               initWithNibName:@"ConceptViewController" bundle:nil];
    if(YES==isSplit){
       [cmapView createNode:CGPointMake(200, 200) withName:m_note_text];
         return note;
    }
    
    note.pvPoint=show_at_point;
    note.parentController=self;
    CGPoint newPos;
    newPos.x=show_at_point.x;
    newPos.y=[thumbNailController getIconPos:show_at_point type: 0];
    note.iconPoint=newPos;
    [self addChildViewController:note];
    [ThumbScrollViewRight addSubview: note.view ];
    if(![m_note_text isEqualToString:@""]){
     note.textField.text=m_note_text;
    }
   
    if(iswrite){

    }
    return note;
}

-(void)updateNoteText:(CGPoint) show_at_point PreText: (NSString*)pre_text NewText: (NSString *)new_text
{
    NSLog(@"Update!!");
    for(ThumbNailIcon *icon in bookthumbNailIcon.thumbnails ){
        if(icon.showPoint.x== show_at_point.x && icon.showPoint.y==show_at_point.y&& [icon.text isEqualToString:pre_text]){
            icon.text=new_text;
        }
    }
    [ThumbNailIconParser saveThumbnailIcon:bookthumbNailIcon];
}


- (NSInteger)highlightAllOccurencesOfString:(NSString*)str
{    
    NSString *startSearch = [NSString stringWithFormat:@"MyApp_HighlightAllOccurencesOfString('%@')",str];
    [webView stringByEvaluatingJavaScriptFromString:startSearch];
    
    NSString *result = [webView stringByEvaluatingJavaScriptFromString:@"MyApp_SearchResultCount"];
    return [result integerValue];
}


-(void)loadHghLight{
    if (bookHighLight != nil) {
        for (HighLight *highLightText in bookHighLight.highLights) {
            if(pageNum== highLightText.page && [bookTitle isEqualToString: highLightText.bookTitle]){
                NSString *methodString=[NSString stringWithFormat:@"highlightRangeByOffset(document.body,%d,%d,%d,%d,'%@')",highLightText.startContainer,highLightText.startOffset,
                                    highLightText.endContainer,highLightText.endOffset,highLightText.color];
                [webView stringByEvaluatingJavaScriptFromString:methodString];            
            }
        }
    }
}

-(void)loadThumbNailIcon: (NSString*)concpet{
    if(bookthumbNailIcon!=nil){
        for(ThumbNailIcon *thumbNailItem in bookthumbNailIcon.thumbnails){
           // if([thumbNailItem.relatedConcpet isEqualToString: concpet]){
            
            if(thumbNailItem.page==pageNum && [bookTitle isEqualToString: thumbNailItem.bookTitle]){
                if(1==thumbNailItem.type){
                    [self createNote:thumbNailItem.showPoint NoteText:thumbNailItem.text isWriteToFile:NO];
                }else if(2==thumbNailItem.type){
                    [self createWebNote:thumbNailItem.showPoint URL:   [NSURLRequest requestWithURL:[NSURL URLWithString:thumbNailItem.url]] isWriteToFile:NO isNewIcon:YES ];
                }
            }
          //}
        }
    }
    
    //initialize bulb image vie
    self.bulbImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 20, 40, 40)];
    [self.bulbImageView setImage:[UIImage imageNamed:@"idea"]];
    self.bulbImageView.alpha=0.8;
    self.bulbImageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *bulbTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(linkCollection:)];
    
    [self.bulbImageView addGestureRecognizer:bulbTap];
    
    [ThumbScrollViewLeft addSubview:self.bulbImageView];
}


-(void)autoGerenateConceptNode{
    int conceptId=0;
    if ( bookHighLight!= nil) {
        for (HighLight *highLightText in bookHighLight.highLights) {
            NSString *methodString=highLightText.text;
            for (  Concept *cell in knowledge_module.conceptList) {
                if([methodString rangeOfString:cell.conceptName].location != NSNotFound){
                    /*
                    if(![conceptNamesArray containsObject: cell.conceptName]){
                        [conceptNamesArray addObject:cell.conceptName];
                        CGPoint position= [self calculateNodePosition:conceptId];
                        conceptId++;
                        //[self createNode:position withName:cell.conceptName];
                    }*/
                    
                }
            }
        }
    }
}

-(UIImage*)getScreenShot{
    
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 0.0);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    
    
    [gaussianBlurFilter setDefaults];
    [gaussianBlurFilter setValue:[CIImage imageWithCGImage:[snapshotImage CGImage]] forKey:kCIInputImageKey];
    [gaussianBlurFilter setValue:@40 forKey:kCIInputRadiusKey];
    
    
    CIImage *outputImage = [gaussianBlurFilter outputImage];
    CIContext *context   = [CIContext contextWithOptions:nil];
    CGRect rect          = [outputImage extent];
    
    // these three lines ensure that the final image is the same size

    rect.origin.x        += (rect.size.width  - snapshotImage.size.width ) / 2;
    rect.origin.y        += (rect.size.height - snapshotImage.size.height) / 2;
    rect.size            = snapshotImage.size;
    
    CGImageRef cgimg     = [context createCGImage:outputImage fromRect:rect];
    UIImage *image       = [UIImage imageWithCGImage:cgimg];
    CGImageRelease(cgimg);
    return image;
}

// check if the menu bar is showing
- (IBAction)didHideEditMenu : (id)sender {
    isMenuShow=NO;
}
//if the menu bar is about popup, hide the navigation bar
- (IBAction)willShowEditMenu : (id)sender {
    [self.parentViewController.navigationController setNavigationBarHidden: YES animated:YES];
    isMenuShow=YES;
}
- (IBAction)didShowEditMenu : (id)sender {
    isMenuShow=YES;
    
    
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //bind the thumbnail scroll view and the web view together to scroll simultaneously.
    if(0==scrollView.tag){
        //ThumbScrollView.contentOffset=CGPointMake(0, scrollView.contentOffset.y);
    }
}


-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    //when retating the device, clear the thumbnail icons and reload
    for (UIView *subviews in [ThumbScrollViewLeft subviews]) {
        if(subviews.frame.size.height!=7){
            [subviews removeFromSuperview];
        }
    }
    if(YES==isleftThumbShow){
    [thumbNailController clearAllThumbnail];
    [self loadThumbNailIcon:firstRespondConcpet];
    }
    //if user rotate the screen from portrait to landscape, show the concept map view.
    if(fromInterfaceOrientation==UIInterfaceOrientationPortrait||fromInterfaceOrientation==UIInterfaceOrientationPortraitUpsideDown){
    [self splitScreen];
    }
    //otherwise, hide the concept map view.
    if(fromInterfaceOrientation==UIInterfaceOrientationLandscapeLeft||fromInterfaceOrientation==UIInterfaceOrientationLandscapeRight){
        [self resumeNormalScreen ];
    }
    
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    if(toInterfaceOrientation==UIInterfaceOrientationPortrait||toInterfaceOrientation==UIInterfaceOrientationPortraitUpsideDown){
      //  [self resumeNormalScreen ];
    }
}




-(void)shakeImage:(id)sender {
    CABasicAnimation* shake = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    shake.fromValue = [NSNumber numberWithFloat:-0.3];
    shake.toValue = [NSNumber numberWithFloat:+0.3];
    shake.duration = 0.1;
    shake.autoreverses = YES;
    shake.repeatCount = 3;
    [self.bulbImageView.layer addAnimation:shake forKey:@"imageView"];
   // self.bulbImageView.alpha = 1.0;
    [UIView animateWithDuration:2.0 delay:2.0 options:UIViewAnimationOptionCurveEaseIn animations:nil completion:nil];
}

- (UIImage*)scaleToSize:(CGSize)size image:(UIImage*) img {
    UIGraphicsBeginImageContext(size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, size.width, size.height), img.CGImage);
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

-(int)searchConceptCount{
    NSString *selection = [webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"];
        int conceptId=0;

                for (  Concept *cell in knowledge_module.conceptList) {
                    if([selection rangeOfString:cell.conceptName].location != NSNotFound){
                        if(![conceptNamesArray containsObject: cell.conceptName]){
                            [conceptNamesArray addObject:cell.conceptName];
                            conceptId++;
                        }
                    }
                }
    return conceptId;
}




-(BOOL)prefersStatusBarHidden{
    return YES;
}

//split the screen, the left side shows the textbook and the right side shows the concept map construction view.
-(void)splitScreen{
    isSplit=YES;
    [ThumbScrollViewLeft setHidden:YES];
    [ThumbScrollViewRight setHidden:YES];
    CGRect rec=CGRectMake(0, webView.frame.origin.y, 512, 768);
    [webView setFrame:rec];
    [QAAskWebViewBar setHidden:YES];
    [SecondScreenView setHidden:NO];
}

-(void)resumeNormalScreen{
    isSplit=NO;
    [SecondScreenView setHidden:YES];
    CGRect rec=CGRectMake(52, webView.frame.origin.y, 653, 967);
    [webView setFrame:rec];
    //[SecondScreenView setFrame:CGRectMake(52, 0, 653, 967)];
    //[QAWebview setFrame:CGRectMake(0, 0, 653, 967)];
    
    [ThumbScrollViewLeft setHidden:NO];
    [ThumbScrollViewRight setHidden:NO];
   // [cmapView.view removeFromSuperview];
}

-(void)resumeNormalScreenLandscape{
    CGRect rec=CGRectMake(52, webView.frame.origin.y, 930, 720);
    [webView setFrame:rec];
    [ThumbScrollViewLeft setHidden:NO];
    [ThumbScrollViewRight setHidden:NO];
   // [cmapView.view removeFromSuperview];
}

-(void)showCmapFullScreen{
    //isSplit=NO;
     //[self resumeNormalScreenLandscape];
    
}

-(void)showRecourseFullScreen{
    isSplit=NO;
    [self resumeNormalScreenLandscape];
    LSHorizontalScrollTabViewDemoViewController *tabView=[[LSHorizontalScrollTabViewDemoViewController alloc] initWithNibName:@"LSHorizontalScrollTabViewDemoViewController" bundle:nil];
    tabView.highlightWrapper=bookHighLight;
    tabView.thumbNailWrapper=bookthumbNailIcon;
    tabView.bookTitle=bookTitle;
    tabView.showType=0;
    tabView.parentContentViewController=self;
    [self.navigationController pushViewController:tabView animated:NO];
    //[self addChildViewController:tabView];
    //[self.view addSubview:tabView.view];
}

@end
