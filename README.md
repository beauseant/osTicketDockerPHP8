# This is the docker version to *migrate* your osTicket to Docker.

Work based on the code from: https://github.com/VincentSC/osTicket-Docker with the following modifications:

- The generated docker containers use PHP 8 to be able to use the latest versions of OsTicket.
- It allows two types of installation: 1) an installation from scratch configuring the database from scratch. 2) An installation using an already working database.

Files used:

- `update.sh` grabs the latest version of osTicket from Github
- `Dockerfile` builds a new Docker using Apache


## Fresh install:

``` 
./update.sh --fresh-install
docker build --tag 'osticketprueba' . -f Dockerfile_freshInstall 
docker run -d -p 4080:80 -it osticketprueba 
```

## Using an existing database

```
./update.sh
 docker build --tag 'osticketprueba' --build-arg DATABASE_NAME='osticket' --build-arg DATABASE_HOST='oshost' --build-arg DATABASE_USERNAME='osuser' --build-arg DATABASE_PASSWORD='ospasswd'   . -f Dockerfile
 docker run -d -p 4080:80 -it osticketprueba 
 ```

*In **ospasswd** scape special characters with \, for example ij&aiph is ij\&aiph*

## To update:

- run `update.sh`. Check for errors.
- run docker-compose up -d --build
- wait, as this takes several minutes


For first use, remove info.txt, else it wil be "up-to-date". Also add your old SALT into `ost-config.php`.
