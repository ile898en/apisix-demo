```shell

# to create a route
curl http://apisix:9180/apisix/admin/routes/1 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -i -d '
{
    "uri": "/user/*",
    "upstream_id": "1"
}'

# See Doc: https://apisix.apache.org/zh/docs/apisix/admin-api/#route
# A route json sample:
{
    "id": "1",                            # id，非必填
    "uris": ["/a","/b"],                  # 一组 URL 路径
    "methods": ["GET","POST"],            # 可以填多个方法
    "hosts": ["a.com","b.com"],           # 一组 host 域名
    "plugins": {},                        # 指定 route 绑定的插件
    "priority": 0,                        # apisix 支持多种匹配方式，可能会在一次匹配中同时匹配到多条路由，此时优先级高的优先匹配中
    "name": "路由 xxx",
    "desc": "hello world",
    "remote_addrs": ["127.0.0.1"],        # 一组客户端请求 IP 地址
    "vars": [["http_user", "==", "ios"]], # 由一个或多个 [var, operator, val] 元素组成的列表
    "upstream_id": "1",                   # upstream 对象在 etcd 中的 id ，建议使用此值
    "upstream": {},                       # upstream 信息对象，建议尽量不要使用
    "timeout": {                          # 为 route 设置 upstream 的连接、发送消息、接收消息的超时时间。
        "connect": 3,
        "send": 3,
        "read": 3
    },
    "filter_func": ""                     # 用户自定义的过滤函数，非必填
}
```