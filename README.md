
# Redis Open Source Logical Databases Extractor

This script creates RDB snapshots for each logical database of a Redis open source instance. 

All logical databases in a Redis open source instance are persisted in the same RDB file. Manually creating RDB files for each logical namespace requires a repetitive process of loading, flushing and restarting an intermediate server.

This script automates this process using an intermediate Redis instance launched as a child process. 

## Prerequisites

- Check that you have installed redis-server and redis-cli. If you need to, you can edit the $rediscli and $redisserver variables at the beginning of the script to use the correct paths to your installations.
- Check that your redis-server version is 4.x, 5.x, 6.0.x, or 6.2.x. 
- Make sure that port 6381 is free. If it is not, then you can use another port by :
  - Updating the $intport variable in the script to the port you want
  - Updating the "port" directive in confs/redis.conf.
- This script assumes that you have a Redis database with the default number of 16 logical databases in its configuration file.

## Usage

```sh
./logical.sh -h HOST -p PORT -v 6.2
OPTIONAL : -a REDIS_PASSWORD
```
HOST, PORT being the host and the port of your source database.
The Redis version can be 6.2, 6.0, 5, or 4.

If your source database has a password, you can :
- Pass an -a flag followed by your password, or
- Edit the $password variable in the script


## Output : 

The script will create 17 files in the "output" folder : 
- one file per logical database (0.rdb, 1.rdb, 2.rdb...)
- one source.rdb file, the initial backup of your source database. 

# Troubleshooting :

- Check the right path on your machine to run redis-server and/or redis-cli. If necessary, edit the $redis-cli and $redisserver variables at the beginning of the script.
- Verify port 6381 is available
- If it is not, then you can :
  - update the $intport variable in the script to the port you want
  - update the "port" directive in the appropriate version of the redis.conf file for the redis-server version you have on your machine
- Check nohup.out file for any errors when launching the background Redis instance
- Check permissions and password for the default user of your source Redis instance
- Check that you have passed the correct version of your redis-server installation to the script


## Importing into Redis Enterprise

You can use these extracted RDB files to import your logical databases to Redis Enterprise databases. See the different import options here :
- [Redis Enterprise Software](https://docs.redis.com/latest/rs/databases/import-export/import-data/)
- [Redis Enterprise Cloud](https://docs.redis.com/latest/rc/databases/import-data/)
