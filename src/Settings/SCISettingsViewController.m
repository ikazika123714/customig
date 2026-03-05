#import "SCISettingsViewController.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

static char rowStaticRef[] = "row";

// --- KLASA ZA PRAVI RAINBOW TEKST (SVAKO SLOVO DRUGA BOJA) ---
@interface HawaiiRainbowView : UIView
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UILabel *label;
- (void)setText:(NSString *)text font:(UIFont *)font;
@end

@implementation HawaiiRainbowView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.gradientLayer = [CAGradientLayer layer];
        self.gradientLayer.startPoint = CGPointMake(0, 0.5);
        self.gradientLayer.endPoint = CGPointMake(1, 0.5);
        self.gradientLayer.colors = @[
            (id)[UIColor redColor].CGColor, (id)[UIColor orangeColor].CGColor,
            (id)[UIColor yellowColor].CGColor, (id)[UIColor greenColor].CGColor,
            (id)[UIColor cyanColor].CGColor, (id)[UIColor blueColor].CGColor,
            (id)[UIColor purpleColor].CGColor, (id)[UIColor redColor].CGColor
        ];
        [self.layer addSublayer:self.gradientLayer];

        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textColor = [UIColor whiteColor];
        self.gradientLayer.mask = self.label.layer;

        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"colors"];
        animation.toValue = @[
            (id)[UIColor purpleColor].CGColor, (id)[UIColor redColor].CGColor,
            (id)[UIColor orangeColor].CGColor, (id)[UIColor yellowColor].CGColor,
            (id)[UIColor greenColor].CGColor, (id)[UIColor cyanColor].CGColor,
            (id)[UIColor blueColor].CGColor, (id)[UIColor purpleColor].CGColor
        ];
        animation.duration = 3.0;
        animation.repeatCount = HUGE_VALF;
        animation.autoreverses = YES;
        [self.gradientLayer addAnimation:animation forKey:@"rainbow"];
    }
    return self;
}

- (void)setText:(NSString *)text font:(UIFont *)font {
    self.label.text = text;
    self.label.font = font;
    [self.label sizeToFit];
    CGRect frame = self.label.frame;
    self.gradientLayer.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, frame.size.width, frame.size.height);
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
        self.title = @"Hawaii Settings";
        
        NSMutableArray *filteredSections = [NSMutableArray new];
        for (NSDictionary *section in sections) {
            NSMutableArray *filteredRows = [NSMutableArray new];
            for (SCISetting *row in section[@"rows"]) {
                NSString *rt = [row.title lowercaseString];
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

        // DODAJEMO DEVELOPER I TIKTOK NA KRAJ (Samo na glavnom ekranu)
        if ([title containsString:@"Settings"]) {
            SCISetting *devRow = [SCISetting new];
            devRow.title = @"Hawaii Developer";
            devRow.subtitle = @"Hawaii";
            
            SCISetting *tkRow = [SCISetting new];
            tkRow.title = @"Hawaii TikTok";
            tkRow.subtitle = @"Join the community!";

            [filteredSections addObject:@{@"header":@"", @"rows":@[devRow, tkRow]}];
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
    
    HawaiiRainbowView *navLabel = [[HawaiiRainbowView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    [navLabel setText:self.title font:[UIFont systemFontOfSize:19 weight:UIFontWeightBold]];
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
        
        HawaiiRainbowView *rainbow = [[HawaiiRainbowView alloc] initWithFrame:CGRectMake(55, 11, 280, 24)];
        rainbow.tag = 2002;
        [cell.contentView addSubview:rainbow];
    }
    
    HawaiiRainbowView *rainbow = (HawaiiRainbowView *)[cell.contentView viewWithTag:2002];
    NSString *title = [row.title stringByReplacingOccurrencesOfString:@"PekiWare" withString:@"Hawaii"];
    [rainbow setText:title font:[UIFont systemFontOfSize:18 weight:UIFontWeightBold]];

    cell.detailTextLabel.text = row.subtitle;
    cell.detailTextLabel.textColor = [UIColor orangeColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
    cell.textLabel.text = @""; 

    if ([row.title containsString:@"Developer"]) {
        cell.imageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
    } else if ([row.title containsString:@"TikTok"]) {
        cell.imageView.image = [UIImage systemImageNamed:@"video.fill"];
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
        NSURL *url = [NSURL URLWithString:@"https://www.tiktok.com/@zivkovichhh_"]; // <-- STAVI LINK
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

@end
