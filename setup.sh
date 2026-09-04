============================================================
        ShopCI - DevOps Environment Setup
============================================================
[OK] Running as root.
[INFO] Operating System: Amazon Linux 2023.12.20260831

============================================================
Updating system packages...
============================================================
Last metadata expiration check: 0:10:19 ago on Fri Sep  4 11:13:37 2026.
Dependencies resolved.
Nothing to do.
Complete!

============================================================
Installing required packages...
============================================================
Last metadata expiration check: 0:10:19 ago on Fri Sep  4 11:13:37 2026.
Package git-2.50.1-1.amzn2023.0.1.x86_64 is already installed.
Package jq-1.8.1-60.amzn2023.x86_64 is already installed.
Package wget-1.21.3-1.amzn2023.0.5.x86_64 is already installed.
Package unzip-6.0-68.amzn2023.0.2.x86_64 is already installed.
Package tar-2:1.34-1.amzn2023.0.4.x86_64 is already installed.
Package gzip-1.12-1.amzn2023.0.1.x86_64 is already installed.
Package ca-certificates-2025.2.76-1.0.amzn2023.0.3.noarch is already installed.
Package openssl-1:3.5.7-2.amzn2023.0.2.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
[OK] Required packages installed.

Checking curl...
[OK] curl is available.

============================================================
Installing Docker...
============================================================
Last metadata expiration check: 0:10:20 ago on Fri Sep  4 11:13:37 2026.
Dependencies resolved.
===========================================================================================================================================================================================
 Package                                            Architecture                       Version                                               Repository                               Size
===========================================================================================================================================================================================
Installing:
 docker                                             x86_64                             25.0.16-1.amzn2023.0.4                                amazonlinux                              46 M
Installing dependencies:
 container-selinux                                  noarch                             4:2.245.0-1.amzn2023                                  amazonlinux                              58 k
 containerd                                         x86_64                             2.2.5-1.amzn2023.0.2                                  amazonlinux                              24 M
 iptables-libs                                      x86_64                             1.8.8-3.amzn2023.0.2                                  amazonlinux                             401 k
 iptables-nft                                       x86_64                             1.8.8-3.amzn2023.0.2                                  amazonlinux                             183 k
 libcgroup                                          x86_64                             3.0-1.amzn2023.0.1                                    amazonlinux                              75 k
 libnetfilter_conntrack                             x86_64                             1.0.8-2.amzn2023.0.2                                  amazonlinux                              58 k
 libnfnetlink                                       x86_64                             1.0.1-19.amzn2023.0.2                                 amazonlinux                              30 k
 libnftnl                                           x86_64                             1.2.2-2.amzn2023.0.2                                  amazonlinux                              84 k
 pigz                                               x86_64                             2.5-1.amzn2023.0.4                                    amazonlinux                              83 k
 runc                                               x86_64                             1.3.5-1.amzn2023.0.2                                  amazonlinux                             3.9 M

Transaction Summary
===========================================================================================================================================================================================
Install  11 Packages

Total download size: 76 M
Installed size: 284 M
Downloading Packages:
(1/11): container-selinux-2.245.0-1.amzn2023.noarch.rpm                                                                                                    1.8 MB/s |  58 kB     00:00    
(2/11): iptables-libs-1.8.8-3.amzn2023.0.2.x86_64.rpm                                                                                                       20 MB/s | 401 kB     00:00    
(3/11): iptables-nft-1.8.8-3.amzn2023.0.2.x86_64.rpm                                                                                                       6.2 MB/s | 183 kB     00:00    
(4/11): libcgroup-3.0-1.amzn2023.0.1.x86_64.rpm                                                                                                            1.9 MB/s |  75 kB     00:00    
(5/11): libnetfilter_conntrack-1.0.8-2.amzn2023.0.2.x86_64.rpm                                                                                             2.4 MB/s |  58 kB     00:00    
(6/11): libnfnetlink-1.0.1-19.amzn2023.0.2.x86_64.rpm                                                                                                      1.0 MB/s |  30 kB     00:00    
(7/11): libnftnl-1.2.2-2.amzn2023.0.2.x86_64.rpm                                                                                                           2.7 MB/s |  84 kB     00:00    
(8/11): pigz-2.5-1.amzn2023.0.4.x86_64.rpm                                                                                                                 3.3 MB/s |  83 kB     00:00    
(9/11): containerd-2.2.5-1.amzn2023.0.2.x86_64.rpm                                                                                                          79 MB/s |  24 MB     00:00    
(10/11): runc-1.3.5-1.amzn2023.0.2.x86_64.rpm                                                                                                               42 MB/s | 3.9 MB     00:00    
(11/11): docker-25.0.16-1.amzn2023.0.4.x86_64.rpm                                                                                                           81 MB/s |  46 MB     00:00    
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                      124 MB/s |  76 MB     00:00     
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                                                                   1/1 
  Installing       : runc-1.3.5-1.amzn2023.0.2.x86_64                                                                                                                                 1/11 
  Installing       : containerd-2.2.5-1.amzn2023.0.2.x86_64                                                                                                                           2/11 
  Running scriptlet: containerd-2.2.5-1.amzn2023.0.2.x86_64                                                                                                                           2/11 
  Installing       : pigz-2.5-1.amzn2023.0.4.x86_64                                                                                                                                   3/11 
  Installing       : libnftnl-1.2.2-2.amzn2023.0.2.x86_64                                                                                                                             4/11 
  Installing       : libnfnetlink-1.0.1-19.amzn2023.0.2.x86_64                                                                                                                        5/11 
  Installing       : libnetfilter_conntrack-1.0.8-2.amzn2023.0.2.x86_64                                                                                                               6/11 
  Installing       : iptables-libs-1.8.8-3.amzn2023.0.2.x86_64                                                                                                                        7/11 
  Installing       : iptables-nft-1.8.8-3.amzn2023.0.2.x86_64                                                                                                                         8/11 
  Running scriptlet: iptables-nft-1.8.8-3.amzn2023.0.2.x86_64                                                                                                                         8/11 
  Installing       : libcgroup-3.0-1.amzn2023.0.1.x86_64                                                                                                                              9/11 
  Running scriptlet: container-selinux-4:2.245.0-1.amzn2023.noarch                                                                                                                   10/11 
  Installing       : container-selinux-4:2.245.0-1.amzn2023.noarch                                                                                                                   10/11 
  Running scriptlet: container-selinux-4:2.245.0-1.amzn2023.noarch                                                                                                                   10/11 
  Running scriptlet: docker-25.0.16-1.amzn2023.0.4.x86_64                                                                                                                            11/11 
  Installing       : docker-25.0.16-1.amzn2023.0.4.x86_64                                                                                                                            11/11 
  Running scriptlet: docker-25.0.16-1.amzn2023.0.4.x86_64                                                                                                                            11/11 
Created symlink /etc/systemd/system/sockets.target.wants/docker.socket → /usr/lib/systemd/system/docker.socket.

  Running scriptlet: container-selinux-4:2.245.0-1.amzn2023.noarch                                                                                                                   11/11 
  Running scriptlet: docker-25.0.16-1.amzn2023.0.4.x86_64                                                                                                                            11/11 
  Verifying        : container-selinux-4:2.245.0-1.amzn2023.noarch                                                                                                                    1/11 
  Verifying        : containerd-2.2.5-1.amzn2023.0.2.x86_64                                                                                                                           2/11 
  Verifying        : docker-25.0.16-1.amzn2023.0.4.x86_64                                                                                                                             3/11 
  Verifying        : iptables-libs-1.8.8-3.amzn2023.0.2.x86_64                                                                                                                        4/11 
  Verifying        : iptables-nft-1.8.8-3.amzn2023.0.2.x86_64                                                                                                                         5/11 
  Verifying        : libcgroup-3.0-1.amzn2023.0.1.x86_64                                                                                                                              6/11 
  Verifying        : libnetfilter_conntrack-1.0.8-2.amzn2023.0.2.x86_64                                                                                                               7/11 
  Verifying        : libnfnetlink-1.0.1-19.amzn2023.0.2.x86_64                                                                                                                        8/11 
  Verifying        : libnftnl-1.2.2-2.amzn2023.0.2.x86_64                                                                                                                             9/11 
  Verifying        : pigz-2.5-1.amzn2023.0.4.x86_64                                                                                                                                  10/11 
  Verifying        : runc-1.3.5-1.amzn2023.0.2.x86_64                                                                                                                                11/11 

Installed:
  container-selinux-4:2.245.0-1.amzn2023.noarch   containerd-2.2.5-1.amzn2023.0.2.x86_64   docker-25.0.16-1.amzn2023.0.4.x86_64                 iptables-libs-1.8.8-3.amzn2023.0.2.x86_64  
  iptables-nft-1.8.8-3.amzn2023.0.2.x86_64        libcgroup-3.0-1.amzn2023.0.1.x86_64      libnetfilter_conntrack-1.0.8-2.amzn2023.0.2.x86_64   libnfnetlink-1.0.1-19.amzn2023.0.2.x86_64  
  libnftnl-1.2.2-2.amzn2023.0.2.x86_64            pigz-2.5-1.amzn2023.0.4.x86_64           runc-1.3.5-1.amzn2023.0.2.x86_64                    

Complete!
Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /usr/lib/systemd/system/docker.service.
[OK] Docker installed.
[OK] Docker service is running.

============================================================
Configuring Docker permissions...
============================================================
[OK] ec2-user added to docker group.

[INFO] System Architecture: x86_64

============================================================
Installing Docker Buildx...
============================================================
[INFO] Docker Buildx already installed.

============================================================
Installing Docker Compose...
============================================================
[INFO] Downloading latest Docker Compose...
[root@Shopci-Project VaibhavsShopciProject]# sh setup.sh
============================================================
        ShopCI - DevOps Environment Setup
============================================================
[OK] Running as root.
[INFO] Operating System: Amazon Linux 2023.12.20260831

============================================================
Updating system packages...
============================================================
Last metadata expiration check: 0:11:19 ago on Fri Sep  4 11:13:37 2026.
Dependencies resolved.
Nothing to do.
Complete!

============================================================
Installing required packages...
============================================================
Last metadata expiration check: 0:11:19 ago on Fri Sep  4 11:13:37 2026.
Package git-2.50.1-1.amzn2023.0.1.x86_64 is already installed.
Package jq-1.8.1-60.amzn2023.x86_64 is already installed.
Package wget-1.21.3-1.amzn2023.0.5.x86_64 is already installed.
Package unzip-6.0-68.amzn2023.0.2.x86_64 is already installed.
Package tar-2:1.34-1.amzn2023.0.4.x86_64 is already installed.
Package gzip-1.12-1.amzn2023.0.1.x86_64 is already installed.
Package ca-certificates-2025.2.76-1.0.amzn2023.0.3.noarch is already installed.
Package openssl-1:3.5.7-2.amzn2023.0.2.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
[OK] Required packages installed.

Checking curl...
[OK] curl is available.

============================================================
Installing Docker...
============================================================
[INFO] Docker is already installed.
[OK] Docker service is running.

============================================================
Configuring Docker permissions...
============================================================
[OK] ec2-user added to docker group.

[INFO] System Architecture: x86_64

============================================================
Installing Docker Buildx...
============================================================
[INFO] Docker Buildx already installed.

============================================================
Installing Docker Compose...
============================================================
[INFO] Downloading latest Docker Compose...
[root@Shopci-Project VaibhavsShopciProject]# docker --version
docker buildx version
docker compose version
aws --version
kubectl version --client
eksctl version
helm version
Docker version 25.0.14, build 0bab007
github.com/docker/buildx 0.12.1 30feaa1a915b869ebc2eea6328624b49facd4bfb
docker: 'compose' is not a docker command.
See 'docker --help'
aws-cli/2.33.15 Python/3.9.25 Linux/6.18.44-99.149.amzn2023.x86_64 source/x86_64.amzn.2023
-bash: kubectl: command not found
-bash: eksctl: command not found
-bash: helm: command not found
[root@Shopci-Project VaibhavsShopciProject]# 
