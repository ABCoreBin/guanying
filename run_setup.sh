#!/bin/bash

# 下载远程脚本并保存为 setup.sh 文件
wget https://raw.githubusercontent.com/ABCoreBin/guanying/main/setup.sh -O setup.sh

# 授予脚本执行权限
chmod +x setup.sh

# 执行脚本并传递参数
./setup.sh "$@"
