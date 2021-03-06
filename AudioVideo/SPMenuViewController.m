//
//  ViewController.m
//  AudioVideo
//
//  Created by 王杰 on 2020/8/12.
//  Copyright © 2020 raintai. All rights reserved.
//

#import "SPMenuViewController.h"
#import "SPCaptureViewController.h"
#import "SPGPUImageViewController.h"

@interface SPMenuViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *listView;
@property (nonatomic, strong) NSArray *menuArr;
@end

@implementation SPMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.menuArr = @[@"录制/保存/编解码", @"GPUImage"];
    
    self.listView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.listView.dataSource = self;
    self.listView.delegate = self;
    [self.listView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"listIdentifier"];
    [self.view addSubview:self.listView];
    

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.row) {
        case 0:
        {
            SPCaptureViewController *vc = [SPCaptureViewController new];
                   [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 1:
        {
            SPGPUImageViewController *vc = [SPGPUImageViewController new];
                   [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"listIdentifier" forIndexPath:indexPath];
    cell.textLabel.text = self.menuArr[indexPath.row];
    return cell;
}


@end
