# -*- coding: utf-8 -*-

'''
导出immortalwrt配置文件脚本
作者：dsmggm
时间：2025-5-13
版本：1.0
说明：
保存的配置文件位于脚本同目录下
'''

import requests

ip = "192.168.11.2"
luci_username = "root"
luci_password = "123"

# 登录URL
login_url = f'http://{ip}/cgi-bin/luci/'
backup_url = f'http://{ip}/cgi-bin/cgi-backup'

# 设置请求头
headers = {
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Language': 'zh-CN,zh;q=0.9',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
    'Content-Type': 'application/x-www-form-urlencoded',
    'Origin': f'http://{ip}',
    'Pragma': 'no-cache',
    'Referer': f'http://{ip}/cgi-bin/luci/',
    'Upgrade-Insecure-Requests': '1',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0'
}

# 登录表单数据
login_data = {
    'luci_username': luci_username,
    'luci_password': luci_password
}

try:
    # 创建会话
    session = requests.Session()
    
    # 先访问登录页面获取初始cookie
    session.get(login_url, headers=headers)
    
    # 发送POST请求登录
    login_response = session.post(
        login_url, 
        data=login_data, 
        headers=headers,
        allow_redirects=False  # 不自动跟随重定向
    )
    if "sysauth_http" in session.cookies:
        print("登录成功，正在下载配置备份文件...")
        # 下载备份
        download_response = session.get(backup_url)

        with open("backup-ImmortalWrt.tar.gz", 'wb') as file:
            file.write(download_response.content)
        print(f"文件已保存")
    else:
        print("登录失败")
except Exception as e:
    print(f'发生错误: {str(e)}')
