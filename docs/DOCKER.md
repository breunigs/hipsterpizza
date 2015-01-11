## Using HipsterPizza with Docker

First, install Docker on your operating system. On Debian this can be achieved by `apt-get install docker.io`.

*Note:* For some reason Docker has problems with DNS resolution on my system. This can be alleviated by editing `/etc/default/docker` and uncommenting the `DOCKER_OPTS` line. Restart the Docker daemon afterwards: `service docker restart`.

### Pulling HipsterPizza

This grabs the release version (master branch), which is recommended. Use `:latest` if you want the devel version.
```
export HP_VERSION=breunigs/hipsterpizza:release
docker pull $HP_VERSION
```

### Setting it up

You’ll have two containers running: One which runs the actual HipsterPizza software and an additional one to hold the data. This way you can throw away the “runner” when updating, while preserving saved orders and other data.

```
docker run -d --name hipsterpizza_data -v /app/db $HP_VERSION echo 'Data Only'
docker run -d --name hipsterpizza_runner --volumes-from hipsterpizza_data \
    -p 10002:10002 $HP_VERSION
```

This will make HipsterPizza available on your machine on [http://localhost:10002](http://localhost:10002).

### Working with the docker instance

```
docker stop    hipsterpizza_runner
docker start   hipsterpizza_runner
docker restart hipsterpizza_runner

# start a shell to inspect the docker container while it is running:
docker exec -it hipsterpizza_runner bash
```

If you want to change configuration (e.g. editing `config/fax.yml`) store the file somewhere on your host system. Next run the following command:
```
docker exec -it hipsterpizza_runner bash -c \
    'cat > /app/config/fax.yml' < my_config/fax.yml
```
It’s a bit clunky, but `docker cp` does not allow files to be copied to the container yet. If you accidentally overwrite important files and the container exits immediately start fresh – this works just like described in the “Upgrading” section. Use this to see what crashes HipsterPizza: `docker start -ai hipsterpizza_runner`.

### Upgrading with Docker

```
docker pull $HP_VERSION
docker rm hipsterpizza_runner
docker run -d --name hipsterpizza_runner --volumes-from hipsterpizza_data \
    -p 10002:10002 $HP_VERSION
```

If you had modified files before, execute the copy statements again. Patches to improve the retention of config files are welcome.

### Further Reading

Please continue with the normal guide starting at [webserver integration](../README.md#webserver-integration).

## Building a new image

You can also build your own Docker image from HipsterPizza’s source. Below are the basic steps need to do this. Please refer to Docker’s documentation for everything else:

```
git clone git://github.com/breunigs/hipsterpizza
cd hipsterpizza
# (make some changes)
docker build --tag MYPIZZA .
docker run -d --name hipsterpizza_data -v /app/db MYPIZZA echo 'HipsterPizza Data Only'
docker run -d --name hipsterpizza_runner --volumes-from hipsterpizza_data -p 10002:10002 MYPIZZA
```
