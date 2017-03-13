#!/bin/bash -x

<<header

title           :yum_repo_sync.sh
decription      :sync and update local repos
author          :Akeem Daly
contributors    :Akeem Daly
date created    :2017-03-12
last revision   :2017-03-12
version         :1.0

CHANGES:
  1.0 (2017-03-12):

    *start of change log

header

## GLOBAL SETTINGS ##

# set path and program name
PATH=/bin:/usr/bin:/sbin:/usr/sbin
export PATH
PROGNAME=$(basename $0)
PROGNAME_SHORT=$(echo $PROGNAME | cut -d"." -f1)

# root of repo directory
data_dir="/data"
repo_dir="$data_dir/repos"

# log location
repo_log="/var/log/$PROGNAME_SHORT.log"

# usage function
usage(){
echo -n "$PROGNAME: "; echo $1

cat <<USAGE_MSG

Usage: $PROGNAME {cent6|cent7|epel6|epel7|all_repos}

-h|  show usage


argument			repo
========			====

cent6				CentOS 6.x x86_64
cent7				CentOS 7.x x86_64
epel6				EPEL 6.x x86_64
epel7				EPEL 7.x x86_64
all_repos			All

USAGE_MSG

exit $2
}

## ERRORS FUNCTIONS ##

# make errors red on the console
echo_error_red(){
  echo -e "\e[1;31m$@\e[0m" 1>&2
}

# define error_out for exit status and error messages
error_out(){
  echo -n "$PROGNAME: "; echo_error_red $1
  exit $2
}

# define exit_out for exit status and non_error messages
exit_out(){
  echo -n "$PROGNAME: "; echo $1
  exit $2
}

## PRECHECKS ##

# check for superuser privileges
check_superuser(){
  current_uid=$(id | cut -d" " -f1)
  if [ ! "$current_uid" = "uid=0(root)" ]; then
    error_out "You Must Be Root to Run This Program!!" 2
  fi
}

# check if repo directory exists
check_repo_dir(){
  if [ ! -d "$repo_dir" ]; then
    error_out "Need $repo_dir for This Program to Run!!" 2
  fi
}

# check if data directory is mounted
check_data_mount(){
  data_mount=$(mount | grep $data_dir | wc -l)
  if [ "$data_mount" -eq "0" ]; then
    error_out "$data_dir is Not Mounted!!" 2
  fi
}

run_prechecks(){
	check_superuser
	check_repo_dir
	check_data_mount
}


repo_sync_job="$1"
set_repo(){

	case $repo_sync_job in
		cent6)
			version=6
			distro=centos
			;;
		cent7)
			version=7
			distro=centos
			;;
		epel6)
			version=6
			distro=all
			;;
		epel7)
			version=7
			distro=all
			;;
		all_repos)
			distro=all
			;;
		-h)
			usage "print usage" 2
			;;
		*)
			usage "invalid argument - please check usage" 1
			;;
	esac

}

## REPO SOURCES AND DESTINATIONS

set_repo_targets(){
# base os repo source
cent_os_src="rsync://mirror.cisp.com/CentOS/$version/os/x86_64/"

# base os local directory
cent_os_dst="$repo_dir/CentOS/$version/os/x86_64/"

# updates repo source
cent_updates_src="rsync://mirror.cisp.com/CentOS/$version/updates/x86_64/"

# updates local directory
cent_updates_dst="$repo_dir/CentOS/$version/updates/x86_64/"

# epel repo source
epel_src="rsync://mirrors.rit.edu/epel/$version/x86_64/"

# epel local directories
epel_dst="$repo_dir/EPEL/$version/x86_64/"
}


# define os repo sync
start_repo_sync(){
	start_msg(){
		printf "## start of $repo_sync_job sync ##\n\n\n"
	}

	end_msg(){
		printf "\n\n\n## end of $repo_sync_job sync ##"
	}

	if [ "$distro" == "centos" ]; then
		start_msg
		set_repo_targets
		rsync -avz --exclude='repo*' $cent_os_src $cent_os_dst && createrepo --update $cent_os_dst
		rsync -avz --exclude='repo*' $cent_updates_src $cent_updates_dst && createrepo --update $cent_updates_dst
		end_msg
	elif [ "$distro" == "epel" ]; then
		start_msg
		set_repo_targets
		rsync -avz --exclude='repo*' --exclude='debug' $epel_src $epel_dst && createrepo --update $epel_dst
		end_msg
	elif [ "$distro" == "all" ]; then
		start_msg
		unset version
		for version in {6..7}; do
			set_repo_targets
			rsync -avz --exclude='repo*' $cent_os_src $cent_os_dst && createrepo --update $cent_os_dst
			rsync -avz --exclude='repo*' $cent_updates_src $cent_updates_dst && createrepo --update $cent_updates_dst
			rsync -avz --exclude='repo*' --exclude='debug' $epel_src $epel_dst && createrepo --update $epel_dst
			unset version
		done
		end_msg
fi
}


# define main function
_main_(){
	set_repo
	run_prechecks
	start_repo_sync
}

# run main function
_main_