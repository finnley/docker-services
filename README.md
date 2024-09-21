# docker-srvs

CREATE DATABASE `test_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
use test_db;
CREATE TABLE `user` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(20) COLLATE utf8mb4_general_ci DEFAULT '',
  `age` int DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

## 允许外部连接

grant all privileges on *.* to 'root'@'%' identified by 'root' with grant option;
grant all privileges on *.* to 'root'@'%' identified by '123' with grant option;
grant all privileges on *.* to 'root'@'localhost' identified by '123' with grant option;

GRANT ALL privileges ON *.* TO 'root'@'%' ;

/opt/mysql/base/8.0.28/bin/mysql -uroot -p -P8028 -h172.20.134.3 
update user set password=password('123') where user='root' and host='%';

#mysql中执行授权命令
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '123';
#手动刷新权限
flush privileges;

/opt/mysql/base/8.0.28/bin/mysql -uroot -p -P8028 -h172.20.134.2 

/opt/mysql/base/8.0.34/bin/mysql -uroot -p -P3313 -h172.30.5.33 #mysql-ecd69l #172.30.5.33:3313 #mysql-zhou-1
/opt/mysql/base/5.7.25/bin/mysql -uroot -p -P3307 -h172.30.5.95 #mysql-6nsp7o #udp-5-95:3307 #mysql-group-3307-2-12

ALTER USER 'root'@'localhost' IDENTIFIED BY '123' PASSWORD EXPIRE NEVER;

ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '123'; #更新用户密码

FLUSH PRIVILEGES; #刷新权限


mysql8.0 创建host为 % user 为 root 的用户

create user 'root'@'%' identified by '123'; 
grant all privileges on *.* to 'root'@'%' identified by '123' with grant option; 
GRANT ALL privileges ON *.* TO 'root'@'%' ;

## 开放3306端口

firewall-cmd --zone=public --add-port=13357/tcp --permanent
firewall-cmd --reload

https://www.cnblogs.com/heqiuyong/p/10460150.html

查看防火墙状态
firewall-cmd --state

停止防火墙
systemctl stop firewalld.service

禁用防火墙
systemctl disable firewalld.service 

查看防火墙所有开放的端口

1、开放端口

firewall-cmd --zone=public --add-port=5672/tcp --permanent   # 开放5672端口

firewall-cmd --zone=public --remove-port=5672/tcp --permanent  #关闭5672端口

firewall-cmd --reload   # 配置立即生效

 

2、查看防火墙所有开放的端口

firewall-cmd --zone=public --list-ports

 

3.、关闭防火墙

如果要开放的端口太多，嫌麻烦，可以关闭防火墙，安全性自行评估

systemctl stop firewalld.service

 

4、查看防火墙状态

 firewall-cmd --state

 

5、查看监听的端口

netstat -lnpt

6、检查端口被哪个进程占用

netstat -lnpt |grep 5672



 

7、查看进程的详细信息

ps 6832



 

8、中止进程

kill -9 6832


## Nacos

```yaml
  #--------------------------------------------------------------------------
  # Nacos
  #
  # 单机版     
  # docker run --name nacos-standalone -e MODE=standalone -e JVM_XMS=512m -e JVM_XMX=512m -e JVM_XMN=256m -p 8848:8848 -d nacos/nacos-server:latest
  #--------------------------------------------------------------------------
  nacos-standalone:
    container_name: ${ENV}-nacos-standalone
    build:
      context: ./services/nacos
      args:
        - NACOS_VERSION=${NACOS_VERSION}
    # image: nacos/nacos-server:latest
    ports:
      - 8848:8848 
    volumes:
      # 把配置文件映射出来
      - ${PWD}/services/nacos/init.d/custom.properties:/home/nacos/init.d/custom.properties
    environment:
      - MODE=standalone                  
      - JVM_XMS=512m
      - JVM_XMX=512m
      - JVM_XMN=256m
    # env_file:
      # - ${PWD}/services/nacos/env/nacos-standlone-mysql.env
    restart: always
```