#import "SCISettingsViewController.h"
#import "TweakSettings.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

static char rowStaticRef[] = "row";

// --- KLASA ZA GRADIENT TEKST BEZ BELIH KOCKI ---
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
        self.gradientLayer.frame = CGRectMake(0, 0, self.bounds.size.width * 2, self.bounds.size.height);
        
        // Animacija
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
        animation.fromValue = @(self.bounds.size.width);
        animation.toValue = @(0);
        animation.duration = 4.5;
        animation.repeatCount = HUGE_VALF;
        [self.gradientLayer addAnimation:animation forKey:@"rainbow"];
        
        // KLJUČ: Koristimo sliku gradijenta kao boju teksta
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
        [self.gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        self.textColor = [UIColor colorWithPatternImage:gradientImage];
    }
}
@end

// --- GLAVNI KONTROLER ---
@implementation SCISettingsViewController

- (instancetype)initWithTitle:(NSString *)title sections:(NSArray *)sections reduceMargin:(BOOL)reduceMargin {
    self = [super init];
    if (self) {
        self.title = @"HawaiiWare";
        
        NSMutableArray *filteredSections = [NSMutableArray new];
        for (NSDictionary *section in sections) {
            NSString *secTitle = [section[@"title"] lowercaseString] ?: @"";
            
            // SKLANJAMO CREDITS I DONATE SEKCIJE POTPUNO
            if ([secTitle containsString:@"credits"] || [secTitle containsString:@"donate"] || [secTitle containsString:@"support"]) {
                continue; 
            }
            
            NSMutableArray *filteredRows = [NSMutableArray new];
            for (SCISetting *row in section[@"rows"]) {
                NSString *rt = [row.title lowercaseString];
                
                // Sklanjamo pojedinačne redove koji ne trebaju
                if (![rt containsString:@"donate"] && ![rt containsString:@"view repo"] && ![rt containsString:@"socuul"]) {
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
    return [self initWithTitle:@"HawaiiWare" sections:[TweakSettings sections] reduceMargin:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    // Naslov u baru
    HawaiiGradientLabel *navLabel = [[HawaiiGradientLabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    navLabel.text = @"HawaiiWare Settings";
    navLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    navLabel.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = navLabel;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.contentInset = UIEdgeInsetsMake(-25, 0, 0, 0);

    [self.view addSubview:self.tableView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    NSString *cellID = [NSString stringWithFormat:@"HawaiiCell-%ld-%ld", (long)indexPath.section, (long)indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
        
        HawaiiGradientLabel *gLabel = [[HawaiiGradientLabel alloc] initWithFrame:CGRectMake(55, 10, 280, 24)];
        gLabel.tag = 1001;
        [cell.contentView addSubview:gLabel];
    }
    
    HawaiiGradientLabel *gLabel = (HawaiiGradientLabel *)[cell.contentView viewWithTag:1001];
    
    // Tekst i rebranding
    NSString *titleText = [row.title stringByReplacingOccurrencesOfString:@"PekiWare" withString:@"HawaiiWare"];
    titleText = [titleText stringByReplacingOccurrencesOfString:@"Peki" withString:@"Hawaii"];
    
    if ([titleText.lowercaseString containsString:@"discord"] || [titleText.lowercaseString containsString:@"community"]) {
        gLabel.text = @"Hawaii TikTok";
        cell.detailTextLabel.text = @"Join our TikTok community!";
    } else {
        gLabel.text = titleText;
        cell.detailTextLabel.text = row.subtitle;
    }

    gLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    cell.detailTextLabel.textColor = [UIColor orangeColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:11];

    if (row.icon != nil) {
        cell.imageView.image = [row.icon image];
        cell.imageView.tintColor = [UIColor whiteColor];
    }

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

    cell.textLabel.text = @""; 
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    if ([row.title.lowercaseString containsString:@"discord"] || [row.title.lowercaseString containsString:@"community"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.tiktok.com/@zivkovichhh_"] options:@{} completionHandler:nil];
    } else if (row.type == SCITableCellNavigation && row.navSections.count > 0) {
        SCISettingsViewController *vc = [[SCISettingsViewController alloc] initWithTitle:row.title sections:row.navSections reduceMargin:NO];
        [self.navigationController pushViewController:vc animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return self.sections.count; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return [self.sections[section][@"rows"] count]; }

- (void)switchChanged:(UISwitch *)sender {
    SCISetting *row = objc_getAssociatedObject(sender, rowStaticRef);
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:row.defaultsKey];
}
@end
