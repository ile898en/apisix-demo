```shell
# To create a upstream with id. (use PATCH to update an exist upstream)
curl http://127.0.0.1:9180/apisix/admin/upstreams/{id}  -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -i -X PUT -d '
{
    "type":"roundrobin",
    "nodes":{
        "127.0.0.1:1980": 1
    }
}'

# See Doc: https://apisix.apache.org/zh/docs/apisix/admin-api/#upstream
# A upstream json sample:
{
    "id": "1",                  # id
    "retries": 1,               # 请求重试次数
    "timeout": {                # 设置连接、发送消息、接收消息的超时时间，每项都为 15 秒
        "connect":15,
        "send":15,
        "read":15
    },
    "nodes": {"host:80": 100},  # 上游机器地址列表，格式为`地址 + 端口`
                                # 等价于 "nodes": [ {"host":"host", "port":80, "weight": 100} ],
    "type":"roundrobin",
    "checks": {},               # 配置健康检查的参数
    "hash_on": "",
    "key": "",
    "name": "upstream-xxx",     # upstream 名称
    "desc": "hello world",      # upstream 描述
    "scheme": "http"            # 跟上游通信时使用的 scheme，默认是 `http`
}
```