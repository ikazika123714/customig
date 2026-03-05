#import "SCISettingsViewController.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

static char rowStaticRef[] = "row";

// --- KLASA ZA TEKST KOJI MENJA BOJE (ANIMACIJA) ---
@interface HawaiiAnimatedLabel : UILabel
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat hue;
@end

@implementation HawaiiAnimatedLabel
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.hue = 0;
        // Tajmer koji na svakih 0.05 sekundi pomera boju (hue)
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateColor) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)updateColor {
    self.hue += 0.01;
    if (self.hue > 1.0) self.hue = 0;
    self.textColor = [UIColor colorWithHue:self.hue saturation:1.0 brightness:1.0 alpha:1.0];
}

- (void)removeFromSuperview {
    [self.timer invalidate];
    self.timer = nil;
    [super removeFromSuperview];
}
@end

// --- GLAVNI KONTROLER ---
@interface SCISettingsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *sections;
@property (nonatomic) BOOL reduceMargin;
@end

@implementation SCISettingsViewController

- (instancetype)initWithTitle:(NSString *)title sections:(NSArray *)sections reduceMargin:(BOOL)reduceMargin {
    self = [super init];
    if (self) {
        self.title = [title stringByReplacingOccurrencesOfString:@"PekiWare" withString:@"Hawaii"];
        
        // FILTRIRANJE: Izbacujemo Donate i View Repo
        NSMutableArray *filteredSections = [NSMutableArray new];
        for (NSDictionary *section in sections) {
            NSMutableArray *filteredRows = [NSMutableArray new];
            for (SCISetting *row in section[@"rows"]) {
                NSString *rowTitle = [row.title lowercaseString];
                if (![rowTitle containsString:@"donate"] && ![rowTitle containsString:@"view repo"]) {
                    [filteredRows addObject:row];
                }
            }
            if (filteredRows.count > 0) {
                NSMutableDictionary *newSec = [section mutableCopy];
                newSec[@"rows"] = filteredRows;
                [filteredSections addObject:newSec];
            }
        }
        self.sections = filteredSections;
        self.reduceMargin = reduceMargin;
    }
    return self;
}

- (instancetype)init {
    return [self initWithTitle:@"Hawaii Settings" sections:[SCITweakSettings sections] reduceMargin:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    // Animirani naslov na vrhu
    HawaiiAnimatedLabel *navLabel = [[HawaiiAnimatedLabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    navLabel.text = self.title;
    navLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    navLabel.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = navLabel;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.contentInset = UIEdgeInsetsMake(self.reduceMargin ? -20 : 0, 0, 0, 0);

    [self.view addSubview:self.tableView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    
    // Unikatni ID da bi animacija radila bez mešanja redova
    NSString *cellID = [NSString stringWithFormat:@"Cell-%ld-%ld", (long)indexPath.section, (long)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
        
        // Dodajemo naš animirani Label preko običnog teksta
        HawaiiAnimatedLabel *animatedLabel = [[HawaiiAnimatedLabel alloc] initWithFrame:CGRectMake(55, 11, 250, 22)];
        animatedLabel.tag = 999;
        animatedLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
        [cell.contentView addSubview:animatedLabel];
    }
    
    HawaiiAnimatedLabel *animatedLabel = (HawaiiAnimatedLabel *)[cell.contentView viewWithTag:999];
    
    // Postavljanje teksta i provera za TikTok
    NSString *cleanTitle = [row.title stringByReplacingOccurrencesOfString:@"PekiWare" withString:@"Hawaii"];
    NSString *lowerTitle = [cleanTitle lowercaseString];
    
    if ([lowerTitle containsString:@"discord"] || [lowerTitle containsString:@"community"]) {
        animatedLabel.text = @"Hawaii TikTok";
    } else {
        animatedLabel.text = cleanTitle;
    }

    // Podnaslov
    NSString *subText = row.subtitle;
    if ([subText containsString:@"SoCuul"]) subText = [subText stringByReplacingOccurrencesOfString:@"SoCuul" withString:@"Hawaii"];
    if ([lowerTitle containsString:@"discord"]) subText = @"Follow my TikTok community!";
    
    cell.detailTextLabel.text = subText;
    cell.detailTextLabel.textColor = [UIColor orangeColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];

    // Ikona
    if (row.icon != nil) {
        cell.imageView.image = [row.icon image];
        cell.imageView.tintColor = [UIColor whiteColor];
    }

    // Switch/Navigacija
    if (row.type == SCITableCellSwitch) {
        UISwitch *toggle = [UISwitch new];
        toggle.on = [[NSUserDefaults standardUserDefaults] boolForKey:row.defaultsKey];
        toggle.onTintColor = [UIColor systemGreenColor];
        objc_setAssociatedObject(toggle, rowStaticRef, row, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggle;
    } else {
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    NSString *lowerTitle = [row.title lowercaseString];
    
    // AKO JE DISCORD/COMMUNITY -> OTVORI TIKTOK
    if ([lowerTitle containsString:@"discord"] || [lowerTitle containsString:@"community"]) {
        NSURL *tiktokURL = [NSURL URLWithString:@"https://www.tiktok.com/@zivkovichhh_"]; // <--- OVDE STAVI SVOJ LINK
        [[UIApplication sharedApplication] openURL:tiktokURL options:@{} completionHandler:nil];
    } 
    else if (row.type == SCITableCellNavigation && row.navSections.count > 0) {
        UIViewController *vc = [[SCISettingsViewController alloc] initWithTitle:row.title sections:row.navSections reduceMargin:NO];
        [self.navigationController pushViewController:vc animated:YES];
    } else if (row.type == SCITableCellLink) {
        [[UIApplication sharedApplication] openURL:row.url options:@{} completionHandler:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return self.sections.count; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return [self.sections[section][@"rows"] count]; }

- (void)switchChanged:(UISwitch *)sender {
    SCISetting *row = objc_getAssociatedObject(sender, rowStaticRef);
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:row.defaultsKey];
    if (row.requiresRestart) [SCIUtils showRestartConfirmation];
}

@end
