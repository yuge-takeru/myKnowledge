#!/bin/bash

echo "start.shを開始しました"

# システム全体へ環境変数パスを設定する
sh -c 'echo "export PATH=$PATH:/usr/pgsql-16/bin" >> /etc/profile'
# 文字化け防止
sh -c 'echo "export LANG=ja_JP.UTF-8" >> /etc/profile'
sh -c 'export LC_CTYPE=ja_JP.UTF-8'

# DB起動
#su - postgres -c "pg_ctl -D /var/lib/pgsql/16/data start"
su - postgres -c "/usr/pgsql-16/bin/pg_ctl -D /var/lib/pgsql/16/data start"
echo "DBを起動しました"

# Start Nginx
# nginx -g "daemon off;" &
#nginx -g "daemon off;"
# echo "nginxを起動しました"


# Start Supervisord
# ssh,rsyslog,chrony
#supervisord -c /etc/supervisord.conf
supervisord -c /etc/supervisord/supervisord.conf &
echo "supervisordを起動しました"


# Keep the container running
tail -f /dev/null

