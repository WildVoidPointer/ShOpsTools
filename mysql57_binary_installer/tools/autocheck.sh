echo '--------'

cat /mysql_init.log

echo '--------'

journalctl -u mysql

echo '--------'

ls -lh /var/lib/mysqld

echo '--------'

ls -lh /var/log/mysqld

echo '--------'

ls -lh /var/lib/mysqld/data

echo '--------'

ls -lh /var/lib/mysqld/binlog
