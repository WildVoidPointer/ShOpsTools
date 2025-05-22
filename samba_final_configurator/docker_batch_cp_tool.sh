#!/bin/bash


# $1 is docker container id
sudo docker cp ./samba_configurators/samba_share_space_initialization.sh ${1}:/samba_install/
sudo docker cp ./samba_test_tools/samba_company_test_tool.sh ${1}:/samba_install/
sudo docker cp ./samba_configurators/samba_server_installer.sh ${1}:/samba_install/
sudo docker cp ./samba_configurators/samba_server_docker_setup.sh ${1}:/samba_install/
sudo docker cp ./samba_configurations/samba_company_members.csv ${1}:/samba_install/
sudo docker cp ./samba_configurations/samba_company_usergroups.txt ${1}:/samba_install/
sudo docker cp ./samba_configurations/samba_share_depts_space.csv ${1}:/samba_install/
sudo docker cp ./samba_configurations/samba_share_users_space.csv ${1}:/samba_install/
sudo docker cp ./samba_configurations/smb.conf ${1}:/samba_install/
