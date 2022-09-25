#!/bin/sh

#######################
# Url's:
# https://docs.ansible.com/ansible/latest/collections/ansible/builtin/index.html
# https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-ansible-on-ubuntu-20-04
# http://snakeproject.ru/rubric/article.php?art=ansible_19.08.2019
# https://www.cyberciti.biz/faq/how-to-set-up-ssh-keys-on-linux-unix/

# CSF
# https://vps.ua/wiki/configserver-security-and-firewall/


# Ansible group name
ansible_gp_name="servers"

# Folder where are stored VM (Vagrantfile)
vm_dir0="/mnt/vm/vagrant"
vm_dir="${vm_dir0}/ubuntu-test"

# ip VM
ip_vm1="192.168.121.201"

# Set rsa file for ssh key access to ansible servers
ssh_key_file="/home/user/.ssh/id_rsa.pub"

# Initial vagrant user
vm_user_init="vagrant"
vm_user_passwd="vagrant"

# Init files
i1_init="_1_init.sh"
i2_vagrant="_2_vagrant_init_vm.sh"

# Registry files
registry_dir="registry"
rg_fl1="hosts"

# Playbooks files
playbooks_dir="playbooks"
pb_scripts="_run_playbooks.sh"
pb_ssh_key_u="copy_ssh_key_user.yml"
pb_ssh_key_r="copy_ssh_key_root.yml"
pb_nginx="nginx.yml"
pb_sshd_mod="sshd_mod.yml"
pb_user_del="user_del.yml"
pb_system_upgr="system_upgrade.yml"

# Script files
scripts_dir="skripts"
#sshd_mod="sshd_modify.sh"

files2copy="${i1_init} ${i2_vagrant} Vagrantfile ${pb_scripts}"
dir2copy="${playbooks_dir} ${registry_dir} ${scripts_dir}"

# lib_virt pool parameters
_libvirt_pool1_dir="${vm_dir0}/img"
_libvirt_pool1_name="vagrant_images"

###########################
make_init_files()
{
###########################
# 1. Init: install ansible and vagrant
cat >"${i1_init}"<<- 'EOF'
#!/bin/sh

sudo apt install sshpass ansible
sudo apt install libvirt-dev libvirt-vagrant
vagrant plugin install vagrant-libvirt

# Check vagrant plugins
vagrant plugin install vagrant-libvirt

# Install vagrant box ubuntu 20.04
vagrant box add generic/ubuntu2004 --provider=libvirt
vagrant box list
EOF

###########################
# 2. Create new VM
cat >"${i2_vagrant}"<<- 'EOF'
#!/bin/sh

vm_dir="/media/k231/vm/vagrant/ubuntu-test2"

mkdir -p "${vm_dir}"
cd "${vm_dir}"
#vagrant init generic/ubuntu2004
#mv Vagrantfile Vagrantfile.original
EOF

###########################
# 3. Create new Vagrantfile
cat >"Vagrantfile"<<- EOF
Vagrant.configure("2") do |config|
 config.vm.define :test_ubuntu_2004 do |tm1|
  tm1.vm.box = "generic/ubuntu2004"
  tm1.vm.network :private_network, :ip=> "${ip_vm1}"
end
  config.vm.provider :libvirt do |v|
    v.memory = 1024
    v.cpus = 1
    v.storage_pool_name = "vagrant_images"
    v.storage :file, :size => '8G', :type => 'qcow2'
    end
end
EOF

# 4. Create playbooks
mkdir "${playbooks_dir}"

# Create yaml file copy ssh key for user
cat >"${playbooks_dir}/${pb_ssh_key_u}"<<- EOF
---
- hosts: ${ansible_gp_name}
  vars:
    ssh_key_file: ${ssh_key_file}
    ssh_user_dir: /home/${vm_user_init}/.ssh

  tasks:
  - name: create directory user .ssh
    file:
      path: '{{ ssh_user_dir }}'
      state: directory
      owner: vagrant
      group: vagrant
      mode: '0700'

  - name: Copy ssh pub key file to servers user vagrant
    copy:
      src: '{{ ssh_key_file }}'
      dest: '{{ ssh_user_dir }}/authorized_keys'
      owner: vagrant
      group: vagrant
      mode: '0600'
EOF
# Create yaml file copy ssh key for root
cat >"${playbooks_dir}/${pb_ssh_key_r}"<<- EOF
---
- hosts: ${ansible_gp_name}
  become: yes
  vars:
    ssh_key_file: ${ssh_key_file}
    ssh_root_dir: /root/.ssh

  tasks:
  - name: create directory /root/.ssh
    become_user: root
    file:
      path: '{{ ssh_root_dir }}'
      state: directory
      owner: root
      group: root
      mode: '0700'

  - name: Copy ssh pub key file to servers user root
    become_user: root
    copy:
      src: '{{ ssh_key_file }}'
      dest: '{{ ssh_root_dir }}/authorized_keys'
      owner: root
      group: root
      mode: '0600'
EOF

cat >"${playbooks_dir}/${pb_sshd_mod}"<<- EOF
---
- hosts: ${ansible_gp_name}
  become: yes
  vars:
       sshd_cfg: /etc/ssh/sshd_config
       ssh_port: 1234
  tasks:
    - name: sshd change port 22 to port 1234
      replace:
        path: "{{ sshd_cfg }}"
        regexp: '.*Port\s.*'
        replace: 'Port {{ ssh_port }}'

    - name: sshd change PasswordAuthentication
      replace:
        path: "{{ sshd_cfg }}"
        regexp: '.*PasswordAuthentication\s(yes|no)'
        replace: 'PasswordAuthentication no'
      notify:
         - restart sshd

  handlers:
    - name: restart sshd
      service: name=ssh state=restarted
EOF

cat >"${playbooks_dir}/${pb_nginx}"<<- EOF
---
- hosts: ${ansible_gp_name}
  tasks:

  - name: install nginx
    apt: name=nginx update_cache=yes

  - name: start nginx
    service: name=nginx state=started

  - name: stop nginx
    service: name=nginx state=stoped

  - name: restart nginx
    service: name=nginx state=restarted
EOF

cat >"${playbooks_dir}/${pb_user_del}"<<- EOF
---
- hosts: servers
  tasks:

  - name: Execute the command in remote shell; whoami
    ansible.builtin.shell: userdel -r ${vm_user_init}
EOF

cat >"${playbooks_dir}/${pb_system_upgr}"<<- EOF
---
- hosts: servers
  tasks:
  - name: Update the repository cache, upgrade system, autoclean, autoremove
    ansible.builtin.apt:
      update_cache: yes
      upgrade: yes
      autoclean: yes
      autoremove: yes
EOF

#########
# 5. Create registry files
mkdir "${registry_dir}"

cat >"${registry_dir}/${rg_fl1}"<<- EOF
[servers]
server1 ansible_host="${ip_vm1}" ansible_port=22 ansible_ssh_user=${vm_user_init} ansible_ssh_pass=${vm_user_passwd}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

# 6. Create init file for change sshd_config on a servers
#    Change: Port 22 -> Port 1234
#            PermitRootLogin (yes|no) -> PermitRootLogin without-password
#            PasswordAuthentication (yes|no) PasswordAuthentication no

mkdir "${scripts_dir}"
#cat >"${scripts_dir}/${sshd_mod}"<<- "EOF"
##!/bin/sh
#
#sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.origin
#src1=$(grep "Port\s[0-9]*" /etc/ssh/sshd_config)
#sudo sed -i "s/${src1}/Port 1234/g" /etc/ssh/sshd_config
#sudo sed -i "s/PermitRootLogin\s[(yes|no)]*//g" /etc/ssh/sshd_config
#sudo echo "PermitRootLogin without-password">>/etc/ssh/sshd_config
#sudo sed -i "s/.*PasswordAuthentication\s[(yes|no)]*/PasswordAuthentication no/g" /etc/ssh/sshd_config
#
#sudo systemctl restart ssh
#EOF

# 7. Create shell script for running ansible playbooks
cat >"${pb_scripts}"<<- EOF
#!/bin/sh

echo "Add ssh key to local repository"
ip1_vm="${ip_vm1}"
nm_ip1=\$(grep "\${ip1_vm}" /etc/hosts|cut -d ' ' -f2)
ssh-keyscan "\${ip1_vm}">> ~/.ssh/known_hosts
ssh-keyscan "\${nm_ip1}">> ~/.ssh/known_hosts

# Copy rsa_pub file to servers for root
# Add ssh_key for root
ansible-playbook -i ${registry_dir}/${rg_fl1} ${playbooks_dir}/${pb_ssh_key_r}

# Make changes in inventory file for use root user
sed -i 's/ansible_ssh_user=${vm_user_init}/ansible_ssh_user=root/' "${registry_dir}/${rg_fl1}"
sed -i 's/ansible_ssh_pass=${vm_user_passwd}//' "${registry_dir}/${rg_fl1}"

# Delete initial user ${vm_user_init}
#ansible-playbook -i ${registry_dir}/${rg_fl1} ${playbooks_dir}/${pb_user_del}

# Add ssh_key for user: ${vm_user_init} only
#ansible-playbook -i ${registry_dir}/${rg_fl1} ${playbooks_dir}/${pb_ssh_key_u}

# Now we make use ansible without remote passwords
# Copy script for modify /etc/ssh/sshd_config
ansible-playbook -i ${registry_dir}/${rg_fl1} ${playbooks_dir}/${pb_sshd_mod}

# Change port, replace user and password in inventory file
sed -i 's/ansible_port=22/ansible_port=1234/' "${registry_dir}/${rg_fl1}"

# Another time
# Upgrade system
#ansible-playbook -i ${registry_dir}/${rg_fl1} ${playbooks_dir}/${pb_system_upgr}
#ansible-playbook -i ${registry_dir}/${rg_fl1} ${playbooks_dir}/${pb_nginx}
EOF

# 8. run scripts for modify sshd_config on a servers

}
# End make_init_files

###########################
#00. Copy all files in VM folder
copy_files2vm_dir()
{
 # Copy init files
 for i in ${files2copy}; do cp "${i}" "${vm_dir}";done

 # Copy dirs
 for i in ${dir2copy}; do cp -rp "${i}" "${vm_dir}/${i}"; done
}

# 001. Remove ssh servers keys from localhost
_ssh_keys_remove()
{
    nm1=$(grep ${ip_vm1} /etc/hosts|cut -d ' ' -f2)
    ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "${ip_vm1}"
    ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "${nm1}"
}
_ssh_keys_add()
{
    nm1=$(grep ${ip_vm1} /etc/hosts|cut -d ' ' -f2)
    ssh-keyscan "${ip_vm1}">> ~/.ssh/known_hosts
    ssh-keyscan "${nm1}">> ~/.ssh/known_hosts
}
_libvirt_pool_init()
{
# Check if pool exist
#echo "_libvirt_pool1_dir=[${_libvirt_pool1_dir}]"
#echo "_libvirt_pool1_name=[${_libvirt_pool1_name}]"

g_p1=$(virsh pool-list --all|grep "${_libvirt_pool1_name}"|sed 's/^\s//g')
#echo "${g_p1}"
echo " -:Check pool: [${_libvirt_pool1_name}]"
if [ -n "${g_p1}" ]; then
  p_state=$(echo "${g_p1}"|awk '{print $2}')
  p_autostart=$(echo "${g_p1}"|awk '{print $3}')
#  echo "p_state=[${p_state}]"
#  echo "p_autostart=[${p_autostart}]"
# Check and activate pool
  if [ "${p_state}" = "inactive" ]; then echo "   -Activate pool"; virsh pool-start "${_libvirt_pool1_name}";
    else echo "   -Pool activated"
  fi
  if [ "${p_autostart}" = "no" ]; then echo "   -Autostart pool";virsh pool-autostart "${_libvirt_pool1_name}";
    else echo "   -Pool autostart"
  fi
  unset p_state
  unset p_autostart
else
# Create full pool: folder, add pool, activate and autostart
  echo "   Create full pool: folder, add pool, activate and autostart"
  mkdir -p "${_libvirt_pool1_dir}" || echo "Error create folder: [${_libvirt_pool1_dir}]"
  echo "    -:define pool"
  virsh pool-define-as "${_libvirt_pool1_name}" dir - - - - "${_libvirt_pool1_dir}"
  ret_c=$(virsh pool-list --all --name|grep "${_libvirt_pool1_name}")
  if [ -n "${ret_c}" ]; then echo "Poll: [${_libvirt_pool1_name}] create at folder [${_libvirt_pool1_dir}]"
    else echo "Error create pool: [${_libvirt_pool1_name}] at [${_libvirt_pool1_dir}]"
  fi

  unset ret_c

  echo "    -:build pool"
  virsh pool-build "${_libvirt_pool1_name}"
  echo "    -:activate pool"
  virsh pool-start "${_libvirt_pool1_name}"
  echo "    -:autostart pool"
  virsh pool-autostart "${_libvirt_pool1_name}"

fi
 unset g_p1
}
_libvirt_pool_delete()
{
if [ -z "${1}" ]; then return 1; else pool1_name="${1}"; fi
    g_ret=$(virsh pool-list --all --name|grep "${pool1_name}")
  if [ -n "${g_ret}" ]; then
    echo "Delete poll: [${pool1_name}]"
    virsh pool-destroy "${pool1_name}"
    virsh pool-delete "${pool1_name}"
    virsh pool-undefine "${pool1_name}"
  else echo "Error: not found pool: [${pool1_name}]"
  fi
}

##########################
# Main sections

# Remove old ssh keys for old VM
_ssh_keys_remove

# Create initial files
make_init_files

# Vagrant: check and init pool storage
_libvirt_pool_init

#exit 0
###########################

if [ -d "${vm_dir}" ]; then
    if [ -w "${vm_dir}" ]; then copy_files2vm_dir; else echo "Error write to folder"; fi
else
    mkdir "${vm_dir}" && copy_files2vm_dir
fi
