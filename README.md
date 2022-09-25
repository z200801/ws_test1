# ws_test1

Useful url's \
https://docs.ansible.com/ansible/latest/collections/ansible/builtin/index.html
https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-ansible-on-ubuntu-20-04 \
http://snakeproject.ru/rubric/article.php?art=ansible_19.08.2019 \
https://www.cyberciti.biz/faq/how-to-set-up-ssh-keys-on-linux-unix 

Script [ws_test1.sh] create files and folders in local folder and copy this structure to [$vm_dir]
 folders: 
  * playbooks: playbooks yml files for ansible-playbooks
  * registry:  files with hostnames and users
  * scripts:   bourne shell scripts for after installing system initial scripts
 
 scripts:
  * _1_init.sh: install - sshpass, ansible, libvirt-dev, libvirt-vagrant
                    download - vagrant box with ubuntu 20.04 for libvirt
  * _2_vagrant_init_vm.sh: initial script for making Vagrantfile [not need]
  * _run_playbooks.sh: script for run playbooks for [servers]. Such as: copy ssh keys, modify sshd_config file [port 1234, access with ssh keys].
          
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
  - Start vagrant box -> cd to $VM && vagrant up. Standart login:pass [vagrant:vagrant]
  - Goto VM folder
  - run script _run_playbooks.sh
    - add ssh public key to localmachine
    - copy ssh key for root to [servers] and make file /root/.ssh/authorized_keys
    - change inventory file [registry/hosts] for user: root, remove ssh password for user: [vagrant]
    - delete from [servers] initial user: [vagrant]
    - modify /etc/ssh/sshd_config for: port 1234 and allow access only ssh keys
    - change inventory file [registry/hosts] for port 1234
    - install nginx from repository
  - Now we can using ssh key access to servers only for root accounts
  - Runnig sshd_modify.sh script for modify /etc/ssh/sshd_config file. Change port to 1234, access only keys and restart sshd service
  - Now access to servers only ssh keys
  - remake: 1st ssh conection with login:password
  - remake: 1st ssh connection for user [vagrant] witth password stored in inventory file registry/hosts
  - add ssh key to root user [/root/.ssh/authorized_keys]
  - remove from servers user: [vagrant]
 
#### To do:
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
----
#### Files:
 - _run_playbooks.sh: script for running ansible playbooks
##### Inventory hosts [registry/]
 - hosts: contains hosts with ssh: port, user
##### Playbooks [playbooks/]
 - copy_ssh_key_user.yml: create dir ~/.ssh and copy ssh key for user [vagrant]. This file is not running, because we are later delete this user
 - copy_ssh_key_root.yml: create dir ~/.ssh and copy ssh key for root
 - sshd_mod.yml: modify /etc/ssh/sshd_config : port 1234, PasswordAuthentication no
 - user_del.yml: delete user [vagrant]
 - system_upgrade.yml: upgrade system
 - apt_autoremove.yml: apt autoremove packages
##### Scripts [scripts/]
 - contains scripts files for running in hosts
 
 
 

