Shell工具连上服务器后输入如下代码安装节点

一、安装必要的组件
```bash
apt update -y
apt upgrade -y
apt install curl -y
apt install iptables -y
```

二、安装证书
```bash
apt --no-install-recommends -y install wget ca-certificates || (apt update && apt --no-install-recommends -y install wget ca-certificates)
```

三、下载安装脚本
```bash
wget -O Xray-TLS+Web-setup.sh https://raw.githubusercontent.com/iplanetcn/Xray-script-with-NextCloud-Docker/main/Xray-TLS%2BWeb-setup.sh
chmod +x Xray-TLS+Web-setup.sh
```
四、执行脚本（重要：将 域名 替代为自己的域名）
```bash
bash Xray-TLS+Web-setup.sh 域名
```
五、安装完成后，可以在复制对应的地址，在代理软件（如：ShadowRocket）中进行测试