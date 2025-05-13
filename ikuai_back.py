# -*- coding: utf-8 -*-

'''
导出ikuai配置文件脚本
作者：dsmggm
时间：2025-5-13
版本：1.0
说明：
登录ikuai网页后台，抓取passwd,pass,username
保存的配置文件位于脚本同目录下
cron: 1 1 1 1 *
一个月运行备份一次
'''

# 登录信息变量
ip = '192.168.22.1'
username  = 'admin'
passwd = '123'
pass_value = '123=='

import requests
import os

login_url = f"http://{ip}/Action/login"
download_url = f"http://{ip}/Action/download?filename=router_config.bak"

# 请求登录数据
login_data = {
    "username": username,
    "passwd": passwd,
    "pass": pass_value,
    "remember_password": "true"
}

# 设置请求头
headers = {
    "Content-Type": "application/json;charset=UTF-8"
}

# 发送登录请求
session = requests.Session()
response = session.post(login_url, json=login_data, headers=headers)

# 检查返回结果是否为成功
try:
    result = response.json()
    if result.get("Result") == 10000 and result.get("ErrMsg") == "Success":
        print("登录成功，正在下载配置备份文件...")

        download_response = session.get(download_url)

        script_dir = os.path.dirname(os.path.abspath(__file__))
        file_path = os.path.join(script_dir, "router_config.bak")

        with open(file_path, 'wb') as file:
            file.write(download_response.content)

        print(f"文件已保存至 {file_path}")
    else:
        msg = result.get("ErrMsg")
        print(f"登录失败，原因：{msg}")
except requests.exceptions.JSONDecodeError:
    print("响应不是有效的 JSON 格式，请检查登录 URL 或 Cookie 设置")
    print("原始响应内容：", response.text)