# ws_test1

Useful url's \
https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-ansible-on-ubuntu-20-04 \
http://snakeproject.ru/rubric/article.php?art=ansible_19.08.2019 \
https://www.cyberciti.biz/faq/how-to-set-up-ssh-keys-on-linux-unix 

Script create some
 folders: 
  * playbooks: playbooks yml files for ansible-playbooks
  * registry:  files with hostnames and users
  * scripts:   bourne shell scripts for after installing system initial scripts
 
 scripts:
  * _1_init.sh: install - sshpass, ansible, libvirt-dev, libvirt-vagrant
                    download - vagrant box with ubuntu 20.04 for libvirt
  * _2_vagrant_init_vm.sh: initial script for making Vagrantfile [not need]
  * _run_playbooks.sh: script running initial VM. Such as: copy and add ssh keys, modify sshd_config file [port 1234, access with ssh keys], install playbooks files
          
### Using:
  * Ubuntu: ansible server
  * Ubuntu 20.04: vagrant server
  * kvm (libvirt): hypervisor
### Need:
  Installing vagrant, ansible, kvm
  
### Work steps:
 #### Maked:
  - Install: vagrant for libvirt, ansible
  - Download voagrant box ubuntu 20.04
  - Create Vagrantfile with some parameters, such as cpus, memory and set ip
  - Start vagrant box -> cd to $VM && vagrant up
  - copy ssh key to VM (need entering password for vagrant user: vagrant)
  - add ssh key to ~/.ssh/authorized_keys (need entering password for vagrant user: vagrant)
  - Now we can using ssh key access to servers
  - Runnig sshd_modify.sh script for modify /etc/ssh/sshd_config file. Change port to 1234, access only keys and restart sshd service
  - Now access to servers only ssh keys
  - remake: 1st ssh conection with login:password
#### To do:
  - add ssh key to root user [/root/.ssh/authorized_keys]
  - remove from servers user: [vagrant]
  - install & configure [csf] with according to requirements
  - install last versions: [nginx], [php-fpm 8.1], [MySql]
  - install last versions & configure [wp] with according to requirements
  - cleaning logs
  - secured: ubuntu, nginx, mysql, wp
  - create cron script for bu: config (system , nginx, mysql); wp; db (mysql)

#### Remake:
  - chage function in main script that:
      - copy all files in folder [scripts] to servers
      - runs scripts from folder [scripts] 
      - delete scripts folder [scripts] 
 
