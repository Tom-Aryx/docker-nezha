# docker-nezha

alpine container, nezha, nezha-agent 

**still on testing**

**NOTICE**

> ONLY support x64 platform  
> AUTO backup, upgrade and restore   
> if you have any nice idea, please ISSUE  

## DEMO

![demo](https://pic.2rmz.com/1734947847381.png)

## HOW TO USE

### 1 Docker

**variables**
```bash
# optional
# jwt secret key, random string of any length
JWT_SECRET='cP77QlrIbQVRCJ3ygB2pwKMUN8GiucW'
# agent connection secret
AGENT_SECRET='mUI1****96qU'
# local agent uuid
AGENT_UUID='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
# dashboard domain with port (80 or 443 or any)
NEZHA_DOMAIN='panel.nezha.fun:443'
# restore from github repo
GITHUB_REPO='https://your-personal-access-token@github.com/YOU/your_repo'
# if set, restore at first starting. otherwise, GITHUB_REPO is useless.
AUTO_RESTORE=1
```

**run in docker**
```bash
docker run -d \
  -p 8080:8080 \
  -e JWT_SECRET='cP77QlrIbQVRCJ3ygB2pwKMUN8GiucW' \
  -e AGENT_SECRET='mUI1****96qU' \
  -e AGENT_UUID='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' \
  -e NEZHA_DOMAIN='panel.nezha.fun:443' \
  --name "Dashboard" \
  taryx/docker-nezha:latest
```

### 2 Backup & Restore

**BACKUP**

- cron and type set whatever you want
- command must be `/app/scripts/backup.sh 'https://your-personal-access-token@github.com/YOU/your_repo'`
- select the `Local` server
- notify or not

![image](https://pic.2rmz.com/1738659942609.png)

**Manual RESTORE**

- same as **BACKUP**
- command set to `/app/scripts/restore.sh 'https://your-personal-access-token@github.com/YOU/your_repo'`

![image](https://pic.2rmz.com/1738659944416.png)

### 3 upgrade

- command set `/app/scripts/upgrade.sh`

![image](https://pic.2rmz.com/1738659946785.png)

## BUILD

```bash
git clone https://github.com/Tom-Aryx/docker-nezha
cd docker-nezha
docker build -t your-tag .
```

### INSPIRATION

[nezhahq/nezha](https://github.com/nezhahq/nezha)  
[nezhahq/agent](https://github.com/nezhahq/agent)  
[fscarmen2/Argo-X-Container-PaaS](https://github.com/fscarmen2/Argo-X-Container-PaaS)  
[fscarmen2/Argo-Nezha-Service-Container](https://github.com/fscarmen2/Argo-Nezha-Service-Container)
