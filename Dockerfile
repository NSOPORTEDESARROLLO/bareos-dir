FROM 			debian:stretch 
MAINTAINER 		cnaranjo@nsoporte.com



RUN				apt-get update; \ 
				apt-get -y upgrade; \
				apt-get -y install wget gnupg2




#Install Bareos Repo
RUN				wget -q http://download.bareos.org/bareos/release/latest/Debian_9.0/Release.key \
				-O- | apt-key add -; \
				echo "deb http://download.bareos.org/bareos/release/latest/Debian_9.0/ /" \
				 > /etc/apt/sources.list.d/bareos.list; \
				 apt-get update


#Install Bareos Director
ENV  			DEBIAN_FRONTEND noninteractive

RUN				apt-get install -y bareos-director; \
				apt-get install -y  bareos-database-mysql bareos-bconsole; \
				tar -czvf /opt/bareos-etc-dir.tgz /etc/bareos; \
				cd /usr/share/dbconfig-common/data/bareos-database-common; \					
				tar -czvf /opt/db.tgz  .; \
				rm -rf /etc/bareos; mkdir /etc/bareos; mkdir /db



#Starting Files
COPY			files/ns-start /usr/bin/

RUN				chmod +x /usr/bin/ns-start

ENTRYPOINT		[ "/usr/bin/ns-start" ]










