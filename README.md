# 一个主从高可靠保障，但不带持久化的REDIS编排
##简介
1主1从，2个哨兵，不带持久化。其中从节点个数和哨兵个数可以设置。
6秒钟的失效监测、12秒的主从切换超时
使用方式：

	1.必须在网内，抱歉
	2.通过哨兵查找master。
	redis-cli -h sb-instanceid-redis -p 26379 --csv SENTINEL get-master-addr-by-name mymaster | tr ',' ' ' | cut -d' ' -f1)
	3.直接连接redis
	redis-cli -h 刚获得的地址 -p 6379
	4.auth
	auth 密码
##生成
	1.执行初始化编排redis-master.yaml。
	需要替换其中的服务名字（要和后面的哨兵服务名字一致）
	要替换instanceid
	要替换密码
	端口一般不用替换。
	
	2.执行哨兵服务的编排redis-sentinel-service.yaml
	注意里面的名字
	
	3.执行从redis编排redis-controller.yaml
	数量可以自己做，不过要慎重一点：）
	注意替换如1种的几个东西
	
	4.执行高可用的哨兵编排redis-sentinel-controller.yaml
	注意同上
	
##绑定
直接返回密码，没有用户一说，所以很简单
##注意事项
暂时没有想到其他

