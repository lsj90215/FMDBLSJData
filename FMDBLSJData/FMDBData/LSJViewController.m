//
//  LSJViewController.m
//  FMDBData
//
//  Created by 李思俊 on 16/11/15.
//  Copyright © 2016年 lsj. All rights reserved.
//

#import "LSJViewController.h"
#import "FMDBLSJManager.h"
#import "PersonModel.h"



@interface LSJViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray <PersonModel *>*personArray;


@property (nonatomic,strong) FMDBLSJManager *manager;
@end

@implementation LSJViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.manager = [[FMDBLSJManager alloc]initWithPathName:@"student" andKeysDict:@{
                                                                                 @"name":SQString,
                                                                                 @"age":SQInteger
                                                                                 }];
}
#pragma mark - 懒加载数据源数组 (注: 这里可以加判断,是否从网络获取数据或者是从本地数据库获取)
-(NSArray<PersonModel *> *)personArray{
    if (_personArray == nil) {
        NSMutableArray *marr = [[NSMutableArray alloc]init];
        
        /* -----------  查询数据  -----------*/
        [self.manager searchValuesWithSeletedString:@"age > 0" successArray:^(NSArray *result) {
            for (NSDictionary *dict in result) {
                PersonModel *model = [[PersonModel alloc]init];
                [model setValuesForKeysWithDictionary:dict];
                [marr addObject:model];
            }
        }];
        //数组赋值
        _personArray = marr.copy;
    }
    return _personArray;
}

#pragma mark - 添加数据
- (IBAction)add:(id)sender {
    
    PersonModel *p = [PersonModel new];
    p.name = @"小明";
    p.age = 30;
    
    /* -----------  添加数据到数据库 注:将model属性名和值编成数组,进行赋值  -----------*/
    [self.manager addValuesWithKeys:@[@"name",@"age"] andValues:@[p.name,@(p.age)]];
    
    /* -----------  刷新UI  -----------*/
    [self reloadTableView];
}

#pragma mark - 删除数据
- (IBAction)delete:(id)sender {
    /* -----------  删除单个  -----------*/
//    [self.manager deleteValueWithKeyName:@"age" andKey:@(30)];
    
    /* -----------  删除一个范围 注:若需要一个区间,则上下用 AND 连接 -----------*/
    [self.manager deleteValueWithSeletedString:@"age > 0"];
    
    /* -----------  刷新UI  -----------*/
    [self reloadTableView];
}

#pragma mark - 修改数据
- (IBAction)change:(id)sender {
    
    /* -----------  根据key值  修改  -----------*/
    [self.manager changeValue:@"name" toNewKey:@"小花" byKeyName:@"age" withKey:@(30)];
    
    /* -----------  刷新UI  -----------*/
    [self reloadTableView];
}

#pragma mark - 查询数据
- (IBAction)search:(id)sender {
    
    [self.manager searchValuesWithSeletedString:@"age > 0" success:^(FMResultSet *result) {
        
        while ([result next]) {
            NSString *name = [result stringForColumn:@"name"];
            int age = [result intForColumn:@"age"];
            NSLog(@" name: %@, age: %zd", name, age);
        }
    }];
}

#pragma mark - 刷新UI
-(void)reloadTableView{
    
    NSMutableArray *marr = [[NSMutableArray alloc]init];
    
    /* -----------  需要输入查询区间  可以用 AND 连接  -----------*/
    [self.manager searchValuesWithSeletedString:@"age > 0" successArray:^(NSArray *result) {
        for (NSDictionary *dict in result) {
            PersonModel *model = [[PersonModel alloc]init];
            [model setValuesForKeysWithDictionary:dict];
            [marr addObject:model];
        }
    }];
    
    self.personArray = marr.copy;
    
    /* -----------  刷新UI  -----------*/
    [self.tableView reloadData];
    
}


#pragma mark - tableView
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.personArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath   {
    
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        NSLog(@"没有CELL");
    }
    
    cell.textLabel.text = self.personArray[indexPath.row].name  ;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"芳龄%zd",self.personArray[indexPath.row].age];
    
    return cell;
    
}

@end
