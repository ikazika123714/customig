#import "SCISettingsViewController.h"
#import "SCISetting.h"
#import "SCITweakSettings.h"
#import "SCIUtils.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

static char rowStaticRef[] = "row";

@interface SCISettingsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *sections;
@property (nonatomic) BOOL reduceMargin;
@property (nonatomic, strong) NSTimer *rainbowTimer;
@property (nonatomic, assign) CGFloat hue;
@end

@implementation SCISettingsViewController

- (instancetype)initWithTitle:(NSString *)title sections:(NSArray *)sections reduceMargin:(BOOL)reduceMargin {
    self = [super init];
    if (self) {
        self.title = @"Hawaii Settings";
        
        NSMutableArray *filteredSections = [NSMutableArray new];
        for (NSDictionary *section in sections) {
            NSMutableArray *filteredRows = [NSMutableArray new];
            for (SCISetting *row in section[@"rows"]) {
                NSString *rt = [row.title lowercaseString];
                // Sklanjamo nepotrebno
                if (![rt containsString:@"donate"] && ![rt containsString:@"view repo"] && 
                    ![rt containsString:@"developer"] && ![rt containsString:@"discord"]) {
                    [filteredRows addObject:row];
                }
            }
            if (filteredRows.count > 0) {
                NSMutableDictionary *newSec = [section mutableCopy];
                newSec[@"rows"] = filteredRows;
                [filteredSections addObject:newSec];
            }
        }

        // DODAJEMO DEVELOPER I TIKTOK NA KRAJ
        if ([title containsString:@"Settings"] || [title isEqualToString:@"Hawaii Settings"]) {
            SCISetting *devRow = [SCISetting new];
            devRow.title = @"Hawaii Developer";
            devRow.subtitle = @"Hawaii";
            
            SCISetting *tkRow = [SCISetting new];
            tkRow.title = @"Hawaii TikTok";
            tkRow.subtitle = @"Visit my TikTok profile!";

            [filteredSections addObject:@{@"header":@"", @"rows":@[devRow, tkRow]}];
        }

        self.sections = [filteredSections copy];
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
    
    // TAJMER ZA ANIMACIJU (Mnogo sigurnije od maski koje su pravile bele blokove)
    self.rainbowTimer = [NSTimer scheduledTimerWithTimeInterval:0.08 target:self selector:@selector(updateRainbow) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.rainbowTimer forMode:NSRunLoopCommonModes];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.contentInset = UIEdgeInsetsMake(-25, 0, 0, 0);
    [self.view addSubview:self.tableView];
}

- (void)updateRainbow {
    self.hue += 0.01;
    if (self.hue > 1.0) self.hue = 0;
    UIColor *color = [UIColor colorWithHue:self.hue saturation:0.9 brightness:1.0 alpha:1.0];
    
    // Menjamo boju naslova
    UILabel *titleLabel = (UILabel *)self.navigationItem.titleView;
    if (!titleLabel || ![titleLabel isKindOfClass:[UILabel class]]) {
        titleLabel = [[UILabel alloc] init];
        titleLabel.font = [UIFont systemFontOfSize:19 weight:UIFontWeightBold];
        self.navigationItem.titleView = titleLabel;
    }
    titleLabel.text = self.title;
    titleLabel.textColor = color;
    [titleLabel sizeToFit];

    // Menjamo boju svim vidljivim ćelijama
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        cell.textLabel.textColor = color;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    static NSString *cellID = @"HawaiiStableCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
    }
    
    // Tekst
    NSString *cleanTitle = [row.title stringByReplacingOccurrencesOfString:@"PekiWare" withString:@"Hawaii"];
    cell.textLabel.text = cleanTitle;
    cell.textLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    cell.textLabel.textColor = [UIColor colorWithHue:self.hue saturation:0.9 brightness:1.0 alpha:1.0];

    // Podnaslov
    cell.detailTextLabel.text = row.subtitle;
    cell.detailTextLabel.textColor = [UIColor orangeColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13];

    // Ikone (Koristimo tvoj originalni row.icon ako ga ima)
    if (row.icon != nil) {
        cell.imageView.image = [row.icon image];
    } else {
        cell.imageView.image = nil;
    }
    cell.imageView.tintColor = [UIColor whiteColor];

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
    if ([row.title containsString:@"TikTok"]) {
        // --- OVDE STAVI SVOJ TIKTOK LINK ---
        NSURL *url = [NSURL URLWithString:@"https://www.tiktok.com/@zivkovichhh_"]; 
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    } else if (row.type == SCITableCellNavigation && row.navSections.count > 0) {
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
    [self.rainbowTimer invalidate];
}

@end
