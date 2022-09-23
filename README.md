# ws_test1

Useful url's
https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-ansible-on-ubuntu-20-04
http://snakeproject.ru/rubric/article.php?art=ansible_19.08.2019
https://www.cyberciti.biz/faq/how-to-set-up-ssh-keys-on-linux-unix/

Script create some 
 folders: 
  * playbooks: playbooks yml files for ansible-playbooks
  * registry: files with hostnames and users
  * scripts: bourne shell scripts for after installing system initial scripts
 scripts:
  * _1_init.sh: install - sshpass, ansible, libvirt-dev, libvirt-vagrant
                download - vagrant box with ubuntu 20.04 for libvirt
  * _2_vagrant_init_vm.sh: initial script for making Vagrantfile [not need]
  * _run_playbooks.sh: script running initial VM. Such as: copy and add ssh keys, modify sshd_config file [port 1234, access with ssh keys], install playbooks files
          
Using: 
  * Ubuntu: ansible server
  * Ubuntu 20.04: vagrant server
  * kvm (libvirt): hypervisor
Need:
  Installing vagrant, ansible
  
Work step

  - 
