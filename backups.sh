#!/bin/bash


# 备份脚本说明：
# 功能一：  系统备份（全量）：备份系统文件，打包为自定义文件，排除特殊目录下的文件等。
# 功能二：  数据备份（全量）：备份指定目录(详细查看"自定义数据备份区")，适用备份数据量小的重要数据，如应用数据、配置等。
# 功能三：  系统备份（差异）：每次备份只在上次的基础上删除、备份新增或修改的文件。
# 功能四：  数据备份（差异）：每次备份只在上次的基础上删除、备份新增或修改的文件。
# 功能五：  上传WebDAV：将已备份文件自动上传到WebDAV服务器，仅上传全量备份。
 
# 差异备份说明：差异备份需要安装rsync，请提前自行安装，否则不进行差异备份。差异数据备份不做归档压缩处理。
# WebDAV用于配合alist备份到各类云盘的，打开此功能会自动将备份文件上传到WebDAV。需要系统安装好curl，否则脚本报错。
# 备份恢复方法：全量备份还原自行百度"tar备份还原"，差异备份自行百度"rsync差异备份还原"。
# 定时运行方法：参考crontab定时，不懂百度"crontab linux定时任务"。
# 设置区功能开关说明：true开，false关
 
# ==============================免责说明==============================
# 无法确保脚本文件完全适合所有linux发行版，请自行确认。
# 不对脚本产生的问题负责，本脚本仅供学习参考，请勿用于商业用途。
 
# 作者: https://github.com/dsmggm
# Date: 2024.08.31
# Version: 1.3

#======================================================================

#=====================功能一  系统备份（全量）=========================
# 说明：每次备份会覆盖上一次备份
System_bak_all_switch=true  # 功能启用选项
System_bak_all_days=90      #系统全量备份间隔天数
System_bak_all_path="/root/AllFiles/backups/system_backups.tar.gz"      # 系统全量备份文件路径

#=====================功能二  数据备份（全量）=========================
# 说明：每次备份会覆盖上一次备份
Data_bak_all_switch=false    # 功能启用选项
Data_bak_all_days=28        #数据全量备份间隔天数
Data_bak_all_flies="/root/"      #要备份的数据源位置，如果要备份/root/AllFiles/下的文件，将/root/AllFiles/填此处
Data_bak_all_path="/root/AllFiles/backups/data_backups.tar.gz"          # 数据全量备份文件路径

#=====================功能三  系统备份（差异）=========================
# 说明：脚本运行既会进行差异备份，可选排除文件，详情看自定义备份区（需要rsync功能支持）
System_bak_diff_switch=false # 功能启用选项
System_bak_diff_path="/root/AllFiles/backups/system_backups_diff"       # 系统差异备份文件路径


#=====================功能四  数据备份（差异）=========================
# 说明：脚本运行既会进行差异备份，可选排除文件，详情看自定义备份区（需要rsync功能支持）
Data_bak_diff_switch=false   # 功能启用选项
Data_bak_diff_files="/root/"      # 需要进行差异备份的源文件路径
Data_bak_diff_path="/root/AllFiles/backups/data_backups_diff"        # 数据差异备份文件目标存放路径


#=====================功能五  WebDAV上传设置区==========================
# WebDAV只支持全量备份上传(需要curl功能支持)
Data_Up_WebDAV_switch=false       # 功能启用选项
WebDAV_Url="http://192.168.11.3:5244/dav/"     # webDAV挂载url，确保目录可挂载
WebDAV_User="backups"                 # WebDAV账号
WebDAV_Pass="0000"                # WebDAV密码


#=====================自定义数据备份区=========================

# 数据备份（全量）
function Data_bak_all() {

    #   函数说明：
    #   备份/root/目录下的文件，排除"/root/AllFiles/*"的文件等,备份为tar.gz格式
    #   "--exclude"参数为排除的备份目录
    #   "--one-file-system"参数为排除挂载点
    #   最后的"/root/"为备份起始目录
    mkdir -p $(dirname "$Data_bak_all_path")
    tar -cpzf $Data_bak_all_path \
        --exclude=AllFiles \
        --exclude=*.log \
        --one-file-system \
        $Data_bak_all_flies
    export data_b_a=true
    echo -e "${GREEN}✅数据备份（全量）完成${NC}"
    sed -n '24,25p' "$0"      # 打印行代码
}

# 数据备份（差异）
function Data_bak_diff() {
    #   函数说明：
    #   备份/root/目录下的文件，排除"/root/AllFiles/*"的文件等
    #   "--exclude"参数为排除的备份目录
    #   "--one-file-system"参数为排除挂载点
    mkdir -p $Data_bak_diff_path
    rsync -au --delete \
        --exclude=AllFiles \
        --exclude=*.log \
        $Data_bak_diff_files $Data_bak_diff_path
    export data_b_d=true
    echo -e "${GREEN}✅数据备份（差异）完成${NC}"
    sed -n '24,25p' "$0"      # 打印行代码
}

#=====================备份系统(固定)=========================

# 系统备份（全量）
function System_bak_all() {
    mkdir -p $(dirname "$System_bak_all_path")
    tar -cpzf $System_bak_all_path \
        --exclude=$System_bak_all_path \
        --exclude=proc/* \
        --exclude=sys/* \
        --exclude=dev/* \
        --exclude=tmp/* \
        --exclude=var/tmp/* \
        --exclude=var/cache/* \
        --exclude=var/log/* \
        --exclude=var/spool/* \
        --exclude=mnt/* \
        --exclude=run/* \
        --exclude=media/* \
        --one-file-system \
        / \
        2>/dev/null
    export system_b_a=true
    echo -e "${GREEN}✅系统备份（全量）完成${NC}"
    sed -n '24,25p' "$0"      # 打印行代码
}

# 系统备份（差异）
function System_bak_diff() {
    mkdir -p $System_bak_diff_path
    rsync -au --delete \
        --exclude=proc/* \
        --exclude=sys/* \
        --exclude=dev/* \
        --exclude=tmp/* \
        --exclude=var/tmp/* \
        --exclude=var/cache/* \
        --exclude=var/log/* \
        --exclude=var/spool/* \
        --exclude=mnt/* \
        --exclude=run/* \
        --exclude=media/* \
        / "$System_bak_diff_path" \
        2>/dev/null
    export system_b_d=true
    echo -e "${GREEN}✅数据备份（差异）完成${NC}"
    sed -n '24,25p' "$0"      # 打印行代码
}

# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
GRAY='\033[1;30m'  # 深灰色
NC='\033[0m' # 没有颜色（重置）

#=====================打印配置信息=========================
# 运行打印签名的几行代码
clear
sed -n '2,24p' "$0"
sed -n '24,25p' "$0"      # 打印行代码
if [ "$System_bak_all_switch" = true ]; then
    echo -e "${GREEN}系统备份（全量）：开启✅${NC}"
else
    echo -e "${GRAY}系统备份（全量）：关闭❌${NC}"
fi
if [ "$Data_bak_all_switch" = true ]; then
    echo -e "${GREEN}数据备份（全量）：开启✅${NC}"
else
    echo -e "${GRAY}数据备份（全量）：关闭❌${NC}"
fi
if [ "$System_bak_diff_switch" = true ]; then
    echo -e "${GREEN}系统备份（差异）：开启✅${NC}"
else
    echo -e "${GRAY}系统备份（差异）：关闭❌${NC}"
fi
if [ "$Data_bak_diff_switch" = true ]; then
    echo -e "${GREEN}数据备份（差异）：开启✅${NC}"
else
    echo -e "${GRAY}数据备份（差异）：关闭❌${NC}"
fi
if [ "$Data_Up_WebDAV_switch" = true ]; then
    echo -e "${GREEN}WebDAV上传：开启✅"
else
    echo -e "${GRAY}WebDAV上传：关闭❌"
fi

echo -e "${BLUE}3秒后开始备份...${NC}"
sleep 3

sed -n '24,25p' "$0"      # 打印行代码


#=====================备份逻辑=========================
# 系统备份（差异）
if [ "$System_bak_diff_switch" = true ]; then
    if command -v rsync &> /dev/null; then
        echo -e "${BLUE}开始系统备份（差异）...请耐心等待...${NC}"
        System_bak_diff
    else
        echo -e "${RED}❌未安装rsync，无法进行差异备份❌${NC}"
        sed -n '24,25p' "$0"      # 打印行代码
    fi
fi

# 数据备份（差异）
if [ "$Data_bak_diff_switch" = true ]; then
    if command -v rsync &> /dev/null; then
        echo -e "${BLUE}开始数据备份（差异）...请耐心等待...${NC}"
        Data_bak_diff
    else
        echo -e "${RED}❌未安装rsync，无法进行差异备份❌${NC}"
        sed -n '24,25p' "$0"      # 打印行代码
    fi
fi


# 系统备份（全量）
if [ "$System_bak_all_switch" = true ]; then
    if [ ! -f "$System_bak_all_path" ]; then
        echo -e "${BLUE}开始系统备份（全量）...请耐心等待...${NC}"
        System_bak_all
    elif find "$System_bak_all_path" -mtime +$System_bak_all_days | grep -q "$System_bak_all_path"; then
        echo -e "${BLUE}开始系统备份（全量）...请耐心等待...${NC}"
        System_bak_all
    else
        echo -e "${YELLOW}系统备份（全量）未到间隔时间${NC}"
        sed -n '24,25p' "$0"      # 打印行代码
    fi
fi

# 数据备份（全量）
if [ "$Data_bak_all_switch" = true ]; then
    if [ ! -f "$Data_bak_all_path" ]; then
        # 文件不存在，进行备份
        echo -e "${BLUE}开始数据备份（全量）...请耐心等待...${NC}"
        System_bak_all
    elif find "$Data_bak_all_path" -mtime +$Data_bak_all_days | grep -q "$Data_bak_all_path"; then
        echo -e "${BLUE}开始数据备份（全量）...请耐心等待...${NC}"
        Data_bak_all
    else
        echo -e "${YELLOW}数据备份（全量）未到间隔时间${NC}"
        sed -n '24,25p' "$0"      # 打印行代码
    fi
fi


#=====================WebDAV备份逻辑=========================
function WebDAV_Up() {
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}❌没有安装curl，无法使用WebDAV功能...❌${NC}"
        return 1
    fi
    if [ "$Data_Up_WebDAV_switch" = true ]; then
        Now_Date=$(date +"%Y-%m-%d_%H-%M-%S")
        if [ "$data_b_a" = true ]; then
            echo -e "${BLUE}开始数据备份（全量）上传...${NC}"
            r=$(curl -s -T "$Data_bak_all_path" -u "$WebDAV_User:$WebDAV_Pass" "$WebDAV_Url/$Now_Date$(basename "$Data_bak_all_path")")
            if echo "$r" | grep -q "Created"; then
                echo -e "${GREEN}✅数据备份（全量）上传完成。${NC}"
            else
                echo -e "${RED}❌数据备份（全量）上传失败。❌${NC}"
            fi
        fi
        if [ "$system_b_a" = true ]; then
            echo -e "${BLUE}开始系统备份（全量）上传...${NC}"
            r=$(curl -s -T "$System_bak_all_path" -u "$WebDAV_User:$WebDAV_Pass" "$WebDAV_Url/$Now_Date$(basename "$System_bak_all_path")")
            if echo "$r" | grep -q "Created"; then
                echo -e "${GREEN}✅系统备份（全量）上传完成。${NC}"
            else
                echo -e "${RED}❌系统备份（全量）上传失败。❌${NC}"
            fi
        fi
        if [ "$data_b_a" = true ] || [ "$system_b_a" = true ]; then
            sed -n '24,25p' "$0"      # 打印行代码
        fi
    fi
}
if ! WebDAV_Up; then
    sed -n '24,25p' "$0"      # 打印行代码
fi


echo -e "${YELLOW}备份脚本运行结束${NC}"
echo
sed -n '24,25p' "$0"      # 打印行代码