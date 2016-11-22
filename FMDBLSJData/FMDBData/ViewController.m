//
//  ViewController.m
//  FMDBData
//
//  Created by 李思俊 on 16/11/15.
//  Copyright © 2016年 lsj. All rights reserved.
//

#import "ViewController.h"
#import <FMDB/FMDB.h>
#import "PersonModel.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray <PersonModel *>*personArray;

@property (nonatomic,strong) FMDatabaseQueue *db;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    /* -----------  创建FMDB  表  -----------*/
    [self.db inDatabase:^(FMDatabase *db) {
        BOOL success = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_person (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, age INTEGER DEFAULT 1);"];
        
        if (success) {
            NSLog(@"创建表成功");
        } else {
            NSLog(@"创建表失败");
        }
        
    }];
    
    /* -----------  注册tableViewCell   -----------*/
//    [self.tableView registerClass:[LSJTableViewCell class] forCellReuseIdentifier:@"cell"];
    
    
}

#pragma mark - 懒加载创建FMDBQueue
-(FMDatabaseQueue *)db{
    if (_db == nil) {
        
        /* -----------  获取沙盒路径  -----------*/
        NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        NSString *sqlitePath = [path stringByAppendingString:@"t_person.sqlite"];
        
        NSLog(@"%@",path);
        
        /* -----------  创建fmdb对象  FMDatabase 线程不安全  这里用FMDatabaseQueue  -----------*/
        _db = [FMDatabaseQueue databaseQueueWithPath:sqlitePath];
    }
    return _db;
}

#pragma mark - 懒加载创建model数组
-(NSArray<PersonModel *> *)personArray{
    if (_personArray == nil) {
        NSMutableArray *marr = [[NSMutableArray alloc]init];
        
        /* -----------  从本地数据库获取数据  -----------*/
        [self.db inDatabase:^(FMDatabase *db) {
            
            [db open];
            
            /* -----------  查找所有age > 0的数据  -----------*/
            FMResultSet *result = [db executeQuery:@"SELECT name, age FROM t_person WHERE age > 0;"];
            
            /* -----------  对获得的数据进行循环赋值  -----------*/
            while ([result next]) {
                NSString *name = [result stringForColumn:@"name"];
                int age = [result intForColumn:@"age"];
                
                PersonModel *p = [PersonModel new];
                p.name = name;
                p.age = age;
                
                //添加到可变数组
                [marr addObject:p];
                NSLog(@" name: %@, age: %zd", name, age);
            }
            
            [db close];
        }];
        //数组赋值
        _personArray = marr.copy;
    }
    return _personArray;
}


#pragma mark - FMDB增加数据
- (IBAction)add:(id)sender {
    
    /* -----------  要增加的数据  -----------*/
    PersonModel *person = [[PersonModel alloc]init];
    person.name = @"安丽娜";
    person.age = 18;
    
    /* -----------  保证线程安全的调用  增加  -----------*/
    [self.db inDatabase:^(FMDatabase *db) {
        [db open];
        NSString *insertSql1= [NSString stringWithFormat:@"INSERT INTO t_person ('%@', '%@') VALUES ('%@', '%zd')",@"name", @"age", person.name, person.age];
        BOOL success = [db executeUpdate:insertSql1];
        
        if (success) {
            NSLog(@"插入成功");
            
            
        } else {
            NSLog(@"插入失败");
        }
        [db close];
    }];
    
    /* -----------  刷新UI  -----------*/
    [self reloadTableView];
}

#pragma mark - FMDB删除数据
- (IBAction)delete:(id)sender {
    
    [self.db inDatabase:^(FMDatabase *db) {
        [db open];
        BOOL success = [db executeUpdate:@"DELETE FROM t_person WHERE age > 12 AND age < 25;"];
        if (success) {
            NSLog(@"删除成功");
            
            
        } else {
            NSLog(@"删除失败");
        }
        [db close];
        
    }];
    //刷新UI
    [self reloadTableView];
}

#pragma mark - FMDB查询数据
- (IBAction)search:(id)sender {
    [self.db inDatabase:^(FMDatabase *db) {
        [db open];
        FMResultSet *result = [db executeQuery:@"SELECT name, age FROM t_person WHERE age > 0;"];
        
        while ([result next]) {
            NSString *name = [result stringForColumn:@"name"];
            int age = [result intForColumn:@"age"];
            NSLog(@" name: %@, age: %zd", name, age);
        }
        [db close];
    }];
    
}

#pragma mark - FMDB修改数据
- (IBAction)change:(id)sender {
    [self.db inDatabase:^(FMDatabase *db) {
        [db open];
        
        BOOL success = [db executeUpdate:@"UPDATE t_person SET name = 'liwx' WHERE age > 12 AND age < 20;"];
        if (success) {
            NSLog(@"修改成功");
            
            
        } else {
            NSLog(@"修改失败");
        }
        [db close];
    }];

    //刷新UI
    [self reloadTableView];
}

#pragma mark - 刷新UI
-(void)reloadTableView{
    
    NSMutableArray *marr = [[NSMutableArray alloc]init];
    
    [self.db inDatabase:^(FMDatabase *db) {
        [db open];
        FMResultSet *result = [db executeQuery:@"SELECT name, age FROM t_person WHERE age > 0;"];

        
        while ([result next]) {
            NSString *name = [result stringForColumn:@"name"];
            int age = [result intForColumn:@"age"];
            
            PersonModel *p = [PersonModel new];
            p.name = name;
            p.age = age;
            
            [marr addObject:p];
            NSLog(@" name: %@, age: %zd", name, age);
        }
        
        [db close];
    }];
    
    self.personArray = marr.copy;
    
    [self.tableView reloadData];

}


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
