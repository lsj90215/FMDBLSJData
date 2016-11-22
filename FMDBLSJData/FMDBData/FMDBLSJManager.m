//
//  FMDBManager.m
//  FMDBData
//
//  Created by 李思俊 on 16/11/15.
//  Copyright © 2016年 lsj. All rights reserved.
//

#import "FMDBLSJManager.h"
#import <FMDB/FMDB.h>

@interface FMDBLSJManager()

//FMDB原生的类
@property (nonatomic,strong) FMDatabaseQueue *db;
/* -----------  数据库属性值的数组  -----------*/
@property (nonatomic, strong) NSArray *keyArray;

@property (nonatomic, strong) NSArray *typeArray;


@end

@implementation FMDBLSJManager

#pragma mark - 实例方法
+(instancetype)managerWithPathName:(NSString *)pathName{
    FMDBLSJManager *manager = [[FMDBLSJManager alloc]initWithPathName:pathName];
    return manager;
}
+(instancetype)managerWithPathName:(NSString *)pathName andKeys:(NSArray *)keys{
    return [[FMDBLSJManager alloc]initWithPathName:pathName andKeys:keys];
}

-(instancetype)initWithPathName:(NSString *)pathName{
    if (self = [super init]) {
        self.pathName = pathName;
    }
    return self;
}

-(instancetype)initWithPathName:(NSString *)pathName andKeys:(NSArray *)keys{
    if (self = [super init]) {
        self.pathName = pathName;
        self.keyArray = keys;
    }
    return self;
}


-(instancetype)initWithPathName:(NSString *)pathName andKeysDict:(NSDictionary *)keysDict{
    if (self = [super init]) {
        self.pathName = pathName;
        self.keysDict = keysDict;
    }
    return self;
}


+(instancetype)managerWithPathName:(NSString *)pathName andKeysDict:(NSDictionary *)keysDict{
    return [[FMDBLSJManager alloc]initWithPathName:pathName andKeysDict:keysDict];
}


#pragma mark - 添加数据库的名称
-(void)setPathName:(NSString *)pathName{
    _pathName = pathName;
    /* -----------  获取沙盒路径  -----------*/
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    NSString *sqlitePath = [path stringByAppendingString:[NSString stringWithFormat:@"\%@.sqlite",pathName]];
    
    NSLog(@"%@",path);
    
    /* -----------  创建fmdb对象  FMDatabase 线程不安全  这里用FMDatabaseQueue  -----------*/
    self.db = [FMDatabaseQueue databaseQueueWithPath:sqlitePath];
    
}

#pragma mark - 赋值keysDict 之后 会创建表
-(void)setKeysDict:(NSDictionary *)keysDict{
    _keysDict = keysDict;
    NSMutableArray *types = [[NSMutableArray alloc]init];
    NSMutableArray *marr = [[NSMutableArray alloc]init];
    NSMutableString *sqliteString = [[NSMutableString alloc]init];
    [keysDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        //拼接属性名数组
        [marr addObject:key];
        [types addObject:obj];
        [sqliteString appendFormat:@", %@ %@",key,obj ];
    }];
    [self creatTableWithString:sqliteString.copy];
    self.keyArray = marr.copy;
    self.typeArray = types.copy;
}

#pragma mark - 创建表
/*
 NSString   TEXT
 NSInteger  INTEGER
 */
-(void)creatTableWithString:(NSString *)string{
    [self.db inDatabase:^(FMDatabase *db) {
        
        NSMutableString *tableString = [[NSMutableString alloc]init];
        
        [tableString appendFormat:@"CREATE TABLE IF NOT EXISTS %@ (id INTEGER PRIMARY KEY AUTOINCREMENT",self.pathName];
        [tableString appendString:string];
        
        [tableString appendString:@");"];
        
        
        //        BOOL success = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS student (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, age INTEGER DEFAULT 1);"];
        BOOL success = [db executeUpdate:tableString.copy];
        
        if (success) {
            NSLog(@"创建表成功");
        } else {
            NSLog(@"创建表失败");
        }
        
    }];
}


#pragma mark - 增加

-(void)addValuesWithModelDict:(NSDictionary *)modelDict{
    NSMutableArray *keys = [[NSMutableArray alloc]init];
    NSMutableArray *objs = [[NSMutableArray alloc]init];
    
    [modelDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [keys addObject:key];
        [objs addObject:obj];
    }];
    
    [self addValuesWithKeys:keys.copy andValues:objs.copy];
}

//参数1:model的属性名 -- 数组
//参数2:model的属性值 -- 数组
-(void)addValuesWithKeys:(NSArray *)keys andValues:(NSArray *)values{
//    
//    if (self.keyArray == nil) {
//        self.keyArray = keys;
//    }
    /* -----------  FMDB原生增加  -----------*/
    [self.db inDatabase:^(FMDatabase *db) {
        [db open];
        
        /* -----------  拼接sqlite语句  -----------*/
        NSMutableString *insertSql1 = [[NSMutableString alloc]init];
        [insertSql1 appendFormat:@"INSERT INTO %@ (",self.pathName];
        for (NSString *key in keys) {
            
            if ([key isEqualToString:keys.lastObject]) {
                
                [insertSql1 appendString:[NSString stringWithFormat:@"'%@'",key]];
            }else{
                [insertSql1 appendString:[NSString stringWithFormat:@"'%@',",key]];
            }
        }
        
        [insertSql1 appendString:@") VALUES ("];
        
        for (int i = 0;i < values.count;i++) {
            id value = values[i];
            if (i == values.count - 1) {
                
                [insertSql1 appendString:[NSString stringWithFormat:@"'%@'",value]];
            }else{
            [insertSql1 appendString:[NSString stringWithFormat:@"'%@',",value]];
            }
        }
        
        [insertSql1 appendString:@")"];
        
//        NSLog(@"%@",insertSql1.copy);
//        NSString *insertSql= [NSString stringWithFormat:@"INSERT INTO t_person ('%@', '%@') VALUES ('%@', '%zd')",@"name", @"age", person.name, person.age];
//        NSLog(@"%@",insertSql);
        
        /* -----------  运行sqlite语句  -----------*/
        BOOL success = [db executeUpdate:insertSql1.copy];
        
        if (success) {
            NSLog(@"插入成功");
            
            
        } else {
            NSLog(@"插入失败");
        }
        [db close];
    }];
}

#pragma mark - 删除单项
//参数1:要删除的model的一个属性名
//参数2:要删除的model 参数1对应的属性值
-(void)deleteValueWithKeyName:(NSString *)keyName andKey:(id)key{
    
    [self.db inDatabase:^(FMDatabase *db) {
        [db open];
        /* -----------  拼接sqlite语句  -----------*/
        NSMutableString *sqliteString = [[NSMutableString alloc]init];
        [sqliteString appendFormat:@"DELETE FROM %@ WHERE %@ = %@;",self.pathName,keyName,key];
        
        /* -----------  运行sqlite语句  -----------*/
        BOOL success = [db executeUpdate:sqliteString.copy];
//        BOOL success = [db executeUpdate:@"DELETE FROM t_person WHERE age > 12 AND age < 25;"];
        if (success) {
            NSLog(@"删除成功");
            
            
        } else {
            NSLog(@"删除失败");
        }
        [db close];
        
    }];
}

#pragma mark - 删除多项
//参数:要删除区间的范围, 中间 需要用 AND 连接
-(void)deleteValueWithSeletedString:(NSString *)seletedString{
    [self.db inDatabase:^(FMDatabase *db) {
        [db open];
        /* -----------  拼接sqlite语句  -----------*/
        NSMutableString *sqliteString = [[NSMutableString alloc]init];
        [sqliteString appendFormat:@"DELETE FROM %@ WHERE %@ ;",self.pathName,seletedString];
        
        /* -----------  运行sqlite语句  -----------*/
        BOOL success = [db executeUpdate:sqliteString.copy];
        //        BOOL success = [db executeUpdate:@"DELETE FROM t_person WHERE age > 12 AND age < 25;"];
        if (success) {
            NSLog(@"删除成功");
            
            
        } else {
            NSLog(@"删除失败");
        }
        [db close];
        
    }];
}

#pragma mark - 修改单项
//参数1:要修改的属性
//参数2:属性修改后的值
//参数3:查询属性名
//参数4:参数3对应的值
-(void)changeValue:(NSString *)value toNewKey:(id)newKey byKeyName:(NSString *)keyName withKey:(id)key{
    [self.db inDatabase:^(FMDatabase *db) {
        [db open];
        
        /* -----------  拼接sqlite语句  -----------*/
        NSMutableString *sqliteString = [[NSMutableString alloc]init];
        [sqliteString appendFormat:@"UPDATE %@ SET %@ = '%@' WHERE %@ = %@;",self.pathName,value,newKey,keyName,key];
        
        /* -----------  运行sqlite语句  -----------*/
        BOOL success = [db executeUpdate:sqliteString.copy];
//        BOOL success = [db executeUpdate:@"UPDATE t_person SET name = 'liwx' WHERE age > 12 AND age < 20;"];
        if (success) {
            NSLog(@"修改成功");
            
            
        } else {
            NSLog(@"修改失败");
        }
        [db close];
    }];
}

#pragma mark - 查询
//参数1:查询区间
//参数2:block回调查询结果
-(void)searchValuesWithSeletedString:(NSString *)seletedString success:(void (^)(FMResultSet *result))success{
    
    [self.db inDatabase:^(FMDatabase *db) {
        [db open];
        
        /* -----------  拼接sqlite语句  -----------*/
        NSMutableString *sqliteString = [[NSMutableString alloc]init];
        
        [sqliteString appendString:@"SELECT "];
        for (NSString *key in self.keyArray) {
            
            if ([key isEqualToString:self.keyArray.lastObject]) {
                
                [sqliteString appendString:[NSString stringWithFormat:@"%@ ",key]];
            }else{
                [sqliteString appendString:[NSString stringWithFormat:@"%@,",key]];
            }
        }
        
        [sqliteString appendFormat: @"FROM %@ WHERE %@;",self.pathName,seletedString];
        
        NSLog(@"===== %@ ",sqliteString);
        
//        FMResultSet *result = [db executeQuery:@"SELECT name, age FROM t_person WHERE age > 0;"];
        
        /* -----------  运行sqlite语句  -----------*/
        FMResultSet *result =[db executeQuery:sqliteString.copy];
        
        /* -----------  block回调查询结果  -----------*/
        success(result);
        
        [db close];
    }];
    
}
//参数:查询区间
//返回参数:字典数组
-(void)searchValuesWithSeletedString:(NSString *)seletedString successArray:(void (^)(NSArray *result))successArray{
    
    [self.db inDatabase:^(FMDatabase *db) {
        [db open];
        
        /* -----------  拼接sqlite语句  -----------*/
        NSMutableString *sqliteString = [[NSMutableString alloc]init];
        
        [sqliteString appendString:@"SELECT "];
        for (NSString *key in self.keyArray) {
            
            if ([key isEqualToString:self.keyArray.lastObject]) {
                
                [sqliteString appendString:[NSString stringWithFormat:@"%@ ",key]];
            }else{
                [sqliteString appendString:[NSString stringWithFormat:@"%@,",key]];
            }
        }
        
        [sqliteString appendFormat: @"FROM %@ WHERE %@;",self.pathName,seletedString];
        
        NSLog(@"===== %@ ",sqliteString);
        
        //        FMResultSet *result = [db executeQuery:@"SELECT name, age FROM t_person WHERE age > 0;"];
        
        /* -----------  运行sqlite语句  -----------*/
        FMResultSet *result =[db executeQuery:sqliteString.copy];
        
        /* -----------  block回调查询结果  -----------*/
        NSMutableArray *dictArr = [[NSMutableArray alloc]init];
        while ([result next]) {
            
            NSDictionary *modelDict = [self modelDictWithResultSet:result];
            [dictArr addObject:modelDict];
        }        
        successArray(dictArr.copy);
        
        [db close];
    }];
    
}

-(NSDictionary *)modelDictWithResultSet:(FMResultSet *)resultSet{
    NSMutableArray *values = [[NSMutableArray alloc]initWithCapacity:self.typeArray.count];
    for (int i = 0;i < self.typeArray.count;i++) {
        if ([self.typeArray[i] isEqualToString:SQString]) {
            [values addObject:[resultSet stringForColumn:self.keyArray[i]]];
        }else if ([self.typeArray[i] isEqualToString:SQInteger]){
            [values addObject:@([resultSet intForColumn:self.keyArray[i]] )];
        }
    }
    NSDictionary *modelDict = [[NSDictionary alloc]initWithObjects:values.copy forKeys:self.keyArray];
    
    return modelDict;
}




@end
