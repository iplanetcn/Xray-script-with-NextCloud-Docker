#!/bin/bash

if [[ $# -eq 0 ]]; then
    echo -e "\033[5;41;34m此脚本必须带参数运行\033[0m"
    exit 1
fi

while [[ $# -ge 2 ]]; do
    case $1 in
        '--ssl-domain')
            shift
            if [[ -z $1 ]] || [[ $1 == -* ]]; then
                echo -e "\033[5;41;34m此脚本至少需要一个解析到本服务器的域名\n请补充域名后重新运行脚本！形如hostname.your.domain\033[0m"
                exit 1
            else
                sslDomain="$1"
                echo -e "\033[5;41;34m您输入的域名是：${sslDomain}\033[0m"
                if [ "$(echo -n "$domain" | wc -c)" -gt 46 ]; then
                    echo -e "\033[5;41;34m域名过长！请调整域名后重新运行脚本！\033[0m"
                    exit 1
                fi
            fi
            shift
        ;;

        '--fake-domain')
            shift
            if [[ -z $1 ]] || [[ $1 == -* ]]; then
                echo -e "\033[5;41;34m如选择反向代理伪装网站，则需要填写一个http网址！\033[0m"
                exit 1
            else
                fakeUrl="$1"
                echo -e "\033[5;41;34m您输入的反向代理伪装网址是：${fakeUrl}\033[0m"
            fi
            shift
        ;;

        '--NextCloud-admin-usr')
            shift
            if [[ -z $1 ]] || [[ $1 == -* ]]; then
                echo -e "\033[5;41;34m需要正确配置NextCloud管理员！\033[0m"
                exit 1
            else
                ncAdmin="$1"
                echo -e "\033[5;41;34m您输入的NextCloud管理员名称是：${ncAdmin}\033[0m"
            fi
            shift
        ;;

        '--NextCloud-admin-pwd')
            shift
            if [[ -z $1 ]] || [[ $1 == -* ]]; then
                echo -e "\033[5;41;34m需要正确配置NextCloud管理员密码！\033[0m"
                exit 1
            else
                ncAdminPwd="$1"
                echo -e "\033[5;41;34m您输入的NextCloud管理员密码是：${ncAdminPwd}\033[0m"
            fi
            shift
        ;;

        '--NextCloud-DB-pwd')
            shift
            if [[ -z $1 ]] || [[ $1 == -* ]]; then
                echo -e "\033[5;41;34m需要正确配置NextCloud数据库密码！\033[0m"
                exit 1
            else
                ncDatabasePwd="$1"
                echo -e "\033[5;41;34m您输入的NextCloud数据库密码是：${ncDatabasePwd}\033[0m"
            fi
            shift
        ;;
    esac
done

if ! [[ -v sslDomain ]]; then
    echo -e "\033[5;41;34m指向域名是必需的！\033[0m"
    exit 1
elif [[ ! (-v ncAdmin && -v ncAdminPwd && -v ncDatabasePwd) && -z $fakeUrl ]]; then
    echo -e "\033[5;41;34m要么装网盘要么正常简单用，也不能缺选项\033[0m"
    exit 1
elif [[ (-v ncAdmin || -v ncAdminPwd || -v ncDatabasePwd) && -v fakeUrl ]]; then
    echo -e "\033[5;41;34m是二选一啦！不能两个都要！达咩！\033[0m"
    exit 1
fi


# start of the script
rm -rf /home/nc /home/xr
mkdir /home/xr && cd /home/xr
apt update && apt --no-install-recommends -y install wget curl ca-certificates sshpass

if [[ -v fakeUrl ]]; then
    curl -fsL rebrand.ly/CamouSneak | bash -s -- $sslDomain $fakeUrl
    echo -e "\033[5;41;34m带有外部反向代理伪装网址的纯Xray服务端已部署完成！\033[0m"
else
    curl -fsL rebrand.ly/CamouSneak | bash -s -- $sslDomain

    curl -fsSL https://get.docker.com | bash

    docker network create NextCloudLAN

    docker run -d \
        --restart=unless-stopped \
        --network=NextCloudLAN \
        -e POSTGRES_USER=nextclouder \
        -e POSTGRES_PASSWORD=$ncDatabasePwd \
        -e PGDATA=/home/ncData \
        --name NextCloudDB \
        postgres:latest

    docker run -d \
        --restart=unless-stopped \
        --network=NextCloudLAN \
        -p 127.0.0.1:8080:80 \
        -v /home/nc:/var/www/html \
        -e NEXTCLOUD_ADMIN_USER=$ncAdmin \
        -e NEXTCLOUD_ADMIN_PASSWORD=$ncAdminPwd \
        -e NEXTCLOUD_TRUSTED_DOMAINS=$sslDomain \
        -e OVERWRITEPROTOCOL=https \
        -e OVERWRITECLIURL=https://$sslDomain \
        -e POSTGRES_DB=nextcloud \
        -e POSTGRES_USER=nextclouder \
        -e POSTGRES_PASSWORD=$ncDatabasePwd \
        -e POSTGRES_HOST=NextCloudDB \
        --name NextCloudIns \
        nextcloud:latest


    # Thankfully borrowed from https://stackoverflow.com/a/37410430
    (crontab -l; echo "*/5  *  *  *  * docker exec -d -u www-data NextCloudIns php --define apc.enable_cli=1 -f /var/www/html/cron.php") | crontab -

    echo -e "\033[5;41;34m高可迁移的NextCloud云盘实例已部署完成！\033[0m"
fi
