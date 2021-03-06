#!/bin/bash

yum_server='yum.server.local'
YUM_PACKAGE='unzip gcc gcc-c++ make cmake automake autoconf libtool pcre pcre-devel zlib zlib-devel openssl openssl-devel'

#SET TEMP DIR
INSTALL_DIR="/tmp/install_$$"
TEMP_FILE="/tmp/tmp.$$"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -d ${INSTALL_DIR} && rm -rf ${INSTALL_DIR};test -f ${TEMP_FILE} && rm -f ${TEMP_FILE}"  EXIT

test -f /etc/redhat-release ||\
eval "echo 不支持此系统!;exit 1"

test -f /usr/bin/yum ||\
eval "echo 未安装yum!;exit 1"

echo -en 'yum安装'
echo -en '\t->\t'
yum --skip-broken --nogpgcheck install -y ${YUM_PACKAGE} >/dev/null 2>&1 ||\
eval "echo yum安装失败;exit 1" && echo 'OK!'

id fastdfs >/dev/null 2>&1 ||\
useradd fastdfs -M -s /sbin/nologin && \
eval "echo 用户: fastdfs 已经存在!"

#libfastcommon安装
pkg='libfastcommon-master.zip'

echo -en '下载'
echo -en "${pkg}"
echo -en '\t->\t'
test -d ${INSTALL_DIR} || mkdir -p ${INSTALL_DIR}
wget -q http://${yum_server}/tools/${pkg} -O ${INSTALL_DIR}/${pkg} ||\
eval "echo wget下载失败;exit 1" &&\
echo 'OK!'

test -d ${INSTALL_DIR} && cd ${INSTALL_DIR}
test -f ${pkg} && unzip ${pkg} >/dev/null 2>&1||\
eval "echo ${pkg}不存在;exit 1"

cd libfastcommon-master ||\
eval "解压失败!;exit 1"

log_file="/tmp/install_${pkg}.log"
./make.sh > ${log_file} 2>&1 && ./make.sh install > ${log_file} 2>&1||\
eval "编译失败!;exit 1"

test -f /usr/local/lib/libfastcommon.so || \
ln -s /usr/lib64/libfastcommon.so  /usr/local/lib/libfastcommon.so
test -f /usr/lib/libfastcommon.so || \
ln -s /usr/lib64/libfastcommon.so  /usr/lib/libfastcommon.so
test -f /usr/local/lib/libfdfsclient.so ||\
ln -s /usr/lib64/libfdfsclient.so /usr/local/lib/libfdfsclient.so
test -f /usr/lib/libfdfsclient.so ||\
ln -s /usr/lib64/libfdfsclient.so /usr/lib/libfdfsclient.so

#fastdfs安装
pkg='FastDFS_v5.05.tar.gz'

echo -en '下载'
echo -en "${pkg}"
echo -en '\t->\t'
test -d ${INSTALL_DIR} || mkdir -p ${INSTALL_DIR}
wget -q http://${yum_server}/tools/${pkg} -O ${INSTALL_DIR}/${pkg} ||\
eval "echo wget下载失败;exit 1" &&\
echo 'OK!'

test -d ${INSTALL_DIR} && cd ${INSTALL_DIR}
test -f ${pkg} && tar xzf ${pkg} ||\
eval "echo ${pkg}不存在;exit 1"

cd FastDFS ||\
eval "解压失败!;exit 1"

log_file="/tmp/install_${pkg}.log"
./make.sh > ${log_file} 2>&1 && ./make.sh install > ${log_file} 2>&1 ||\
eval "编译失败!;exit 1"

ls /usr/bin/fdfs* >/dev/null 2>&1||\
eval "编译失败!;exit 1"

test -f /etc/init.d/fdfs_storaged &&\
sed -r -i 's|/usr/local/bin/|/usr/bin/|g' /etc/init.d/fdfs_storaged
test -f /etc/init.d/fdfs_trackerd &&\
sed -r -i 's|/usr/local/bin/|/usr/bin/|g' /etc/init.d/fdfs_trackerd

#test -d /usr/local/src/FastDFS/conf &&
test -d conf && cp conf/* /etc/fdfs/

#tdfs-nginx-module安装
pkg='fastdfs-nginx-module_v1.16.tar.gz'

echo -en '下载'
echo -en "${pkg}"
echo -en '\t->\t'
test -d ${INSTALL_DIR} || mkdir -p ${INSTALL_DIR}
wget -q http://${yum_server}/tools/${pkg} -O ${INSTALL_DIR}/${pkg} ||\
eval "echo wget下载失败;exit 1" &&\
echo 'OK!'

test -d ${INSTALL_DIR} && cd ${INSTALL_DIR}
test -f ${pkg} && tar xzf ${pkg} ||\
eval "echo ${pkg}不存在;exit 1"

cd fastdfs-nginx-module ||\
eval "解压失败!;exit 1"

test -f src/config && \
sed -r -i '/^CORE_INCS/s|/usr/local/|/usr/|g' src/config

test -d /usr/local/fastdfs-nginx-module/ && rm -rf /usr/local/fastdfs-nginx-module/
cd .. && mv fastdfs-nginx-module /usr/local/
chown -R fastdfs.fastdfs /usr/local/fastdfs-nginx-module/

#安装nginx
pkg='nginx-1.6.2.tar.gz'

echo -en '下载'
echo -en "${pkg}"
echo -en '\t->\t'
test -d ${INSTALL_DIR} || mkdir -p ${INSTALL_DIR}
wget -q http://${yum_server}/tools/${pkg} -O ${INSTALL_DIR}/${pkg} ||\
eval "echo wget下载失败;exit 1" &&\
echo 'OK!'

test -d ${INSTALL_DIR} && cd ${INSTALL_DIR}
test -f ${pkg} && tar xzf ${pkg} ||\
eval "echo ${pkg}不存在;exit 1"

id nginx >/dev/null 2>&1 ||\
useradd nginx -M -s /sbin/nologin && \
eval "echo 用户: fastdfs 已经存在!"

log_file="/tmp/install_${pkg}.log"
cd nginx-1.6.2 && \
./configure --prefix=/usr/local/nginx --add-module=/usr/local/fastdfs-nginx-module/src > ${log_file} 2>&1

make > ${log_file} 2>&1 && make install > ${log_file} 2>&1

test -d /etc/fdfs/ || mkdir -p /etc/fdfs/
cp /usr/local/fastdfs-nginx-module/src/mod_fastdfs.conf /etc/fdfs/

mkdir -p /fastdfs/storage/data
mkdir -p /fastdfs/tracker
test -L /fastdfs/storage/data/M00 ||\
ln -s /fastdfs/storage/data /fastdfs/storage/data/M00
chown -R fastdfs.fastdfs /fastdfs/storage/data

#下载配置文件
pkg='fdfs.config.tar.gz'

echo -en '下载'
echo -en "${pkg}"
echo -en '\t->\t'
test -d ${INSTALL_DIR} || mkdir -p ${INSTALL_DIR}
wget -q http://${yum_server}/tools/${pkg} -O ${INSTALL_DIR}/${pkg} ||\
eval "echo wget下载失败;exit 1" &&\
echo 'OK!'

test -d ${INSTALL_DIR} && cd ${INSTALL_DIR}
test -f ${pkg} && tar xzf ${pkg} -C /etc/fdfs/||\
eval "echo ${pkg}不存在;exit 1"

#tar xzf fdfs.config.tar.gz -C /tmp/fdfs/
