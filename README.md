# ipfs-docker-webserver
IPFS webserver powered by apache2 as docker container

# Usage
`docker run -d -e IPNS_URL=yourdomain.com -p 8090:80 mkg20001/ipfs-docker-webserver`

Now the webserver should be running on 0.0.0.0:8090

### Env

`IPNS_URL`: The IPNS url of you page (e.g `Qm...` or `ipfs.io`)

`IPFS_URL`: Arbitrary link that go-ipfs can serve (e.g `/ipfs/Qm...`)

`PASSTHROUGH`: Just pass all request as-is to the server while still setting the cache headers

# Links

### [ » Demo ](http://94.130.45.83:8090/)

### [ » Learn more ](https://github.com/ipfs/examples/tree/master/examples/websites)
