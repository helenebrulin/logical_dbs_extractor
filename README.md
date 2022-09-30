
# Introduction

This script creates RDB snapshots for each logical database of your Redis open source instance. 
All logical databases in a Redis open source instance are persisted in the same RDB file. Manually creating RDB files for each logical namespace requires a repetitve loading, flushing and restarting process of an intermediate server.
This script automates this process on an intermediate Redis instance that it launches as a child process. 

## Prerequisites

- Check that you have installed redis-server and redis-cli. If you don't have the relevant directory in your $PATH environment variable, then you can edit the $redis-cli and $redisserver variables at the beginning of the script.
- Check which version of redis-server you have
- Make sure that port 6371 is free. If it is not, then you can :
  - update the $intport variable in the script to the port you want
  - update the "port" directive in the appropriate version of the redis.conf file for the redis-server version you have on your machine

## Usage :

Clone this repository on your machine.
Run:
```sh
./logic.sh -h HOST -p PORT -v REDIS_SERVER_VERSION:6.2/6.0/5/4
```

HOST and PORT being the host and the port of your source database. 

If your database has a password, you can :
- optionnally pass an -a flag followed by your password
- edit the $password variable in the script


## Output : 

You will get 17 new files in the "output" folder : 
- one file per logical database (1.rdb, 2.rdb...)
- one source.rdb file, the initial backup of your source database. 


# Troubleshooting :

- Verify port 6381 is available
- If it is not, then you can :
  - update the $intport variable in the script to the port you want
  - update the "port" directive in the appropriate version of the redis.conf file for the redis-server version you have on your machine
- Check the right path on your machine to run redis-server and/or redis-cli. If necessary, edit the $redis-cli and $redisserver variables at the beginning of the script.
- Check nohup.out file
- Check permissions and password for the default user of your source Redis instance


## Importing into Redis Enterprise

You can use these files to import your first logical database data to a Redis Enterprise Database. See the different import options here :
- [Redis Enterprise Software](https://docs.redis.com/latest/rs/databases/import-export/import-data/)
- [Redis Enterprise Cloud](https://docs.redis.com/latest/rc/databases/import-data/)


# logical_dbs_extractor
