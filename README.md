# ApacheAccessLogs
Apache Access Logs to write in MySQL DB
To run the script we have to follow below steps.
$ ./apachelog2mysql.pl {log path(s)} {mysql db credentials}
$ ./apachelog2mysql.pl "/var/www/test/test.log, /var/www/test1/test1.log" "localhost:mydb:user1:secretpass"

We can schedule this script too using Cron to run at specific intervals.Like below an example.

*/10 * * * * ./apachelog2mysql.pl {log(s)} {mysql info} &> /opt/test/cron.log


Also, The only configuration setting is the table name that the script will use for the Apache log(s), to change this setting edit this like in the script file:

my %conf = ( 
      "table_name" => "apachelog" # edit table name here 
);
