# Use Docker Compose to develop lineblocs - asterisk

## Structure of directory
```shell
.
.
├── configs
├── dev
|  ├── docker-compose.yaml
|  ├── .env
|  └── README.md
├── Dockerfile
├── entrypoint.sh
└── irontec.list
```

## Simple running
```shell
$ git clone https://github.com/Lineblocs/asterisk.git
$ cd asterisk/dev
$ cp .env.example .env
$ docker compose up -d
```

## Advance running

### Clone user-app project 
Clone docker compose and move to directory.
```shell
$ git clone https://github.com/Lineblocs/asterisk.git
$ cd asterisk/dev
```

### Make .env file and confige
```shell
$ cp .env.example .env
```
`AMI_HOST`
`AMI_PORT`
`AMI_USER`
`AMI_PASS`

`ARI_USERNAME`
`ARI_PASSWORD`

`LINEBLOCS_KEY`


###  create container
Create and run container with this command below. 

```shell
$ docker compose up -d
```

### Useful command
Check node log  `docker logs -f lineblocs-asterisk`

Log in to terminal of container  -> `docker exec -it lineblocs-asterisk bash`

Modify asterisk project under `asterisk` directory

After change configuration, Please run `docker compose restart`
