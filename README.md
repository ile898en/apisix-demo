# apisix-demo

## Description
基于<a href="https://github.com/apache/apisix-docker">apach/apisix-docker</a>项目下的example略作改动<br>

## QuickStart
更多信息请参考官方<a href="https://apisix.apache.org/zh/docs/apisix/getting-started/">快速入门指南</a>。
需要注意的是官方文档示例中默认访问apisix网关的端口是9080、9443，已经被我改成80、443了。

### 在apisix-demo目录下执行：
- x86
```shell
docker-compose -p docker-apisix up -d
```
- arm64
```shell
docker-compose -p docker-apisix -f docker-compose-arm64.yml up -d
```
### 访问控制台
```shell
http://localhost:9000
```
初始化用户名密码都是admin，可以在`dashboard_conf/conf.yaml`中配置：
```shell
authentication:
  secret:
    secret              # secret for jwt token generation.
                        # NOTE: Highly recommended to modify this value to protect `manager api`.
                        # if it's default value, when `manager api` start, it will generate a random string to replace it.
  expire_time: 3600     # jwt token expire time, in second
  users:                # yamllint enable rule:comments-indentation
    - username: admin   # username and password for login `manager api`
      password: admin
    - username: user
      password: user
```

## Modules
### apisix_conf
该目录下的`config.yaml`是apisix的配置文件，关于该配置文件的解释可以查看官方提供的<a href="https://github.com/apache/apisix/blob/master/conf/config-default.yaml">config-default.yaml</a>文件

值得注意的是，该配置文件中的`deployment: admin: admin_key`配置项用来定义访问apisix admin api的密钥，
建议修改掉文件中的默认值；

并且该项目中的`config.yaml`将apisix默认监听的9080、9443端口改为80、443
```yaml
apisix:
  node_listen: 80              # APISIX listening port
  enable_ipv6: false

  ssl:
    enable: true
    listen:
      - port: 443
```

### apisix_init
该目录下存放的都是一些需要初始化的数据文件以及shell脚本。创建该目录的本意是希望在apisix的server启动后，
自动初始化一些提前准备好的路由/upstream配置。 最初的想法是在apisix的docker容器启动时添加`ENTRYPOINT`，
但这样做会覆盖apisix本身的entry point配置，因此想到的解决办法就是在同一个网络环境内再启一个docker专门去做
初始化工作，初始化工作完成后该容器会自动停掉，不会占用有限的机器资源
#### cert
该目录下存放证书相关的文件，通常会有两个文件，一个证书文件一个key文件，例如：
- example.com.pem
- example.com.key.pem

如果你需要开启ssl并通过https访问，必须要在该目录下放入你的证书文件。`start.sh`脚本会在apisix server启动后扫描
该目录下的证书文件，并调用apisix admin api自动将证书添加至apisix网关

同时，你还需要更改`start.sh`脚本中的证书文件名：
```shell
# Replace with your cert file name TODO
cert_file_name=""
# Replace with your key file name TODO
key_file_name=""

# ...

if [ -n "${cert_file_name}" ] && [ -n "${key_file_name}" ]; then
  load_cert
fi
```
#### log
该目录下是`start.sh`脚本执行过程中生成的日志文件
#### routes
routes目录下存放的是一些需要初始化的路由信息<br>
See [ROUTES_SAMPLE.md](apisix_init/routes/route_sample.md)
#### upstream
upstream目录下存放的是一些需要初始化的upstream信息<br>
See [UPSTREAM_SAMPLE.md](apisix_init/upstream/upstream_sample.md)
#### Dockefile
apisix_init所依赖的docker文件
#### start.sh
apisix_init的核心代码。
该脚本会在apisix-init容器启动后开始执行，并首先sleep20秒，目的是等待apisix server完全启动；
之后会分别读取cert目录下的证书、routes目录下的routes.json、upstream目录下的upstream.json，并分别调用apisix 
admin api将读取到的数据初始化到apisix

### apisix_log
该目录下有apisix网关产生的一些日志文件：
- access.log
- error.log
- nginx.pid

### dashboard_conf
未深入研究，不做赘述
### etcd_conf
未深入研究，不做赘述
### etcd_data
未深入研究，不做赘述
### grafana_conf
未深入研究，不做赘述
### prometheus_conf
未深入研究，不做赘述