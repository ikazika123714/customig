#import "SCISettingsViewController.h"
#import <objc/runtime.h>

static char rowStaticRef[] = "row";

@interface SCISettingsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *sections;
@property (nonatomic) BOOL reduceMargin;
@end

@implementation SCISettingsViewController

// Pomoćna funkcija za boje (Dodat Zika umesto Developer)
- (UIColor *)colorForTitle:(NSString *)title {
    NSString *t = [title lowercaseString];
    if ([t containsString:@"general"]) return [UIColor systemYellowColor];
    if ([t containsString:@"feed"]) return [UIColor systemGreenColor];
    if ([t containsString:@"reels"]) return [UIColor colorWithRed:0.40 green:0.95 blue:0.40 alpha:1.0];
    if ([t containsString:@"saving"]) return [UIColor colorWithRed:0.30 green:0.85 blue:0.70 alpha:1.0];
    if ([t containsString:@"stories"]) return [UIColor colorWithRed:0.25 green:0.75 blue:0.90 alpha:1.0];
    if ([t containsString:@"navigation"]) return [UIColor colorWithRed:0.20 green:0.50 blue:1.00 alpha:1.0];
    if ([t containsString:@"confirm"]) return [UIColor colorWithRed:0.30 green:0.30 blue:1.00 alpha:1.0];
    if ([t containsString:@"debug"]) return [UIColor systemPurpleColor];
    if ([t containsString:@"zika"]) return [UIColor systemPinkColor]; // Boja za tebe
    if ([t containsString:@"discord"]) return [UIColor systemRedColor];
    
    return [UIColor whiteColor]; 
}

- (instancetype)initWithTitle:(NSString *)title sections:(NSArray *)sections reduceMargin:(BOOL)reduceMargin {
    self = [super init];
    if (self) {
        // MENJANJE NASLOVA NA ZIKAWARE
        NSString *newTitle = [title stringByReplacingOccurrencesOfString:@"PekiWare" withString:@"ZikaWare"];
        self.title = newTitle;
        
        NSMutableArray *filteredSections = [NSMutableArray new];
        
        for (NSDictionary *section in sections) {
            NSMutableArray *filteredRows = [NSMutableArray new];
            
            for (SCISetting *row in section[@"rows"]) {
                NSString *rt = [row.title lowercaseString];
                
                // 1. IZBACIVANJE DONATE I VIEW REPO
                if ([rt containsString:@"donate"] || [rt containsString:@"view repo"] || [rt containsString:@"source code"]) {
                    continue; // Preskoči ovaj red
                }
                
                [filteredRows addObject:row];
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
    return [self initWithTitle:@"ZikaWare Settings" sections:[SCITweakSettings sections] reduceMargin:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = self.title;
    titleLabel.textColor = [UIColor systemYellowColor];
    titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    [titleLabel sizeToFit];
    self.navigationItem.titleView = titleLabel;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.contentInset = UIEdgeInsetsMake(self.reduceMargin ? -20 : 0, 0, 0, 0);

    [self.view addSubview:self.tableView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    static NSString *cellID = @"SCICell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    
    cell.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
    
    // LOGIKA ZA TEXT I REBRENDIRANJE
    NSString *displayText = row.title;
    
    // 2. PROMENA DEVELOPER U ZIKA
    if ([displayText.lowercaseString containsString:@"developer"]) {
        displayText = @"Zika";
    }
    
    // 3. PROMENA PEKIWARE U ZIKAWARE U SVIM NASLOVIMA
    displayText = [displayText stringByReplacingOccurrencesOfString:@"PekiWare" withString:@"ZikaWare"];
    
    cell.textLabel.text = displayText;
    cell.textLabel.textColor = [self colorForTitle:displayText];
    cell.textLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];

    cell.detailTextLabel.text = row.subtitle;
    cell.detailTextLabel.textColor = [UIColor orangeColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];

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

    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return self.sections.count; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return [self.sections[section][@"rows"] count]; }

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
