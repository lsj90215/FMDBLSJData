//
//  FMDBManager.h
//  FMDBData
//
//  Created by 李思俊 on 16/11/15.
//  Copyright © 2016年 lsj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMResultSet.h>

//如果有较多的数据类型,请在这里添加宏
#define SQString @"TEXT" 
#define SQInteger @"INTEGER"

@interface FMDBLSJManager : NSObject

/* -----------  数据库名称  -----------*/
@property (nonatomic, copy) NSString *pathName;

/* -----------  Model属性名:属性类型 -- 赋值后就会创建表 -----------*/
@property (nonatomic,strong) NSDictionary *keysDict;

/* -----------  实例方法 -- 不会创建表,需要再给keysDict赋值 -----------*/
+(instancetype)managerWithPathName:(NSString *)pathName;
-(instancetype)initWithPathName:(NSString *)pathName;
/* -----------  实例方法 -- 会创建表  -----------*/
-(instancetype)initWithPathName:(NSString *)pathName andKeysDict:(NSDictionary *)keysDict;
+(instancetype)managerWithPathName:(NSString *)pathName andKeysDict:(NSDictionary *)keysDict;

/* -----------  增加  -----------*/
//参数1:model的属性名 -- 数组
//参数2:model的属性值 -- 数组
//参数1和2要一一对应
-(void)addValuesWithKeys:(NSArray *)keys andValues:(NSArray *)values;
//参数:model的字典 属性名: 属性值
-(void)addValuesWithModelDict:(NSDictionary *)modelDict;

/* -----------  删除  -----------*/
//参数1:要删除的model的一个属性名
//参数2:要删除的model 参数1对应的属性值
-(void)deleteValueWithKeyName:(NSString *)keyName andKey:(id)key;
//参数:要删除区间的范围, 中间 需要用 AND 连接
-(void)deleteValueWithSeletedString:(NSString *)seletedString;

/* -----------  修改  -----------*/
//参数1:要修改的属性
//参数2:属性修改后的值
//参数3:查询属性名
//参数4:参数3对应的值
-(void)changeValue:(NSString *)value toNewKey:(id)newKey byKeyName:(NSString *)keyName withKey:(id)key;

/* -----------  查询  -----------*/
//参数1:查询区间
//参数2:block回调查询结果
-(void)searchValuesWithSeletedString:(NSString *)seletedString success:(void (^)(FMResultSet *result))success;
//返回字典数组
-(void)searchValuesWithSeletedString:(NSString *)seletedString successArray:(void (^)(NSArray *result))successArray;

@end
