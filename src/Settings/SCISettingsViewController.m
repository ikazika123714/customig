#import "SCISettingsViewController.h"
#import <objc/runtime.h>

static char rowStaticRef[] = "row";

@interface SCISettingsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *sections;
@property (nonatomic) BOOL reduceMargin;
@end

@implementation SCISettingsViewController

- (UIColor *)rainbowColorForIndex:(NSInteger)index {
    NSArray *colors = @[
        [UIColor systemYellowColor],
        [UIColor systemGreenColor],
        [UIColor colorWithRed:0.40 green:0.95 blue:0.40 alpha:1.0],
        [UIColor colorWithRed:0.30 green:0.85 blue:0.70 alpha:1.0],
        [UIColor colorWithRed:0.25 green:0.75 blue:0.90 alpha:1.0],
        [UIColor colorWithRed:0.20 green:0.50 blue:1.00 alpha:1.0],
        [UIColor colorWithRed:0.30 green:0.30 blue:1.00 alpha:1.0],
        [UIColor systemPurpleColor],
        [UIColor systemPinkColor],
        [UIColor systemRedColor],
    ];
    return colors[index % colors.count];
}

- (instancetype)initWithTitle:(NSString *)title sections:(NSArray *)sections reduceMargin:(BOOL)reduceMargin {
    self = [super init];
    if (self) {
        NSString *newTitle = [title stringByReplacingOccurrencesOfString:@"PekiWare" withString:@"ZikaWare"];
        newTitle = [newTitle stringByReplacingOccurrencesOfString:@"Peki" withString:@"Zika"];
        self.title = newTitle;

        NSMutableArray *filteredSections = [NSMutableArray new];

        for (NSDictionary *section in sections) {
            NSMutableArray *filteredRows = [NSMutableArray new];

            for (SCISetting *row in section[@"rows"]) {
                NSString *rt = [row.title lowercaseString];

                // Izbaci Donate
                if ([rt containsString:@"donate"]) {
                    continue;
                }

                // View Repo / Source Code -> TikTok
                if ([rt containsString:@"view repo"] || [rt containsString:@"source code"]) {
                    SCISetting *tiktokRow = [row mutableCopy];
                    tiktokRow.title    = @"TikTok";
                    tiktokRow.subtitle = @"Poseti moj TikTok profil";
                    tiktokRow.url      = [NSURL URLWithString:@"https://www.tiktok.com/@zivkovichhh_"];
                    tiktokRow.type     = SCITableCellLink;
                    [filteredRows addObject:tiktokRow];
                    continue;
                }

                // Discord/Community -> TikTok takodje
                if ([rt containsString:@"discord"] || [rt containsString:@"community"] || [rt containsString:@"join"]) {
                    SCISetting *tiktokRow = [row mutableCopy];
                    tiktokRow.title    = @"TikTok";
                    tiktokRow.subtitle = @"Poseti moj TikTok profil";
                    tiktokRow.url      = [NSURL URLWithString:@"https://www.tiktok.com/@zivkovichhh_"];
                    tiktokRow.type     = SCITableCellLink;
                    [filteredRows addObject:tiktokRow];
                    continue;
                }

                // Developer red -> Zika koji otvara TikTok
                if ([rt containsString:@"developer"]) {
                    SCISetting *zikaRow = [row mutableCopy];
                    zikaRow.title    = @"Zika";
                    zikaRow.subtitle = @"@zivkovichhh_";
                    zikaRow.url      = [NSURL URLWithString:@"https://www.tiktok.com/@zivkovichhh_"];
                    zikaRow.type     = SCITableCellLink;
                    [filteredRows addObject:zikaRow];
                    continue;
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
    titleLabel.text      = self.title;
    titleLabel.textColor = [UIColor systemYellowColor];
    titleLabel.font      = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    [titleLabel sizeToFit];
    self.navigationItem.titleView = titleLabel;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.backgroundColor  = [UIColor blackColor];
    self.tableView.separatorColor   = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.tableView.dataSource       = self;
    self.tableView.delegate         = self;
    self.tableView.contentInset     = UIEdgeInsetsMake(self.reduceMargin ? -20 : 0, 0, 0, 0);
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

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

    // Globalni index za rainbow boje
    NSInteger globalIndex = 0;
    for (NSInteger s = 0; s < indexPath.section; s++) {
        globalIndex += [self.sections[s][@"rows"] count];
    }
    globalIndex += indexPath.row;

    // Rebrendiranje teksta
    NSString *displayText = row.title;
    displayText = [displayText stringByReplacingOccurrencesOfString:@"PekiWare" withString:@"ZikaWare"];
    displayText = [displayText stringByReplacingOccurrencesOfString:@"Peki" withString:@"Zika"];

    cell.textLabel.text      = displayText;
    cell.textLabel.textColor = [self rainbowColorForIndex:globalIndex];
    cell.textLabel.font      = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];

    NSString *subtitleText = row.subtitle ?: @"";
    subtitleText = [subtitleText stringByReplacingOccurrencesOfString:@"PekiWare" withString:@"ZikaWare"];
    subtitleText = [subtitleText stringByReplacingOccurrencesOfString:@"Peki" withString:@"Zika"];
    cell.detailTextLabel.text      = subtitleText;
    cell.detailTextLabel.textColor = [UIColor orangeColor];
    cell.detailTextLabel.font      = [UIFont systemFontOfSize:12];

    if (row.icon != nil) {
        cell.imageView.image     = [row.icon image];
        cell.imageView.tintColor = [UIColor whiteColor];
    }

    if (row.type == SCITableCellSwitch) {
        UISwitch *toggle   = [UISwitch new];
        toggle.on          = [[NSUserDefaults standardUserDefaults] boolForKey:row.defaultsKey];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.sections[section][@"rows"] count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];

    if (row.type == SCITableCellNavigation && row.navSections.count > 0) {
        UIViewController *vc = [[SCISettingsViewController alloc] initWithTitle:row.title
                                                                       sections:row.navSections
                                                                   reduceMargin:NO];
        [self.navigationController pushViewController:vc animated:YES];
    } else if (row.type == SCITableCellLink) {
        // Otvara TikTok ili drugi link
        [[UIApplication sharedApplication] openURL:row.url
                                           options:@{}
                                 completionHandler:nil];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)switchChanged:(UISwitch *)sender {
    SCISetting *row = objc_getAssociatedObject(sender, rowStaticRef);
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:row.defaultsKey];
    if (row.requiresRestart) [SCIUtils showRestartConfirmation];
}

@end
