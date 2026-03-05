#import "SCISettingsViewController.h"
#import <objc/runtime.h>

static char rowStaticRef[] = "row";

@interface SCISettingsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *sections;
@property (nonatomic) BOOL reduceMargin;
@property (nonatomic, strong) NSTimer *globalTimer;
@property (nonatomic, assign) CGFloat hue;
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
                NSString *rt = [row.title lowercaseString];
                if (![rt containsString:@"donate"] && ![rt containsString:@"view repo"]) {
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
        self.hue = 0;
    }
    return self;
}

- (instancetype)init {
    return [self initWithTitle:@"Hawaii Settings" sections:[SCITweakSettings sections] reduceMargin:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    // Tajmer koji menja boju svim vidljivim ćelijama istovremeno (Smanjena brzina na 0.1s)
    self.globalTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateRainbow) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.globalTimer forMode:NSRunLoopCommonModes];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    // Smanjujemo gornju marginu da naslov bude bliže vrhu
    self.tableView.contentInset = UIEdgeInsetsMake(self.reduceMargin ? -25 : 0, 0, 0, 0);

    [self.view addSubview:self.tableView];
}

// Funkcija koja glatko menja boju
- (void)updateRainbow {
    self.hue += 0.005; // Što je manji broj, duga je sporija
    if (self.hue > 1.0) self.hue = 0;
    
    UIColor *rainbowColor = [UIColor colorWithHue:self.hue saturation:0.9 brightness:1.0 alpha:1.0];
    
    // Menjamo boju naslova u navigaciji
    UILabel *titleLabel = (UILabel *)self.navigationItem.titleView;
    if (!titleLabel || ![titleLabel isKindOfClass:[UILabel class]]) {
        titleLabel = [[UILabel alloc] init];
        titleLabel.font = [UIFont systemFontOfSize:19 weight:UIFontWeightBold];
        self.navigationItem.titleView = titleLabel;
    }
    titleLabel.text = self.title;
    titleLabel.textColor = rainbowColor;
    [titleLabel sizeToFit];

    // Menjamo boju teksta u svim vidljivim ćelijama
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        cell.textLabel.textColor = rainbowColor;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    
    static NSString *cellID = @"HawaiiStableCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    
    cell.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
    
    // Čišćenje i postavljanje teksta (PekiWare -> Hawaii)
    NSString *cleanTitle = [row.title stringByReplacingOccurrencesOfString:@"PekiWare" withString:@"Hawaii"];
    NSString *lowerTitle = [cleanTitle lowercaseString];
    
    if ([lowerTitle containsString:@"discord"] || [lowerTitle containsString:@"community"]) {
        cell.textLabel.text = @"Hawaii TikTok";
    } else {
        cell.textLabel.text = cleanTitle;
    }

    // Font i Boja (Koristimo sistemski textLabel da izbegnemo bagove)
    cell.textLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    cell.textLabel.textColor = [UIColor colorWithHue:self.hue saturation:0.9 brightness:1.0 alpha:1.0];

    // Podnaslov
    NSString *subText = row.subtitle;
    if ([subText containsString:@"SoCuul"]) subText = [subText stringByReplacingOccurrencesOfString:@"SoCuul" withString:@"Hawaii"];
    if ([lowerTitle containsString:@"discord"]) subText = @"Visit my TikTok profile!";
    
    cell.detailTextLabel.text = subText;
    cell.detailTextLabel.textColor = [UIColor orangeColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13];

    // Ikona
    if (row.icon != nil) {
        cell.imageView.image = [row.icon image];
        cell.imageView.tintColor = [UIColor whiteColor];
    } else {
        cell.imageView.image = nil;
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
    
    // TIKTOK LINK
    if ([lowerTitle containsString:@"discord"] || [lowerTitle containsString:@"community"]) {
        NSURL *url = [NSURL URLWithString:@"https://www.tiktok.com/@TVOJ_USER_OVDE"]; // <-- OVDE STAVI SVOJ LINK
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
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

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.globalTimer invalidate]; // Zaustavi tajmer kad se izađe iz menija
}

@end
