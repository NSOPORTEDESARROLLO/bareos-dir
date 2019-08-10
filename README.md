## bareos-dir

Bareos Director on Docker container 


## Volumes

* /db = Where database scrpts will be copy.
* /etc/bareos = Config files  
* /catalog_backup = Baros catalog database backup

## NOTE:

If container is running on same bareos director host you may need a catalog backup, I recommend create a volume:

* docker volume create bareos-catalog

## RUN:

docker run --name=bareos-dir --net=host --restart=always -v /etc/localtime:/etc/localtime:ro -v /data/apps/bareos-dir/etc:/etc/bareos -v /data/apps/bareos-dir/db:/db -v bareos-catalog:/catalog_backup -d nsoporte/bareos-dir 