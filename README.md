# docker-tunnel-nezha

nezha over cloudflare tunnel

**still on testing**

**NOTICE**

> ONLY support x64 platform  
> AUTO backup and upgrade  
> MANUALLY restore   
> if you have any nice idea, please ISSUE  

## DEMO

![demo](https://pic.2rmz.com/1734947847381.png)

## HOW TO USE

### 0 build

```bash
git clone https://github.com/Tom-Aryx/docker-tunnel-nezha
cd docker-tunnel-nezha
docker build -t your-tag .
```

### 1 cloudflare tunnel

![public hostname](https://pic.2rmz.com/1734929821974.png)

![tls & http2](https://pic.2rmz.com/1734929824944.png)

### 2 run

**variables**
```bash
# required
ARGO_DOMAIN='test.example.com'
ARGO_TOKEN='ey****J9'

# optional
# use Bcrypt to generate, online tool link: https://bcrypt.online/
ADMIN_SECRET='$2a$10$pGBH10RM.LDvQREgrz60G.cP77QlrIbQVRCJ3ygB2pwKMUN8GiucW'
# agent connection secret
CLIENT_SECRET='mUI1****96qU'
# local agent uuid
AGENT_UUID='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
```

**run in docker**
```bash
docker run -d \
  -e ARGO_DOMAIN='test.example.com' \
  -e ARGO_TOKEN='ey****J9' \
  -e ADMIN_SECRET='$2a$10$pGBH10RM.LDvQREgrz60G.cP77QlrIbQVRCJ3ygB2pwKMUN8GiucW' \
  -e CLIENT_SECRET='mUI1****96qU' \
  -e AGENT_UUID='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' \
  --name "Dashboard" \
  your-tag
```

### 3 backup & restore

### 4 upgrade

## INSPIRATION

[nezhahq/nezha](https://github.com/nezhahq/nezha)  
[nezhahq/agent](https://github.com/nezhahq/agent)  
[fscarmen2/Argo-X-Container-PaaS](https://github.com/fscarmen2/Argo-X-Container-PaaS)  
[fscarmen2/Argo-Nezha-Service-Container](https://github.com/fscarmen2/Argo-Nezha-Service-Container)
