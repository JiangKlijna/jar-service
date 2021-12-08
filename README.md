
## jar-service

### 解决痛点
	解决jar包运行方式两种问题
	*.不能注册系统服务的问题
	*.不能增量部署

### 项目起源
	为了解决自动化部署java项目
	但是自动化重启,部署tomcat等servlet容器,比较麻烦
	自动化部署jar包却很方便,同时可以解决jar的运行方式不足的问题

### 实现方式
	首先解压jar包,设置classpath为解压后的文件夹
	构造好java命令后,注册命令为系统服务

### 脚本
	jar-service.bat
	jar-service.sh(开发中)
	jar-service.ps1(开发中)

### 命令列表
	jar-service install	xxx.jar
	jar-service remove	xxx.jar
	jar-service regist	jar_dir
	jar-service unreg	jar_dir
	jar-service start	jar_dir
	jar-service stop	jar_dir
	jar-service reboot	jar_dir

### 参数详解
	install	解压jar包
	remove	删除解压的文件夹
	regist	注册为系统服务
	unreg	删除服务
	start	启动服务
	stop	停止服务
	reboot	重启服务

	[java_opts] jvm 运行参数默认值为(-Xms512m -Xmx1024m)
