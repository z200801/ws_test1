#!/bin/sh

#
# Ansible group name
ansible_gp_name="servers"

# Folder where are stored VM (Vagrantfile)
vm_dir="/mnt/vm/vagrant/ubuntu-test"

# ip VM
ip_vm1="192.168.121.201"

# Set rsa file for ssh key access to ansible servers
ssh_key_file="~/.ssh/id_rsa_ansible.pub"

# Initial vagrant user
vm_user_init="vagrant"
vm_user_passwd="vagrant"

ssh_dest_key_file="/home/${vm_user_init}/.ssh/id_rsa_ansible.pub"

# Init files
i1_init="_1_init.sh"
i2_vagrant="_2_vagrant_init_vm.sh"

# Registry files
registry_dir="registry"
rg_fl1="hosts"

# Playbooks files
playbooks_dir="playbooks"
pb_scripts="_run_playbooks.sh"
pb_ssh_keys="copy_ssh_keys.yml"
pb_nginx="nginx.yml"
pb_sshd_mod="sshd_mod.yml"

# Script files
scripts_dir="skripts"
sshd_mod="sshd_modify.sh"

files2copy="${i1_init} _2_vagrant_init_vm.sh Vagrantfile ${pb_scripts}"
dir2copy="${playbooks_dir} ${registry_dir} ${scripts_dir}"

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
    v.storage :file, :size => '8G', :type => 'qcow2'
    end
end
EOF

# 4. Create playbooks
mkdir "${playbooks_dir}"

cat >"${playbooks_dir}/${pb_ssh_keys}"<<- EOF
---
- hosts: ${ansible_gp_name}
  tasks:
  - name: Copy ssh pub key file to servers
    copy:
      src: /home/user/.ssh/id_rsa.pub
      dest: /home/${vm_user_init}/.ssh/id_rsa_ansible.pub
      owner: ${vm_user_init}
      group: ${vm_user_init}
      mode: '0644'
EOF

cat >"${playbooks_dir}/${pb_sshd_mod}"<<- EOF
---
- hosts: ${ansible_gp_name}
  tasks:
  - name: Copy sshd modify script to servers
    copy:
      src: ../${scripts_dir}/${sshd_mod}
      dest: /home/${vm_user_init}/${sshd_mod}
      owner: ${vm_user_init}
      group: ${vm_user_init}
      mode: '0744'
EOF

cat >"${playbooks_dir}/${pb_nginx}"<<- EOF
---
- hosts: ${ansible_gp_name}
  become: yes
 
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
cat >"${scripts_dir}/${sshd_mod}"<<- "EOF"
#!/bin/sh

sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.origin
src1=$(grep "Port\s[0-9]*" /etc/ssh/sshd_config)
sudo sed -i "s/${src1}/Port 1234/g" /etc/ssh/sshd_config
sudo sed -i "s/PermitRootLogin\s[(yes|no)]*//g" /etc/ssh/sshd_config
sudo echo "PermitRootLogin without-password">>/etc/ssh/sshd_config
sudo sed -i "s/.*PasswordAuthentication\s[(yes|no)]*/PasswordAuthentication no/g" /etc/ssh/sshd_config

sudo systemctl restart ssh
EOF

# 7. Create shell script for running ansible playbooks
cat >"${pb_scripts}"<<- EOF
#!/bin/sh

# Copy rsa_pub file to servers
ansible-playbook ${playbooks_dir}/${pb_ssh_keys} -i ${registry_dir}/${rg_fl1}

# Add key file to authorized_keys
ansible ${ansible_gp_name} \\
    -i ${registry_dir}/${rg_fl1} \\
    -b --become-user=${vm_user_init} \\
    -m shell \\
    -a "cat ${ssh_key_file}>>~/.ssh/authorized_keys"

# Now we make use ansible without remote passwords
# Copy script for modify /etc/ssh/sshd_config
ansible-playbook ${playbooks_dir}/${pb_sshd_mod} -i ${registry_dir}/${rg_fl1}
# Run script
ansible ${ansible_gp_name} \\
    -b \
    -i ${registry_dir}/${rg_fl1} \\
    -m shell \\
    -a "/home/vagrant/sshd_modify.sh"

sed -i 's/ansible_port=22/ansible_port=1234/' "${registry_dir}/${rg_fl1}"

# Another time
#ansible-playbook ${playbooks_dir}/${pb_nginx} -i ${registry_dir}/${rg_fl1}
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
    ssh-keyscan "${ip_vm1}">> ~/.ssh/known_hosts
    ssh-keyscan "${nm1}">> ~/.ssh/known_hosts
}

##########################
# Main sections
_ssh_keys_remove
make_init_files
#exit 0
###########################

if [ -d "${vm_dir}" ]; then
    if [ -w "${vm_dir}" ]; then copy_files2vm_dir; else echo "Error write to folder"; fi
else
    mkdir "${vm_dir}" && copy_files2vm_dir
fi
