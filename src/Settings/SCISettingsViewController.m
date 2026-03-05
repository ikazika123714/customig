#import "SCISettingsViewController.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

static char rowStaticRef[] = "row";

// --- SPECIJALNA KLASA ZA GRADIENT TEKST (DUGA KROZ SLOVA) ---
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
        animation.duration = 3.0;
        animation.repeatCount = HUGE_VALF;
        animation.autoreverses = YES;
        [self.gradientLayer addAnimation:animation forKey:@"rainbow"];
    }
    self.gradientLayer.frame = self.bounds;
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
                // Sklanjamo nepotrebno
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
    }
    return self;
}

- (instancetype)init {
    return [self initWithTitle:@"Hawaii Settings" sections:[SCITweakSettings sections] reduceMargin:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    // Gradient Naslov na vrhu
    HawaiiGradientLabel *navLabel = [[HawaiiGradientLabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    navLabel.text = self.title;
    navLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    navLabel.textAlignment = NSTextAlignmentCenter;
    navLabel.backgroundColor = [UIColor whiteColor]; // Neophodno za masku
    self.navigationItem.titleView = navLabel;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.contentInset = UIEdgeInsetsMake(self.reduceMargin ? -30 : 0, 0, 0, 0);

    [self.view addSubview:self.tableView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    
    // Unikatni ID da ne bi bilo preklapanja teksta
    NSString *cellID = [NSString stringWithFormat:@"HawaiiCell-%ld-%ld", (long)indexPath.section, (long)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
        
        // Pravimo naš gradient label
        HawaiiGradientLabel *gLabel = [[HawaiiGradientLabel alloc] initWithFrame:CGRectMake(55, 11, 280, 24)];
        gLabel.tag = 1001;
        gLabel.backgroundColor = [UIColor whiteColor];
        [cell.contentView addSubview:gLabel];
    }
    
    HawaiiGradientLabel *gLabel = (HawaiiGradientLabel *)[cell.contentView viewWithTag:1001];
    
    // Obrada teksta PekiWare -> Hawaii
    NSString *titleText = [row.title stringByReplacingOccurrencesOfString:@"PekiWare" withString:@"Hawaii"];
    titleText = [titleText stringByReplacingOccurrencesOfString:@"Peki" withString:@"Hawaii"];
    NSString *lowerTitle = [titleText lowercaseString];

    if ([lowerTitle containsString:@"discord"] || [lowerTitle containsString:@"community"]) {
        gLabel.text = @"Hawaii TikTok";
    } else {
        gLabel.text = titleText;
    }

    // Podesi font da bude krupan i ujednačen
    gLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];

    // Podnaslov (SoCuul -> Hawaii)
    NSString *subText = row.subtitle;
    if ([subText containsString:@"SoCuul"]) subText = [subText stringByReplacingOccurrencesOfString:@"SoCuul" withString:@"Hawaii"];
    if ([lowerTitle containsString:@"discord"]) subText = @"Join my TikTok community!";
    
    cell.detailTextLabel.text = subText;
    cell.detailTextLabel.textColor = [UIColor orangeColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];

    // Ikona (Bela)
    if (row.icon != nil) {
        cell.imageView.image = [row.icon image];
        cell.imageView.tintColor = [UIColor whiteColor];
    }

    // Switch kontrole
    if (row.type == SCITableCellSwitch) {
        UISwitch *toggle = [UISwitch new];
        toggle.on = [[NSUserDefaults standardUserDefaults] boolForKey:row.defaultsKey];
        toggle.onTintColor = [UIColor systemGreenColor];
        objc_setAssociatedObject(toggle, rowStaticRef, row, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggle;
        
        // Pomeri label malo ulevo ako ima switch
        CGRect frame = gLabel.frame;
        frame.origin.y = (subText.length > 0) ? 8 : 11;
        gLabel.frame = frame;
    } else {
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    // Sakrij originalni label da se ne bi preklapao
    cell.textLabel.text = @""; 

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    NSString *lowerTitle = [row.title lowercaseString];
    
    if ([lowerTitle containsString:@"discord"] || [lowerTitle containsString:@"community"]) {
        NSURL *url = [NSURL URLWithString:@"https://www.tiktok.com/@TVOJ_PROFIL"]; // ZAMENI LINK
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
