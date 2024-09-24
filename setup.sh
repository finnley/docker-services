#!/bin/bash

# source prepare.sh
source .env

function echo_mysql_to_nginx() {
  if [[ ${MYSQL_5_7_ENABLE} == 'true' ]]; then
    cat <<EOF
- mysql57
EOF
  fi
  if [[ ${MYSQL_8_0_ENABLE} == 'true' ]]; then
  cat <<EOF
- mysql80
EOF
  fi
}

function echo_php_to_nginx() {
  if [[ ${PHP_ENABLE} == 'true' ]]; then
    cat <<EOF
depends_on:
      - php-fpm
EOF
  fi
}

cat > ./docker-compose.yaml <<EOF
version: "3"

services:
EOF


# MySQL 5.7
# no matching manifest for linux/arm64/v8 in the manifest list entries
# solution: https://stackoverflow.com/questions/65456814/docker-apple-silicon-m1-preview-mysql-no-matching-manifest-for-linux-arm64-v8
echo "MYSQL_5_7_ENABLE: ${MYSQL_5_7_ENABLE}"
# 最简单的部署
# if [[ ${MYSQL_5_7_ENABLE} == 'true' ]]; then
#   cat >> ./docker-compose.yaml <<EOF
#   mysql57:
#     # platform: linux/x86_64
#     platform: linux/amd64
#     image: mysql:${MYSQL_5_7_VERSION}
#     restart: always
#     command: --default-authentication-plugin=mysql_native_password
#     environment:
#       MYSQL_ROOT_PASSWORD: root
#     volumes:
#       # 设置初始化脚本
#       - ./mysql/docker-entrypoint-initdb.d/:/docker-entrypoint-initdb.d/
#     ports:
#       # 注意这里我映射为了 13357 端口
#       - "13357:3306"

# EOF
# fi


if [[ ${MYSQL_5_7_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  mysql57:
    # container_name: ${ENV}-mysql57
    # build:
    #   context: ./services/mysql
    #   args:
    #     - MYSQL_VERSION=${MYSQL_5_7_VERSION}
    platform: linux/amd64
    image: mysql:${MYSQL_5_7_VERSION}
    restart: always
    environment:
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - TIMEZONE=${TIMEZONE}
    volumes:
      - ${MYSQL_ENTRYPOINT_INITDB}:/docker-entrypoint-initdb.d
      # - ./mysql/5.7/conf:/etc/mysql/conf.d
      # - ${DATA_PATH_HOST}/mysql/5.7/data:/var/lib/mysql
    ports:
      - 3357:${MYSQL_PORT}

EOF
fi


# MySQL 8.0
echo "MYSQL_8_0_ENABLE: ${MYSQL_8_0_ENABLE}"
if [[ ${MYSQL_8_0_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  mysql80:
    image: mysql:${MYSQL_8_0_VERSION}
    restart: always
    command: --default-authentication-plugin=mysql_native_password
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    volumes:
      - ${MYSQL_ENTRYPOINT_INITDB}:/docker-entrypoint-initdb.d
    ports:
      - 3380:${MYSQL_PORT}

EOF
fi


echo "REDIS_ENABLE: ${REDIS_ENABLE}"
if [[ ${REDIS_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  redis:
    image: bitnami/redis:${REDIS_VERSION}
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
    ports:
      - 6379:${REDIS_PORT}

EOF
fi

echo "MONGODB_ENABLE: ${MONGODB_ENABLE}"
if [[ ${MONGODB_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  mongodb:
    restart: always
    build: ./mongodb
    ports:
      - "${MONGODB_PORT}:27017"
    environment:
      - MONGODB_INITDB_ROOT_USERNAME=${MONGODB_ROOT_USERNAME}
      - MONGODB_INITDB_ROOT_PASSWORD=${MONGODB_ROOT_PASSWORD}
    volumes:
      - ${DATA_PATH_HOST}/mongodb:/data/db
      - ${PWD}/mongodb/mongo-conf:/docker-entrypoint-initdb.d

EOF
fi

echo "CONSUL_ENABLE: ${CONSUL_ENABLE}"
if [[ ${CONSUL_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  consul:
    image: consul:${CONSUL_VERSION}
    ports:
      - 8300:8300
      - 8500:8500
      - 8301:8301
      - 8301:8301/udp
      - 8302:8302
      - 8302:8302/udp
      - 8600:8600
      - 8600:8600/udp
    # volumes:
    #   - ${PWD}/config:/consul/config
    #   - ${DATA_STORAGE_PATH}/consul/data:/consul/data
    restart: always
    command: agent -dev -client=0.0.0.0

EOF
fi


#--------------------------------------------------------------------------
# Nacos
#
# 单机版     
# docker run --name nacos-standalone -e MODE=standalone -e JVM_XMS=512m -e JVM_XMX=512m -e JVM_XMN=256m -p 8848:8848 -d nacos/nacos-server:latest
#--------------------------------------------------------------------------
echo "NACOS_ENABLE: ${NACOS_ENABLE}"
if [[ ${NACOS_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  nacos-standalone:
    # platform: linux/amd64
    image: nacos/nacos-server:${NACOS_VERSION}
    ports:
      - 8848:8848 
    # volumes:
    #   - ./nacos/init.d/custom.properties:/home/nacos/init.d/custom.properties
    environment:
      - MODE=standalone                  
      - JVM_XMS=512m
      - JVM_XMX=512m
      - JVM_XMN=256m
    restart: always

EOF
fi


echo "PHP_ENABLE: ${PHP_ENABLE}"
if [[ ${PHP_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  php-fpm:
    # container_name: php-pfm
    build:
      context: ./php-fpm
      args:
        - PHP_VERSION=${PHP_VERSION}
        - INSTALL_PCNTL=${PHP_INSTALL_PCNTL}
        - INSTALL_OPCACHE=${PHP_INSTALL_OPCACHE}
        - INSTALL_ZIP=${PHP_INSTALL_ZIP}
        - INSTALL_REDIS=${PHP_INSTALL_REDIS}
        - INSTALL_REDIS_VERSION=${PHP_INSTALL_REDIS_VERSION}
        - INSTALL_MONGODB=${PHP_INSTALL_MONGODB}
        - INSTALL_MONGODB_VERSION=${PHP_INSTALL_MONGODB_VERSION}
        - INSTALL_MEMCACHED=${PHP_INSTALL_MEMCACHED}
        - INSTALL_MEMCACHED_VERSION=${PHP_INSTALL_MEMCACHED_VERSION}
        - INSTALL_SWOOLE=${PHP_INSTALL_SWOOLE}
        - INSTALL_SWOOLE_VERSION=${PHP_INSTALL_SWOOLE_VERSION}
        - INSTALL_YAF=${PHP_INSTALL_YAF}
        - INSTALL_YAF_VERSION=${PHP_INSTALL_YAF_VERSION}
        - INSTALL_XUNSEARCH=${PHP_INSTALL_XUNSEARCH}
        - INSTALL_COMPOSER=${PHP_INSTALL_COMPOSER}
    ports:
      - 9000:9000
    volumes:
      - ./php-fpm/conf-${PHP_VERSION}/php.ini:/usr/local/etc/php/php.ini
      - ./php-fpm/conf-${PHP_VERSION}/php-fpm.conf:/usr/local/etc/php-fpm.conf
      - ./php-fpm/conf-${PHP_VERSION}/php-fpm.d:/usr/local/etc/php-fpm.d
      - ${WORKSPACE}/www:/var/www/site
    depends_on:
      $(echo_mysql_to_nginx)

EOF
fi

echo "NGINX_ENABLE: ${NGINX_ENABLE}"
if [[ ${NGINX_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  nginx:
    # container_name: ${ENV}-nginx
    build:
      context: ./nginx
      args:
        - CHANGE_SOURCE=${CHANGE_SOURCE}
        # - PHP_UPSTREAM_CONTAINER=${NGINX_PHP_UPSTREAM_CONTAINER}
        # - PHP_UPSTREAM_PORT=${NGINX_PHP_UPSTREAM_PORT}
        - http_proxy
        - https_proxy
        - no_proxy
    volumes:
      - ./nginx/logs/:/var/log
      - ./nginx/sites/:/etc/nginx/sites-available
      - ./nginx/ssl/:/etc/nginx/ssl
      # - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ${WORKSPACE}/www:/var/www/site
    ports:
      - 80:80
      - 81:81
      - 443:443
    # environment:
    #   - BACKEND_API_DOMAIN=${BACKEND_API_DOMAIN}
    working_dir: /var/www/site
    tty: true
    $(echo_php_to_nginx)

EOF
fi

echo "SQLITE3_ENABLE: ${SQLITE3_ENABLE}"
if [[ ${SQLITE3_ENABLE} == 'true' ]]; then
  cat >> ./docker-compose.yaml <<EOF
  sqlite3:
    volumes:
      - ${PWD}/sqlite3:/data/db
      - ${PWD}/mongo_config:/data/configdb
      - ${PWD}/mongo/mongo-conf:/docker-entrypoint-initdb.d
    command: 'sqlite3 /data/mydatabase.db'

EOF
fi

