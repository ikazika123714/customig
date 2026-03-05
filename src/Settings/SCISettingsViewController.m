#import "SCISettingsViewController.h"
#import "TweakSettings.h" // Promenjeno sa SCITweakSettings.h na TweakSettings.h
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

// Ako tvoj projekt nema SCIUtils.h, slobodno zakomentariši donju liniju
// #import "SCIUtils.h" 

static char rowStaticRef[] = "row";

// --- KLASA ZA DINAMIČKI GRADIENT TEKST ---
@interface HawaiiGradientLabel : UIView
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
- (void)setText:(NSString *)text;
- (void)setFont:(UIFont *)font;
@end

@implementation HawaiiGradientLabel
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _textLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _textLabel.textAlignment = NSTextAlignmentLeft;
        
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.startPoint = CGPointMake(0, 0.5);
        _gradientLayer.endPoint = CGPointMake(1, 0.5);
        _gradientLayer.colors = @[
            (id)[UIColor redColor].CGColor,
            (id)[UIColor orangeColor].CGColor,
            (id)[UIColor yellowColor].CGColor,
            (id)[UIColor greenColor].CGColor,
            (id)[UIColor cyanColor].CGColor,
            (id)[UIColor blueColor].CGColor,
            (id)[UIColor purpleColor].CGColor,
            (id)[UIColor redColor].CGColor
        ];
        
        self.layer.addSublayer(_gradientLayer);
        self.maskView = _textLabel;
        [self startAnimation];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _gradientLayer.frame = CGRectMake(-self.bounds.size.width, 0, self.bounds.size.width * 3, self.bounds.size.height);
    _textLabel.frame = self.bounds;
}

- (void)setText:(NSString *)text { _textLabel.text = text; }
- (void)setFont:(UIFont *)font { _textLabel.font = font; }

- (void)startAnimation {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    animation.fromValue = @(0);
    animation.toValue = @(self.bounds.size.width);
    animation.duration = 5.0; 
    animation.repeatCount = HUGE_VALF;
    [_gradientLayer addAnimation:animation forKey:@"rainbowShift"];
}
@end

// --- GLAVNI KONTROLER ---
@implementation SCISettingsViewController

- (instancetype)initWithTitle:(NSString *)title sections:(NSArray *)sections reduceMargin:(BOOL)reduceMargin {
    self = [super init];
    if (self) {
        self.title = @"HawaiiWare Settings";
        
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
    }
    return self;
}

// Inicijalizacija sa ispravnom klasom TweakSettings
- (instancetype)init {
    return [self initWithTitle:@"HawaiiWare Settings" sections:[TweakSettings sections] reduceMargin:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    HawaiiGradientLabel *navLabel = [[HawaiiGradientLabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    [navLabel setText:@"HawaiiWare Settings"];
    [navLabel setFont:[UIFont systemFontOfSize:19 weight:UIFontWeightBold]];
    self.navigationItem.titleView = navLabel;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.contentInset = UIEdgeInsetsMake(-20, 0, 0, 0);

    [self.view addSubview:self.tableView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    NSString *cellID = [NSString stringWithFormat:@"HawaiiCell-%ld-%ld", (long)indexPath.section, (long)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        HawaiiGradientLabel *gLabel = [[HawaiiGradientLabel alloc] initWithFrame:CGRectMake(54, 10, 250, 25)];
        gLabel.tag = 1001;
        [cell.contentView addSubview:gLabel];
    }
    
    HawaiiGradientLabel *gLabel = (HawaiiGradientLabel *)[cell.contentView viewWithTag:1001];
    NSString *titleText = [row.title stringByReplacingOccurrencesOfString:@"PekiWare" withString:@"HawaiiWare"];
    titleText = [titleText stringByReplacingOccurrencesOfString:@"Peki" withString:@"Hawaii"];
    
    if ([titleText.lowercaseString containsString:@"discord"] || [titleText.lowercaseString containsString:@"community"]) {
        [gLabel setText:@"Hawaii TikTok"];
        cell.detailTextLabel.text = @"Join our TikTok community!";
    } else {
        [gLabel setText:titleText];
        cell.detailTextLabel.text = row.subtitle;
    }

    [gLabel setFont:[UIFont systemFontOfSize:17 weight:UIFontWeightBold]];
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
    NSString *lowerTitle = [row.title lowercaseString];
    
    if ([lowerTitle containsString:@"discord"] || [lowerTitle containsString:@"community"]) {
        NSURL *url = [NSURL URLWithString:@"https://www.tiktok.com/@zivkovichhh_"]; 
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    } 
    else if (row.type == SCITableCellNavigation && row.navSections.count > 0) {
        SCISettingsViewController *vc = [[SCISettingsViewController alloc] initWithTitle:row.title sections:row.navSections reduceMargin:NO];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return self.sections.count; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return [self.sections[section][@"rows"] count]; }

- (void)switchChanged:(UISwitch *)sender {
    SCISetting *row = objc_getAssociatedObject(sender, rowStaticRef);
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:row.defaultsKey];
    // Ako izbacuje error za SCIUtils, samo obriši donju liniju:
    // [SCIUtils showRestartConfirmation];
}
@end
