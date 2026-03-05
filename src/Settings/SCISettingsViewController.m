#import "SCISettingsViewController.h"
#import <objc/runtime.h>

static char rowStaticRef[] = "row";

@interface SCISettingsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *sections;
@property (nonatomic) BOOL reduceMargin;
@property (nonatomic, strong) NSTimer *rainbowTimer;
@property (nonatomic, assign) CGFloat currentHue;
@end

@implementation SCISettingsViewController

- (instancetype)initWithTitle:(NSString *)title sections:(NSArray *)sections reduceMargin:(BOOL)reduceMargin {
    self = [super init];
    if (self) {
        // Branding: PekiWare -> Hawaii
        self.title = [title stringByReplacingOccurrencesOfString:@"PekiWare" withString:@"Hawaii"];
        
        // FILTRIRANJE: Sklanjamo Donate i View Repo
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
        self.currentHue = 0;
    }
    return self;
}

- (instancetype)init {
    return [self initWithTitle:@"Hawaii Settings" sections:[SCITweakSettings sections] reduceMargin:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    // TAJMER ZA ANIMACIJU BOJA (0.05s za glatko kretanje)
    self.rainbowTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(animateColors) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.rainbowTimer forMode:NSRunLoopCommonModes];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.contentInset = UIEdgeInsetsMake(self.reduceMargin ? -25 : 0, 0, 0, 0);

    [self.view addSubview:self.tableView];
}

// Glavna funkcija koja vrti dugu
- (void)animateColors {
    self.currentHue += 0.005; 
    if (self.currentHue > 1.0) self.currentHue = 0;
    
    UIColor *animatedColor = [UIColor colorWithHue:self.currentHue saturation:0.9 brightness:1.0 alpha:1.0];
    
    // Animacija naslova na vrhu
    UILabel *titleLabel = (UILabel *)self.navigationItem.titleView;
    if (![titleLabel isKindOfClass:[UILabel class]]) {
        titleLabel = [[UILabel alloc] init];
        titleLabel.font = [UIFont systemFontOfSize:19 weight:UIFontWeightBold];
        self.navigationItem.titleView = titleLabel;
    }
    titleLabel.text = self.title;
    titleLabel.textColor = animatedColor;
    [titleLabel sizeToFit];

    // Animacija svih stavki u listi
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        cell.textLabel.textColor = animatedColor;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    
    static NSString *cellID = @"HawaiiFinalCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.09 alpha:1.0]; // Tamnija pozadina kao na videu
    }
    
    // Branding teksta
    NSString *displayTitle = [row.title stringByReplacingOccurrencesOfString:@"PekiWare" withString:@"Hawaii"];
    NSString *lowerTitle = [displayTitle lowercaseString];
    
    if ([lowerTitle containsString:@"discord"] || [lowerTitle containsString:@"community"]) {
        cell.textLabel.text = @"Hawaii TikTok";
    } else {
        cell.textLabel.text = displayTitle;
    }

    // PODEŠAVANJE FONTA (Krupnije i deblje)
    cell.textLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    cell.textLabel.textColor = [UIColor colorWithHue:self.currentHue saturation:0.9 brightness:1.0 alpha:1.0];

    // Podnaslov (Branding i TikTok)
    NSString *subText = row.subtitle;
    if ([subText containsString:@"SoCuul"]) subText = [subText stringByReplacingOccurrencesOfString:@"SoCuul" withString:@"Hawaii"];
    if ([lowerTitle containsString:@"discord"]) subText = @"Join my TikTok community!";
    
    cell.detailTextLabel.text = subText;
    cell.detailTextLabel.textColor = [UIColor orangeColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];

    // Ikona
    if (row.icon != nil) {
        cell.imageView.image = [row.icon image];
        cell.imageView.tintColor = [UIColor whiteColor];
    } else {
        cell.imageView.image = nil;
    }

    // Kontrole (Switch)
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
    
    // TIKTOK LINK - Ovde upiši svoj link!
    if ([lowerTitle containsString:@"discord"] || [lowerTitle containsString:@"community"]) {
        NSURL *url = [NSURL URLWithString:@"https://www.tiktok.com/@TVOJ_PROFIL"]; 
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.rainbowTimer invalidate]; // Čistimo tajmer da ne troši bateriju u pozadini
}

@end
