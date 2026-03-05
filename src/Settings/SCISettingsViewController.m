#import "SCISettingsViewController.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

static char rowStaticRef[] = "row";

// --- SPECIJALNA KLASA ZA GRADIENT TEKST (SVAKO SLOVO DRUGA BOJA) ---
@interface HawaiiGradientLabel : UILabel
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@end

@implementation HawaiiGradientLabel
- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.gradientLayer) {
        self.gradientLayer = [CAGradientLayer layer];
        self.gradientLayer.startPoint = CGPointMake(0, 0.5);
        self.gradientLayer.endPoint = CGPointMake(1, 0.5);
        self.gradientLayer.colors = @[
            (id)[UIColor redColor].CGColor,
            (id)[UIColor orangeColor].CGColor,
            (id)[UIColor yellowColor].CGColor,
            (id)[UIColor greenColor].CGColor,
            (id)[UIColor cyanColor].CGColor,
            (id)[UIColor blueColor].CGColor,
            (id)[UIColor purpleColor].CGColor,
            (id)[UIColor redColor].CGColor
        ];
        self.layer.mask = self.gradientLayer;
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"colors"];
        animation.toValue = @[
            (id)[UIColor purpleColor].CGColor,
            (id)[UIColor redColor].CGColor,
            (id)[UIColor orangeColor].CGColor,
            (id)[UIColor yellowColor].CGColor,
            (id)[UIColor greenColor].CGColor,
            (id)[UIColor cyanColor].CGColor,
            (id)[UIColor blueColor].CGColor,
            (id)[UIColor purpleColor].CGColor
        ];
        animation.duration = 2.5; // Brzina prelivanja
        animation.repeatCount = HUGE_VALF;
        animation.autoreverses = YES;
        [self.gradientLayer addAnimation:animation forKey:@"rainbow"];
    }
    self.gradientLayer.frame = self.bounds;
}
@end

// --- GLAVNI VIEW CONTROLLER ---
@interface SCISettingsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *sections;
@property (nonatomic) BOOL reduceMargin;
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
                // Izbacujemo nepotrebne stvari ako postoje
                if (![rt containsString:@"donate"] && ![rt containsString:@"view repo"] && ![rt containsString:@"developer"] && ![rt containsString:@"discord"]) {
                    [filteredRows addObject:row];
                }
            }
            if (filteredRows.count > 0) {
                NSMutableDictionary *newSec = [section mutableCopy];
                newSec[@"rows"] = filteredRows;
                [filteredSections addObject:newSec];
            }
        }

        // --- RUČNO DODAJEMO HAWAII DEVELOPER I TIKTOK NA KRAJ ---
        // Samo na početnom ekranu (Hawaii Settings)
        if ([self.title isEqualToString:@"Hawaii Settings"]) {
            SCISetting *devRow = [SCISetting new];
            devRow.title = @"Hawaii Developer";
            devRow.subtitle = @"Hawaii";
            
            SCISetting *tkRow = [SCISetting new];
            tkRow.title = @"Hawaii TikTok";
            tkRow.subtitle = @"Join the community!";

            NSDictionary *customSection = @{
                @"header": @"",
                @"rows": @[devRow, tkRow]
            };
            [filteredSections addObject:customSection];
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
    
    HawaiiGradientLabel *navLabel = [[HawaiiGradientLabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    navLabel.text = self.title;
    navLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    navLabel.textAlignment = NSTextAlignmentCenter;
    navLabel.backgroundColor = [UIColor whiteColor]; 
    self.navigationItem.titleView = navLabel;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.contentInset = UIEdgeInsetsMake(-30, 0, 0, 0);

    [self.view addSubview:self.tableView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    
    NSString *cellID = [NSString stringWithFormat:@"HawaiiCell-%ld-%ld", (long)indexPath.section, (long)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
        
        HawaiiGradientLabel *gLabel = [[HawaiiGradientLabel alloc] initWithFrame:CGRectMake(55, 11, 280, 24)];
        gLabel.tag = 1001;
        gLabel.backgroundColor = [UIColor whiteColor];
        [cell.contentView addSubview:gLabel];
    }
    
    HawaiiGradientLabel *gLabel = (HawaiiGradientLabel *)[cell.contentView viewWithTag:1001];
    gLabel.text = [row.title stringByReplacingOccurrencesOfString:@"PekiWare" withString:@"Hawaii"];
    gLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];

    cell.detailTextLabel.text = row.subtitle;
    cell.detailTextLabel.textColor = [UIColor orangeColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
    cell.textLabel.text = @""; 

    // Ikone za ručno dodate stavke
    if ([row.title containsString:@"Developer"]) {
        cell.imageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
    } else if ([row.title containsString:@"TikTok"]) {
        cell.imageView.image = [UIImage systemImageNamed:@"bubble.left.and.bubble.right.fill"];
    } else if (row.icon != nil) {
        cell.imageView.image = [row.icon image];
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

@end
