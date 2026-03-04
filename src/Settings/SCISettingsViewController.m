#import "SCISettingsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static char rowStaticRef[] = "row";

// --- SPECIJALNA KLASA ZA DUGINU ANIMACIJU ---
@interface PekiRainbowLabel : UILabel
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
- (void)startRainbowAnimation;
@end

@implementation PekiRainbowLabel
- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = CGRectMake(-self.bounds.size.width, 0, 3 * self.bounds.size.width, self.bounds.size.height);
}

- (void)startRainbowAnimation {
    if (self.gradientLayer) return;

    self.gradientLayer = [CAGradientLayer layer];
    // Niz duginih boja
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
    self.gradientLayer.startPoint = CGPointMake(0, 0.5);
    self.gradientLayer.endPoint = CGPointMake(1, 0.5);
    
    // Pravimo da gradient bude širi od labela da bi mogao da se pomera
    self.gradientLayer.frame = CGRectMake(-self.bounds.size.width, 0, 3 * self.bounds.size.width, self.bounds.size.height);

    // Animacija pomeranja (pomeramo gradient s leva na desno)
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    animation.byValue = @(self.bounds.size.width * 2);
    animation.duration = 3.0; // Brzina pomeranja boja
    animation.repeatCount = HUGE_VALF;
    animation.removedOnCompletion = NO;
    [self.gradientLayer addAnimation:animation forKey:@"rainbow"];

    // Postavljamo gradient kao masku - boje se vide samo na slovima
    self.layer.mask = self.gradientLayer;
    self.backgroundColor = [UIColor whiteColor]; // Osnova za masku
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
        self.sections = sections;
        self.reduceMargin = reduceMargin;
        self.title = @"PekiWare Settings";
    }
    return self;
}

- (instancetype)init {
    return [self initWithTitle:@"PekiWare Settings" sections:[SCITweakSettings sections] reduceMargin:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];

    // Postavljanje animiranog naslova na vrhu
    PekiRainbowLabel *navLabel = [[PekiRainbowLabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    navLabel.text = @"PekiWare Settings";
    navLabel.font = [UIFont systemFontOfSize:19 weight:UIFontWeightBold];
    navLabel.textAlignment = NSTextAlignmentCenter;
    [navLabel startRainbowAnimation];
    self.navigationItem.titleView = navLabel;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.contentInset = UIEdgeInsetsMake(self.reduceMargin ? -30 : -10, 0, 0, 0);

    [self.view addSubview:self.tableView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    
    cell.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    // Kreiranje duginih slova za svaku stavku
    PekiRainbowLabel *rainbowLabel = [[PekiRainbowLabel alloc] initWithFrame:CGRectMake(55, 12, 250, 22)];
    rainbowLabel.text = row.title;
    rainbowLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    [rainbowLabel startRainbowAnimation];
    [cell.contentView addSubview:rainbowLabel];

    // Ikona (Bela ikona, slova su duga)
    if (row.icon != nil) {
        UIImageView *iconView = [[UIImageView alloc] initWithImage:[row.icon image]];
        iconView.tintColor = [UIColor whiteColor];
        iconView.frame = CGRectMake(15, 11, 28, 28);
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        [cell.contentView addSubview:iconView];
    }

    // Subtitle (Narandžasta boja)
    if (row.subtitle.length) {
        UILabel *subLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 32, 250, 15)];
        subLabel.text = row.subtitle;
        subLabel.font = [UIFont systemFontOfSize:12];
        subLabel.textColor = [UIColor orangeColor];
        [cell.contentView addSubview:subLabel];
        
        // Pomera glavni naslov malo gore ako ima podnaslova
        CGRect frame = rainbowLabel.frame;
        frame.origin.y = 8;
        rainbowLabel.frame = frame;
    }

    // Kontrole (Switch, Stepper...)
    if (row.type == SCITableCellSwitch) {
        UISwitch *toggle = [UISwitch new];
        toggle.on = [[NSUserDefaults standardUserDefaults] boolForKey:row.defaultsKey];
        toggle.onTintColor = [UIColor systemGreenColor];
        objc_setAssociatedObject(toggle, rowStaticRef, row, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggle;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return self.sections.count; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return [self.sections[section][@"rows"] count]; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return self.sections[section][@"header"]; }
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section { return self.sections[section][@"footer"]; }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    if (row.type == SCITableCellNavigation && row.navSections.count > 0) {
        UIViewController *vc = [[SCISettingsViewController alloc] initWithTitle:row.title sections:row.navSections reduceMargin:NO];
        [self.navigationController pushViewController:vc animated:YES];
    } else if (row.type == SCITableCellLink) {
        [[UIApplication sharedApplication] openURL:row.url options:@{} completionHandler:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)switchChanged:(UISwitch *)sender {
    SCISetting *row = objc_getAssociatedObject(sender, rowStaticRef);
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:row.defaultsKey];
    if (row.requiresRestart) [SCIUtils showRestartConfirmation];
}

@end
