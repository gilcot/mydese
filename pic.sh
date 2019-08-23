#!/bin/sh
# ex: ai:sw=4:ts=4
# vim: ai:ft=sh:sw=4:ts=4:ff=unix:sts=4:et:fenc=utf8
# -*- sh; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4;
# atom: set usesofttabs tabLength=4 encoding=utf-8 lineEnding=lf grammar=shel;
# mode: shell; tabsoft; tab:4; encoding: utf-8; coding: utf-8;
##########################################################################
# Put things I used to add to my De(bi|vu)an box
# everytime I create a new box, I use to perfom those setings


## global variables
_c=0    # changed by _select()
_p=''   # changed by _debsel()

## constants: fixed strings
# start of many strings used with _at_p()
_def="Favorite"
# end of many strings used with _at_p()
_man=" Manager"
# end of some strings used with _at_p()
_bro=" Browser"
# for TL;DR community driven commands helps
_nlr=" client for https://tldr.ostera.io"

## constants: directories paths
# Installation Base Directory, a.k.a PREFIX
_ibd=/usr/local
# install Binaries into $PREFIX/bin
_ulb="$_ibd/bin"
# download Sources into $PREFIX/src
_uls="$_ibd/src"
# put shared Data dir into $PREFIX/share
_uld="$_ibd/share"
# system width bashrc
_brc=/etc/bash.bashrc
# bash completions directory >D5
# created by bash-completion package
_bcd=/usr/share/bash-completion/completions

## constants: commands aliases (3 letters)
# Where Is that Command: POSIX alternative to "which" ;
# replaces "type -f" (or "-a") or even "whereis -b"
wic="command -v"
# Get this URL Link
# ...okay, not shorter than "wget" or "curl" but with rigth options
gul="wget -q -c -nD --random-wait --waitretry=3 -T 9 -t 3 --no-check-certificate "
# Make Directory full Path
mdp="mkdir -pv"
# alias for Apt-Get Install to avoid retyping everytime
# -qq or -q=2 implies -y that is tempered with --trivial-only
agi="apt-get -qq --trivial-only install"
# alias for an Easy Python package Install to avoid retyping everytime
epi="pip -qq --retries 2 --timeout 7 install"
# alias for an Easy Ruby package Install to avoid retyping everytime
eri="$wic gem >/dev/null || $agi ruby ; gem install"

## constants: variant strings
# Debian installed Packages List ; used by _debsel()
_dpl="$( dpkg --get-selections | awk '{print $1}' )"
# Script Directory Name ; used by _installf() and elsewhere
_sdn="$( readlink -fns "$( dirname $0 )" )"
# domain name ;
_dom="$( hostname -d )"
_dom="${dom:-localnet}"
# host name ;
_hos="$( hostname -s )"
# for _at_? functions, set terminal's width
# $_w: is 0 if term. can't handle colors,
#      otherwise is known available columns
if $wic tput >/dev/null
then
    if $wic stty >/dev/null
    then
        _w="$( stty size | cut -d ' ' -f 2 )"
    else
        # note: $COLUMNS may not be set
        # (e.g with sudo or non-login ssh)
        # but does terms less than 40 chars.width exist
        _w=${COLUMNS:-40}
    fi
else
    _w=0
fi

## title of current part (main step)
# $1: message to show
_at_p() {
    if test $_w -ne 0
    then
        printf "\033[44;36m => %*s\033[0m\n" \
            "-$(( _w - 4 ))" "$1"
    else
        echo " => $1"
    fi
}

## title of current task (a sub step)
# $1: message to show
_at_t() {
    if test $_w -ne 0
    then
        printf "\033[44;37m --> %*s\033[0m\n" \
            "-$(( _w - 5 ))" "$1"
    else
        echo " --> $1"
    fi
}

## ask for choice within passed items
# $@: items to choose from, in order
# $_c: result (i.e. choice number...)
_select() {
    _i=0
    for _item in 'none' "$@"
    do
        if test $_w -ne 0
        then
           printf "\033[44;37m\t%d\t%*s\033[0m\n" \
               $_i "-$(( _w - 16 ))" "$_item"
        else
            printf "\t%d\t%s\n" $_i "$_item"
        fi
        _i=$(( _i+1 ))
    done
    unset _i
    if test $_w -ne 0
    then
        printf "\033[44;37m choice:\t\033[0m"
    else
        printf " choice:\t"
    fi
    read -r _c
    _c=$(( _c ))
}

## check if one of the commands is in path
# (return with success at first found)
# $@: commands to check for, in order
_cmd_ok() {
    for _item in $@
    do
        $wic $_item && return
    done
    #return 1
}

## install with list from file
# $1: file path to loop on
# $2: install command
_instalf() {
    # note on packages naming
    # http://manpages.debian.org/1/dpkg-name
    # package_version_architecture.package-type
    # http://www.debian.org/doc/manuals/debian-reference/ch02.en.html#_debian_package_file_names
    # <package-name>_<epoch>.<upstream-version>-<debian_version>-<architecture>.deb
    # http://www.debian.org/doc/manuals/debian-faq/ch-pkg_basics#s-pkgname
    # <foo>_<VersionNumber>-<DebianRervisionNumber>_<DebianArchitecture>.deb
    # Well those informations, while a bit relevant, may not be up to date
    # https://unix.stackexchange.com/a/407195
    # and exceptions may occur outside
    # https://unix.stackexchange.com/a/469546
    for _p in $( awk '/^ *[a-zA-Z0-9_+=-]+/{print $1}' "$1" )
    do
        _at_t "$_p"
        ${2:-$agi} $_p
    done
}

## retrieve and build Go...
# $@: list of locations to get
_make_go() {
    # beware, distro Go compiler may be outdate
    # https://linuxize.com/post/how-to-install-go-on-debian-9/
    # https://tecadmin.net/install-go-on-debian/
    # https://www.digitalocean.com/community/tutorial/how-to-install-go-on-debian-8
    # https://www.digitalocean.com/community/tutorial/how-to-install-go-on-debian-9
    if ! $wic go >/dev/null
    then
        $agi golang-go
        # of course, change $GOROOT to installation directory
        # (e.g. $PREFIX/go) if it's installed from sources
        # https://linoxide.com/linux-how-to/install-go-ubuntu-linux-centos/
        cat >/etc/profile.d/goenv.sh << EOF
export GOROOT=/usr/lib/go
export GOPATH="$HOME/go"
export PATH="$PATH:$GOROOT/bin:$GOPATH/bin"
EOF
    fi
    cd "$_uls"
    export GOPATH="$_ibd"
    for _item in $@
    do
        go get $_item
    done
    for _item in $@
    do
        go install $_item
    done
}

## retrieve and build Rust
# $@: list of packages to install
_inst_ru() {
    # but packages "cargo" and " rustc" aren't available for older distros
    # like D7, where we should go rustup prior
    # https://www.rust-lang.org/tools/install
    # https://github.com/rustup.rs/blob/master/README.rd
    $wic cargo >/dev/null ||
        $agi cargo ||
        break
    for _item in $@
    do
        cargo install $_item
    done
}

## clone a Git repository
# $1: user_or_team_or_project/repository_id
# $2: base site if not github.com
_g_clone() {
    $wic git >/dev/null || $agi git
    cd "$_uls"
    git clone -q https://${2:-github.com}/$1.git &&
        cd $( basename $1 .git )
}

## choose a package to install in a group
# see if a package of a list is installed,
# and if none of them, make a selection list
# $@: items to choose from, in order
# $_p: result (i.e. package selected)
_debsel() {
    _p=''
    for _item in $@
    do
        echo "$_dpl" | grep -s -w $_item && return
    done
    _old="$IFS" IFS="
" _sel=$( for _item in $@
    do
        apt-cache search -n ^$_item$
    done)
    _select $_sel
    IFS=$_old
    if test $_c -ne 0
    then
        _p=$( echo $_sel | awk -v N=$_c 'NR=$N {print $1}' )
    fi
    unset _sel
}

## install a package from a group
# $@: items to choose from, in order
_dipick() {
    _debsel $@
    test -n "$_p" &&
        $agi "$_p"
}


##########################################################################
## main: let's process now


_at_p "Initial Checks"

# All the following actions should be performed as root
_at_t "User is Root"
id
test $( id -u ) -eq 0 || exit 1

_at_t "Commands in Path"
# Following commands are used before packages installation
for _item in readlink dirname hostname apt-get dpkg awk
do
    $wic $_item ||
        {
            echo "Cannot locate '$_item' within $PATH" >&2
            exit 1
        }
done

_at_t "Prepare Directoryes"
$mdp $_bcd "$_uls"
# Downloads should occur in this directory, so let's swith here
cd "$_uls"


_at_p "Update System"

# Put client or other specific additions
# note that this can be done later with Ansible
_at_t "Add Extra Sources Lists"
find "$_sdn" -maxdepth 0 -name '*.list' \
    -exec cp -nuv {} /etc/apt/sources.list.d/ \;

# Alternatively, you may use the following to add setting
# (e.g. files in /etc/profile.d/ /etc/apt/apt.conf.d/ and so)
# if this is not relevant for the following (for example,
# exporting http_proxy and https_proxy in the environment),
# it's better to do it later via nice Ansible playbook
if test -e "$_dom.setup"
then
    _at_t "Load Site Extra Settings"
    . "$_dom.setup"
fi

# Usefull if source list is changed before
# Stop on network issue or if lists need to be fix...
_at_t "Refresh Repositories Data"
apt-get -qq update || exit 2

# Upgrade to correct latest
# Also stop if the process went wrong...
_at_t "Refrest Installed Files"
apt-get -qq upgrade || exit 2

_at_p "Install Additionnal System Packages"
# ensure the following packages are there
if test -e "$_sdn/all.deb.lst"
then
    # As I'm sharing this on a public Git, let's give ability to have
    # own default packages (e.g. one may prefere Nano instead of ViM)
    # So people won't need to patch my maintenance releases for that!
    _instalf "$_sdn/all.deb.lst"
else
    # I should keep that list as small as possible, as I have Ansible
    # playbooks to add and configure some other stuffs when required.
    # question: should I add in the list: rlfe 
    for _item in ssh sshpass gnupg-agent pwgen cowsay mtr gpm \
        ca-certificates cifs-utils smbclient lsb-release rlpr sl
    do
        _at_t "$_item"
        $agi $_item
    done
fi

# Install virtual machine additionals
if $wic virt-what >/dev/null
then
    # https://people.redhat.com/~rjones/virt-what/virt-what.txt
    _vmt="$( virt-what | head -n 1 )"
elif $wic dmidecode >/dev/null
then
    _vmt="$( dmidecode -s system-product-name )"
else
    _vmt=''
fi
case $_vmt in
    'VirtualBox'|'virtualbox') # Sun/Oracle VirtualBox
        # this is required to mount shared folders...
        _p='virtualbox-guest-dkms'
        ;;
    'VMware Virtual Platform'|'vmware') # VMware Workstation
        # tools and drivers for better experience and administration
        if test $( grep -o '[0-9]\.[0-9][0-9]*' /etc/debian_version |
            cut -d. -f1 ) -gt 5
        then
            # OpenSource binaries are enough
            _p='open-vm-tools'
        else
            # OpenSource binaries are not available prior Squeeze
            # one have to go the hard way, and redo it on each kernel upgrade
            # https://www.debiantutorials.com/how-to-install-vmware-tools/
            # https://www.electrictoolbox.com/install-vmware-tools-debian-5/
            _p="autoconf gcc-4.1* make psmisc linux-header-$( uname -r )"
            #_p="autoconf gcc-4.3* make psmisc linux-header-$( uname -r )"
        fi
        ;;
    'KVM') # QEmu with KVM
        _p=''
        ;;
    'Bochs') # QEmu emulated
        _p=''
        ;;
    'Virtual Machine') # Microsoft VirtualPC
        _p=''
        ;;
    'HVM domU'|'xen-dom[0U]'|'xen-hvm'|'xen') # Xen
        _p=''
        ;;
    *) # baremetal
        _p=''
        ;;
esac
unset _vmt
if test -n "$_p"
then
    _at_t "$_p"
    $agi $_p
fi

# Install specific packages to that host
# note that this can be done later with Ansible
test -e "$_sdn/$_hos.deb.lst" &&
    _instalf "$_sdn/$_hos.deb.lst"

# Now some clean up bfore going on
_at_t "Cleaning Up"
apt-get autoremove --purge &&
    apt-get autoclean


_at_p "Misc. System Configuration"
# some setings I used to

_at_t "Login Banner"
_debsel 'linuxlogo' 'neofetch' 'screenfetch' 'sysvbanner'
if test -n "$_p"
then
    $agi "$_p"
    case $_p in
        linuxlogo)
            _p="$_p -b"
            ;;
        neofetch)
            # this one will only show in some distro versions
            # https://github.com/dylanaraps/neofetch/wiki/installation#debian
            # https://github.com/dylanaraps/neofetch/wiki/installation#ubuntu
            # https://github.com/dylanaraps/neofetch/wiki/installation#bunsenlab
            # launched with no option
            # https://github.com/dylanaraps/neofetch/wiki/Getting-Started
            # https://github.com/dylanaraps/neofetch/wiki/Customizing-Info
            _p="$_p --config none"
            ;;
        screenfetch)
            # Note that il will install: scrot libimlib2 libid3tag0 giblib1
            # By default, it shows (per line):
            # user@host OS Kernel Uptime Packages Shell CPU RAM
            # Documentation isn't up to date and one should scan source
            # https://github.com/KittyKatt/screenFetch/issues/452#issuecomment-287433134
            # However "-d" option seems buggy when tested with 3.6.2;
            # hope it's corrected with current 3.8.0
            _p="$_p -E"
            if test $( $_p -V | head -n 1 | 
                grep -os '[1-9]\.[0-9]\.[0-9]' | cut -c 1,3 ) -gt 36
            then
                _p="$_p -d '+distro;+kernel;-uptime;-pkgs;-shell;+cpu;+mem;+host' "
            fi
            ;;
        sysvbanner)
            _p="{ banner $_hos; uname -sr 2>/dev/null; uname -vm 2>/dev/null; }"
            ;;
    esac
    eval "$_p" >/etc/issue
fi

_at_t "root bashrc"
if test -e $_sdn/root_bashrc
then
    # As I'm sharing this on a public Git, let's give ability to have
    # something different from mine
    # So people won't need to patch my maintenance releases for that!
    cat $_sdn/root_bashrc >/root/.bashrc
else
    cat >/root/.bashrc << 'EOF'
# ~/.bashrc: executed by bash(1) for non-login shells.

# Note: PS1 and umask are already set in /etc/profile. You should not
# need this unless you want different defaults for root.
# PS1='${debian_chroot:+($debian_chroot)}\h:\w\$ '
# umask 022

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# history setting
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
PROMPT_COMMAND='history -a'
HISTSIZE=99
HISTFILESIZE=999

if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # show some informations
    printf "\033[01;33m%s\033[0m\n" "$(uptime)"
    printf "\033[01;34m%s\033[0m\n" "$(free -th)"
    printf "\033[01;31m%s\033[0m\n" "$(who -dH)"
    # red colored prompt
    PS1='\[\033[01;31m\]\h:\w \$\[\033[0m\] '
else
    # some informations
    uptime
    free -th
    # prompt
    PS1='\h:\w \$ '
fi

# no colorised 'ls' for root
export LS_OPTIONS='--color=never'
# some usefull 'ls' alias
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -lF'
alias la='ls $LS_OPTIONS -lAF'
#
# Some more alias to avoid making mistakes:
alias rm='rm -vi'
alias cp='cp -vi'
alias mv='mv -vi'
alias ln='ln -v'
EOF
fi
    cat >/root/.profile << 'EOF'
# ~/.profile: executed by Bourne-compatible login shells.

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
   . ~/.bashrc
  fi
fi

mesg n
EOF


_at_p "Setup Python Packages$_man"
# Let's go beyong 'easy_install' but get the latest from source
# (an "$agi python-pip" will leave us with an outdate version)
if ! $wic pip #>/dev/null
then
    # instructions from https://github.com/pypa/get-pip
    _at_t "Retrieve Installer"
    test -e get-pip.py ||
        $gul https://bootstrap.pypa.io/get-pip.py || exit 2
    _at_t "Install pip:lastest"
    python get-pip.py || exit 2
fi

if test -e "$_sdn/all.pip.lst"
then
    # As I'm sharing this on a public Git, let's give ability to have
    # own default packages instead of always patching this script
    _at_p "Install Common Python Packages"
    _instalf "$_sdn/all.pip.lst" "$epi"
else

    _at_p "Install Ansible:base"
    # I always use the latest stable that may not be available for old distro
    # Also, one may add the file /etc/apt/sources.list.d/ansible.list
    # with this content for example:
    # deb http://ppa.launchpag.net/ansible/ubuntu trusty main
    # Those steps are performed under Ubuntu with the command:
    # (you'll need to do before: $agi software-properties-common )
    # apt-add-repository ppa:ansible/ansible
    # cryptography-packaging
    # pyOpenSSL
    if ! $wic ansible #>/dev/null
    then
        for _item in \
            'PyYAML' \
            'MarkupSafe jinja2' \
            'pycparser cffi' \
            'six ipaddress enum34 cffi asn1crypto cryptography' \
            'ansible'
        do
            _at_t "$_item"
            $epi $_item
        done
    fi

    _at_p "hosts infrastructure"
    # https://docs.ansible.com/latest/plugins/inventory.html
    _select \
        "Amazon Web Service EC2/RDS" \
        "Azure Resource$_man" \
        "Docker swarm" \
        "Google Cloud Compute Engine" \
        "GitLab runners" \
        "Hetzner Cloud" \
        "Kubernetes / KubeVirt / OpenShift" \
        "OpenStack" \
        "Linode" \
        "nmap" \
        "VMware ESX/ESXi/vCenter" \
        "Windows hosts" \
        "Cloudscale / Foreman / NetBox / Online / Scaleway / Ansible Tower / Oracle VirtualBox / vultr" \
        #"Proxmox VE" 
    case $_c in
        1|amazon)
            # https://docs.ansible.com/latest/plugins/inventory/aws_ec2.html
            # https://docs.ansible.com/latest/plugins/inventory/aws_rds.html
            _p='boto3 botocore'
            ;;
        2|azure)
            # https://docs.ansible.com/latest/plugins/inventory/azure_rm.htl
            _p='azure>=2.0.0'
            ;;
        3|docker)
            # https://docs.ansible.com/latest/plugins/inventory/docker_swarm.html
            _p='docker'
            ;;
        5|gitlab)
            # https://docs.ansible.com/latest/plugins/inventory/gitlab_runners.html
            _p='python-gitlab>=1.8.0'
            ;;
        4|google)
            # https://docs.ansible.com/latest/plugins/inventory/gcp_compute.html
            _p='google-auth>=1.3.0'
            ;;
        6|hcloud)
            # https://docs.ansible.com/latest/plugins/inventory/hcloud.html
            _p='hcloud-python>=1.0.0'
            ;;
        7|openshift)
            # https://docs.ansible.com/latest/plugins/inventory/k8s.html
            # https://docs.ansible.com/latest/plugins/inventory/kubevirt.html
            # https://docs.ansible.com/latest/plugins/inventory/openshift.html
            _p='openshift>=0.6'
            ;;
        8|openstack)
            # https://docs.ansible.com/latest/plugins/inventory/openstack.html
            _p='openstacksdk'
            ;;
        9|linode)
            # https://docs.ansible.com/latest/plugins/inventory/linode.html
            _p='linode_api4>=2.0.0'
            ;;
        10|nmap)
            # https://docs.ansible.com/latest/plugins/inventory/nmap.html
            # Wheezy has all those (and their libs) as dependencies to nmap :o
            _p=''
            for _item in \
                gsfonts \
                ghostscript \
                gnuplot-nox \
                groff \
                netpbm \
                psutils \
                ufraw-batch \
                imagemagick \
                nmap
            do
                _at_p "$_item"
                $agi $_item
            done
            ;;
        11|vmware)
            # https://docs.ansible.com/latest/plugins/inventory/vmware_inventory.html
            # pyvmomi uses: requests and six (installed with Ansible)
            # requests uses: certifi chardet idna urllib3
            _p='urllib3[secure] idna chardet certifi requests pyvmomi'
            ;;
        12|windows)
            # https://docs.ansible.com/ansible/latest/user_guide/windows_winrm.html
            for _item in krb5-user libkrb5-dev python-dev
            do
                _at_p "$_item"
                $agi $_item
            done
            # https://github.com/diyan/pywinrm
            # ipaddress library is only included by default in Python 3.x
            # make sure to install ipaddress library for IPv6 with Python 2.7
            _p='ipaddress pywinrm>=0.3.0'
            #_p='ipaddress pywinrm[kerberos] pywinrm[credssp]'
            ;;
        13)
            # https://www.lisenet.com/2019/ansible-dynamic-inventory-for-proxmox
            # https://github.com/xezpeleta/Ansible-Proxmox-inventory
            # https://github.com/RaSerge/Ansible-Proxmox-inventory
            _p=''
            ;;
        *)
            _p=''
            ;;
    esac
    if test -n "$_p"
    then
        _at_t "$_p"
        $epi $_p
    fi

    _at_p "Install Ansible:extra"
    # graphes
    # https://univers-libre.net/posts/ansible-infrastructure-diagram.html
    # note that core now comes with ansible-inventory command with --graph
    # https://github.com/willthames/ansible-inventory-grapher
    # https://github.com/haidaraM/ansible-playbook-grapher
    # https://github.com/ansiblejunky/ansible-graph
    # https://github.com/sebn/ansible-roles-graph
    # https://github.com/croesnickn/ansible-discover
    _at_t "graphviz"
    $agi graphviz
    # publish inventory
    # note that core now comes with ansible-inventory command with --list
    # https://docs.ansible.com/ansible/latest/cli/ansible-inventory.html
    # https://ansible-cmdb.readthedocs.io/en/stable/usage/
    # https://github.com/fboender/ansible-cmdb
    # review/lint/ci
    # https://www.egi.eu/blog/ansible-style-guide-in-action
    # https://www.jeffgeerling.com/blog/2018/testing-your-ansible-roles-molecule
    # https://univers-libre.net/posts/ansible-molecule.html
    # note that core ansible-playbook command has --syntax-check
    # https://github.com/willthames/ansible-review
    # https://docs.ansible.com/ansible-lint/
    # https://github.com/ansible/ansible-lint
    # https://molecule.readthedocs.io/en/stable/
    # https://github.com/ansible/molecule
    # more Jinja
    # https://github.com/anshumanb/jinja2-cli
    # https://github.com/kolypto/j2cli
    for _p in \
        ansible-inventory-grapher \
        ansible-playbook-grapher \
        ansible-roles-graph \
        ansible-cmdb \
        ansible-lint \
        j2cli[yaml]
    do
        if ! $wic $_p
        then
            _at_t "$_p"
            $epi $_p
        fi
    done
fi


_at_p "$_def Privileges Escalation$_man"
_dipick 'calife' 'chiark-really' 'dpsyco-sudo' #'sudo'


_at_p "$_def Commands Shell"
# Most Linux distros install BASH as default.
# Debian family also ship it's version of ASH
# falselogin fbterm lshell rssh rush
_dipick 'csh' 'fish' 'fizsh' 'ksh' 'mksh' 'mosh' 'pdksh' 'posh' \
    'rc' 'sash' 'shtool' 'tcsh' 'yash' 'zsh' # 'bash' 'dash'


_at_p "$_def Other Interpreter"
# cl-launch
_dipick 'bsh' 'bwbasic' 'ipython' 'jimsh' 'lush' 'php5-cli' 'scsh' 'tkcon'


_at_p "$_def SSH cluster"
# Despite the word cluster, those have nothing to do with:
# broctl cman zeekctl csync2 ...
# It's more similar to https://github.com/byjg/automate or Fabric
# See http://www.fabfile.org/ about using Frabric! and also read:
# - https://www.digitalocean.com/commutinty/tutorials/how-to-use-fabric-to-automate-administration-tasks-deployments
# - https://docs.fabfile.org/en/1.11/tutorial.html
# - https://nosarthur.github.io/coding/2019/05/16/deploy-fabric.html
# - https://serversforhackers.com/c/deploying-with-fabric
# etc. It's not included here 'cause it's better to get it via pip
# See http://taktuk.gforce.inria.fr/ for TakTuk and Kanif
# I no longer use them since I've switched to Ansible... See
# - http://manpages.org/ansible-console
# - https://docs.ansible.com/ansible/latest/cli/ansible-console.html
# - https://blog.linuxserver.io/2018/02/09/q-quick-intro-to-ansible-console/
# - https://yobriefca.se/blog/2017/01/10/ansible-console-an-interactive-repl-for-ansible/
# - https://blog.james-carr.org/a-read-eval-print-loop-for-ansible-4f16f266a3d6
_debsel 'clustershell' 'clusterssh' \
    'dish' 'dsh' 'mussh' 'pconsole' 'pdsh' 'pssh' 'sinfo' 'sslh' 'taktuk'
test "$_p" = 'taktuk' &&
    _p='taktuk kanif'
test -n "$_p" &&
    $agi "$_p"


_at_p "$_def Term. Multiplexer"
# console equivalent of: xpra disper
# also consider gems to show a session in several terms.
_dipick 'screen' 'tmux' 'elscreen' 'dtach' 'byobu'


_at_p "$_def Text Editor"
# by default, 'nano-tiny' and 'vim-tiny' are installed.
# install full 'nano' and 'vim'  in order to have all features.
# question: should I separe line editors from screen editors?
_dipick 'alpine-pico' 'ed' 'elvis-console' 'emacs23-nox' 'emacs24-nox' \
    'fte-console' 'fte-terminal' 'jed' 'joe' 'jove' 'jupp' 'le' 'ledit' \
    'levee' 'mcedit' 'mg' 'nano' 'ne' 'nvi' 'vile' 'vim-nox' 'vim-basic' 'vim'


_at_p "$_def grep alternative"
_dipick 'ripgrep' 'ack-grep' 'sgrep' 'agrep' 'grepcidr' #'grep'


_at_p "$_def Pager"
_dipick 'less' 'more' 'most' 'pg'


_at_p "$_def Revision System"
_debsel 'bzr' 'cvs' 'cssc' 'darcs' 'easygit' 'git' 'mercurial' 'rcs' \
    'rabitvcs-cli' 'subversion' 'tla'
case $_p in
    bzr)
        _p="$_p bzr-grep bzr-search bzr-stats bzr-rewrite commit-patch"
        $wic git >/dev/null &&
            _p="$_p bzr-fastimport bzr-git git-bzr tailor"
        $wic svn >/dev/null &&
            _p="$_p bzr-fastimport bzr-svn tailor"
        $wic cvs >/dev/null &&
            _p="$_p cvs2svn"
        # for server, install also: bzr-email bzr-upload bzr-xmloutput  loggerhead trac-bzr
        ;;
    cvs)
        _p="$_p curves"
        $wic bzr >/dev/null &&
            _p="$_p cvs2svn tailor"
        $wic git >/dev/null &&
            _p="$_p cvs2svn tailor"
        $wic svn >/dev/null &&
            _p="$_p cvs2svn tailor"
        # for server, install also: viewvc viewvc-query
        ;;
    darcs)
        _p="$_p darcsum"
        $wic bzr </dev/null &&
            _p="$_p bzr-fastimport commit-patch tailor"
        # for server, install also: darcsweb darcs-monitor
        ;;
    easygit|git)
        _p="$_p tig"
        $wic hg >/dev/null &&
            _p="$_p mercurial-git tailor"
        $wic bzr >/dev/null &&
            _p="$_p bzr-git git-bzr tailor"
        $wic emacs >/dev/null &&
            _p="$_p magit"
        $wic cvs >/dev/null &&
            _p="$_p cvs2svn"
        # heavy users may add also: legit stgit topgit
        ;;
    mercurial)
        _p="$_p hgview-curses mercurial-nested"
        $wic git >/dev/null &&
            _p="$_p mercurial-git hg-fast-export tailor"
        # for server, install also: mercurial-server trac-mercurial
        ;;
    rcs)
        _p="$_p rcs-blame"
        ;;
    subversion)
        $wic hg >/dev/null &&
            _p="hgsubversion hgsvn tailor"
        _p="$_p svn2cl"
        $wic git >/dev/null &&
            _p="$_p git-svn tailor"
        $wic bzr >/dev/null &&
            _p="$_p bzr-fastimport bzr-svn tailor"
        $wic cvs >/dev/null &&
            _p="$_p cvs2svn tailor"
        # for server, install also: subversion-tools statsvn svn-load svn-workbench websvn viewvc viewvc-query pepper
        ;;
esac
test -n "$_p" &&
    $agi "$_p"


_at_p "$_def Multi-Repos. Tool"
_dipick 'mr' 'myrepos' 'moap'


_at_p "$_def LDAP$_bro"
# not to confuse with things like: gosa lat ldap2(dns|zone) phamm
# those are more like (but console): jxplorer ldapadmin
_dipick 'cpu' 'ldaptor-utils' 'ldap-utils' 'ldapvi' 'shelldap'


_at_p "$_def Calendaring Tool"
# also consider: birthday dates gcalcli email-reminder ical2html leave mhc-utils pcal taglog vpim
# and: hebcal itools jcal
# and: cycle mencal pcalendar
_dipick 'ccal' 'calcurse' 'gcal' 'pal' 'remind' 'when' 'wyrd'


_at_p "$_def Tasks$_man"
_dipick 'calcurse' 'devtodo' 'etm' 'hnb' 'org-mode' \
    'tasque' 'tdl' 'task' 'tasks' 'todotxt-cli' 'tudu' \
    'ukolovnik' 'yagtd' 'yokadi' 'w2do'


_at_p "$_def DOS Files Converter"
_dipick 'toffodos' 'flip' 'dos2unix'


_at_p "$_def JSON Tool"
_dipick 'jparse' 'jq' \
    'lua-json' 'php-service-json' 'ruby-json' 'ruby-multi-json' \
    'python-anyjson' 'python-cjson' 'python-demjson' 'python-simple-json'


_at_p "$_def Passwords$_man (PM)"
if ! _cmd_ok kpcli.pl pwman3 kpcli upass kedpm pwman \
 pebble passman passpie pass cpm ph bw
then
    _select \
        "cpm - Curse based PM using PGP encryption, in C" \
        "gopass - Pass-store read-only nice interface in Go"
        "kedpm - KED's Figaro PM client in Python" \
        "kpcli - KeePassX command line interface in PERL" \
        "kpclix - KeePassX client in PERL, with Xclip support" \
        "pass - Pass-store: directories based PM with PGP, in C" \
        "passhole - KeePass client in Python, with Pass-store looklike" \
        "passmgr  - Simple portable PM, in Go" \
        "passpie  - Configurable colorful directories based PM with PGP, in Python" \
        "pwman3 - Lightweiht command line PM which can use different databases" \
        "ripasso - Pass-store read-only nice interface in Rust" \
        "upass - Pass-store friendly interface in Python" \
        "ylva - Command line PM, in C" \
        "bitwarden - Command-line interface for the service, in NodeJS" \
        "passman-cli - Command-line interface for NextCloud Passman, in Python" \
        "pebble - Command-line interface for NextCloud Passman, in Python" \
        # etc.
    case $_c in
        1|cpm)
            # http://freshmeat.sourceforge.net/projects/cpm
            # https://packages.debian.org/search?keyword=kedpm
            $agi libc6 libcdk6 libcrack2 libdotconf0 libgpg-error0 libgpgme11 libncursesw5 libtinfo5 libxml2 libxml2-utils zlib1g cpm
            ;;
        2|gopass)
            # https://github.com/cortex/gopass
            _make_go github.com/go-qml/qml \
                github.com/limetext/qml-go \
                github.com/cortex/gopass
            # https://github.com/dmulholl/ironclad
            #_make_go github.com/dmulholl/ironclad
            ;;
        3|kedpm)
            # http://kedpm.sourceforge.net/
            # https://packages.debian.org/search?keyword=kedpm
            $agi python-crypto kedpm
            ;;
        4|kpcli)
            # http://kpcli.sourceforge.net
            # https://github.com/tnbut/kpcli
            # https://github.com/alecsammon/kpcli
            # either https://www.cpan.org/modules/INSTALL.html
            #$agi libcpan-distnameinfo-perl liblocal-lib-perl libtry-tiny-perl
            #$agi cpanminus
            #cpan -i Data::Password Crypt::Rijndael Sort::Naturally \
                #Term::Readkey Term::ShullUI Capture::Tiny File::Keepass \
                #Math::Random::ISAAC
            # or system packages
            $agi libdata-password-perl \
                libcrypt-rijndael-perl libsort-naturally-perl \
                libterm-readkey-perl libterm-shellui-perl \
                libcapture-tiny-perl libfile-keepass-perl \
                libmath-random-isaac-perl libmath-random-isaac-xs-perl
            # then
            # (last check shows no change since december 2017 for version
            # 3.2 at https://sourceforge.net/projects/kpcli/files/ but I
            # prefere downloading from source to 'cause package not always
            # available or not at latest version:
            # https://manpages.debian.org/jessie/kpcli/kpcli.1.en.html 2.7-1
            # https://manpages.debian.org/strecth/kpcli/kpcli.1.en.html 3.1-3
            $gul -O $_ulb/kpcli \
                https://raw.githubusercontent.com/alecsalmmon/kpcli/master/kpcli.pl
            ;;
        5|kpclix)
            # https://github.com/caian-org/kpclix
            # either https://www.cpan.org/modules/INSTALL.html
            #$agi libcpan-distnameinfo-perl liblocal-lib-perl libtry-tiny-perl
            #$agi xclip cpanminus
            #cpan -i Data::Password Crypt::Rijndael Sort::Naturally \
                #Term::Readkey Term::ShullUI Capture::Tiny File::Keepass \
                #Math::Random::ISAAC
            # or system packages
            $agi xclip cmake libdata-password-perl \
                libcrypt-rijndael-perl libsort-naturally-perl \
                libterm-readkey-perl libterm-shellui-perl \
                libcapture-tiny-perl libfile-keepass-perl \
                libmath-random-isaac-perl libmath-random-isaac-xs-perl
            # then
            _g_clone caian-org/kpclix &&
                make install
            ;;
        6|pass)
            # https://www.passwordstore.org/
            # https://packages.debian.org/search?keyword=pass
            $agi xclip gnupg2 tree pass
            ;;
        7|passhole)
            # https://github.com/Evidlo/passhole
            $agi gcc libgpgme-dev python3-dev
            $epi kdbxpasswordpwned passhole
            ;;
        8|passmgr)
            # https://github.com/urld/passmgr
            $agi xsel libxmu-dev libxmu6 libxmuu1
            _make_go github.com/atotto/clipboard \
                github.com/bgentry/speakeasy \
                golang.org/x/crypto/scrypt \
                github.com/urld/passmgr/cmd/passmgr
            ;;
        9|passpie)
            # https://passpie.readthedocs.io/
            # https://github.com/marcwebbie/passpie/
            $epi passpie
            # https://passpie.readthedocs.io/en/latest/faq.html#why-is-it-taking-so-long-to-initialize-a-database
            $agi haveged
            # is it possible to make it behave like a Password-store interface?
            # https://passpie.readthedocs.io/en/latest/configuration.html#partial-configuration-file
            $mdp /etc/skel/.password-store
            cat >/etc/skel/.passpierc << EOF
path: ~/.password-store
homedir: ~/.gnupg
autopull: null
autopush: null
copy_timeout: 0
extension: .gpg
genpass_pattern: "[a-z]{5} [-_+=#&%$#}{5} [A-Z]{5}"
EOF
            ;;
        10|pwman3|pwman)
            # https://github.com/pwman3/pwman3
            # https://packages.debian.org/search?keyword=pwman3
            # note that if a RDBMS isn't installed with the biding
            # python-mysqldb or python-pygresql it should use SQLite3
            #$agi python-colorama python-crypto pwman3
            $epi pwman3
            ;;
        11|ripasso)
            # https://github.com/gycos/cursive/wiki/install-ncurses
            # https://vfoley.xyz/rust-compile-speed-ups/
            # https://github.com/cortex/ripasso
            #$agi libgtk-3-dev qtdeclaratives-dev libqt5svg5-dev
            $agi libncursesws-dev cmake cargo ||
                break
            _g_clone cortex/ripasso &&
                cargo clean &&
                #cargo check &&
                cargo build -p ripasso-cursive --out-dir "$_ulb"
                #cargo install
            ;;
        12|upass)
            # https://github.com/Kwpolska/upass
            $epi urwid pyperclip upass
            ;;
        13|titan|ylva)
            # https://github.com/nrosvall/titan
            # https://github.com/nrosvall/ylva
            $agi libsqlite0-dev libsqlite-tcl libssl-dev cmake gcc
            _g_clone nrosvall/titan &&
                make && make install
            ;;
        14|bitwarden)
            $wic npm ||
                $agi software-properties-common nodejs ||
                break
            # https://github.com/bitwarden/cli
            npm install -g @bitwarden/cli
            ;;
        15|passman-cli)
            # https://github.com/douglascamata/passman-cli
            _g_clone douglascamata/passman-cli &&
                python setup.py
            ;;
        16|pebble)
            # https://incerp.org/dvlpt/pebble.html
            $epi incerp.pebble
            ;;
        17|vault)
            # https://www.vaultproject.io/commands/
            # https://www.vaultproject.io/download.html
            # https://learn.hashicorp.com/vault/getting-started/install
            $agi unzip
            _v=1.2.2 # version number at 2019-08-22
            # https://serverfault.com/a/63760
            # https://stackoverflow.com/a/45125525
            case $( uname -m 2>/dev/null ) in
                'x86_64'|'amd64') _a='amd64' ;; # 64-bits
                'i386'|'i686') _a='386' ;; # 32-bits
                'arm') _a='arm' ;; # Arm
                'aarch64'|'aarch64_be'|'armv8[bl]'|'arme[bl]') _a='arm64' ;; # Arm64
            esac
            $gul -O vault.zip \
                https://releases.hachicorp.com/vault/$_v/vaul_${_v}_linux_${_a}.zip &&
                unzip vault.zip && rm vault.zip &&
                cd vault && mv vault "$_ulb/vault" &&
                chmod a+x "$_ulb/vault" &&
                vault-autocomplete-install
            # create a service to start the server and export the key
            # https://learn.hashicorp.com/vault/getting-started/dev-server
            ;;
        18|ratti)
            # https://github.com/tildaslash/RattiCli
            _g_clone tildaslash/RattiCli &&
                ln -s rattic.py "$_ulb/rattic"
            # https://github.com/tildaslash/RattiD
            _g_clone tildaslash/RattiD &&
                $mdp "$_ibd/sbin" &&
                ln -s RattiD.py "$_ibd/sbin/rattid"
            # https://github.com/tildaslash/RatticWeb
            _g_clone tildaslash/RatticWeb #&&
            ;;
    esac
fi


_at_p "$_def Web$_bro"
_dipick 'elinks' 'elinks-lite' 'links' 'links2' \
    'lynx' 'lynx-cur' 'netrik' 'surfraw' 'w3m' \
    'gopher'


_at_p "$_def Mails-n-News Client"
# NotMuch can be used standalone... or with a front-end:
# https://wiki.archlinux.org/index.php/Notmuch lists them
# Some listed alternatives won't show unless repository was registered
# https://www.neomutt.org/distro.html
_debsel 'alpine' 'cone' 'mutt' 'bsd-mailx' 'heirloom-mailx' \
    'mailutils' 's-nail' 'notmuch-mutt' 'neomutt' 'alot' \
    'sup-mail' 'notmuch-vim' 'elpa-notmuch' 'bower' 'ner' \
    'trn4' 'suck' # those 2 laters may requier inn or inn2 server
# explicit dependencies and additional packages
if test "$_p" = 'mutt'
then
    _p='mutt mutt-profiles'
elif test "$_p" = 'notmuch-mutt'
then
    _p='notmuch mutt mutt-profiles notmuch-mutt'
elif test "$_p" = 'alot'
then
    _p='notmuch alot'
elif test "$_p" = 'sup-mail'
then
    _p='ruby-chronic ruby-highline ruby-locale ruby-lockfile ruby-rubymail ruby-mime-types ruby-trollop ruby-unicode ruby-xapian sup-mail'
elif test "$_p" = 'notmuch-vim'
then
    _p='ruby-mail vim-nox vim-addon-manager ruby-notmuch notmuch notmuch-vim'
elif test "$_p" = 'elpa-notmuch'
then
    _p='emacsen-common elpa-notmuch'
elif test "$_p" = 'alot'
then
    _p='python3 python3-configobj python3-notmuch python3-magic python3-gpg alot'
# Here, in fact, we'll need to download and compile
# https://www.neomutt.org/distro.html
# https://gitthub.com/pioto/ner
#else
fi
test -n "$_p" &&
    $agi "$_p"
# we'll also need one of: getmail4 fetchmail gpgv gpgv2 MTA-relay
# also consider packages: pdfgrep mboxgrep grepmail t-prot
# for the dark side of the force: pst-utils readpst


_at_p "$_def File$_bro"
if ! $wic ranger
then
    _debsel 'clex' 'gnuit' 'gt5' 'lfm' 'vfu' 'vifm' 'ranger' 'mc'
    if test "$_p" = 'ranger'
    then
        # img2txt is found in caca-utils
        # pdfto(cairo|html|ppm|ps|text) are found in popler-utils
        # exiftool is found in libimage-exiftool-perl or libimage-info-perl
        $agi caca-utils popler-utils atool libimage-exiftool-perl
        #$agi ranger
        $epi ranger-fm
    elif test -n "$_p"
    then
        $agi "$_p"
    fi
fi


_at_p "$_def FTP Client"
_dipick 'aftp' 'git-ftp' 'ftp' 'ftpcopy' 'ftp-ssl' 'ftp-upload' \
    'lftp' 'noftp' 'netrw' 'tftp' 'tnftp' 'weex' 'wput' 'yafc' \
    'zftp'


_at_p "$_def File Mirroring"
# ftpwatch wget curl axel pavuk sendfile netsend snarf
_dipick 'avfs' 'backup-manager' 'cadaver' 'ftpgrab' 'ftpmirror' \
    'sitecopy' 'rsync'


_at_p "$_def Package$_man"
# ftpwatch wget curl axel
_dipick 'aptitude' 'dselect' 'cupt' 'wajig' 'aptsh'


_at_p "$_def Local Cheats$_man"
# To ease maintenance, I favor only the command "cheat"
# and it should work with users ~/.cheats directory
if ! $wic cheat cheatly eg tldr.py >/dev/null
then
    _select \
        "cheat - Chris Allen Lane, Python implementation" \
        "jahendrie - James Hendrie, Bash reimplementation" \
        "dufferzafar - Chadab Zafar, Go reimplementation" \
        "lucaswerkmeister - Lucas Werkmeiste, Bash cheats function" \
        "weakish - Jang Rush, own GiT cheats repository in Bash" \
        "srsudar - Sam Sudar, Python own examples in Markdown" \
        "lord63 - , Python client for local tldr repository" \
        #"arthurnn - Arthur Nogueira Neves, own github cheats repository in Ruby" \
        #"chhsiao90 - Chun-Han Hsiao, extension of cheat in Python" # should be per user\
        #"torsten - Torsten Becker, Ruby self-contained script" \
    case $_c in
        1|cheat)
            # https://github.com/cheat/cheat
            $epi cheat
            ;;
        2|jahendrie)
            # https://github.com/jahendrie/cheat
            _g_clone jahendrie/cheat || break
            MANFILE=cheat.1.gz
            DATADIR="$_uld/cheat"
            install -D -m 0755 "src/cheat.sh"  "$_ulb/cheat" &&
            $mdp "$DATADIR" &&
            cp -rv data "$DATADIR/sheets" &&
            install -v -D -m 0644 LICENSE "$DATADIR/LICENSE" &&
            install -v -D -m 0644 README "$DATADIR/README" &&
            install -D -m 0644 "doc/$MANFILE" "$_uld/man/man1/$MANFILE"
            ;;
        3|dufferzafar)
            # https://github.com/dufferzafar/cheat
            _make_go github.com/dufferzafar/cheat
            ;;
        4|lucaswerkmeister)
            # https://github.com/lucaswerkmeister/cheats
            _g_clone lucaswerkmeister/cheats || break
            $wic bash >/dev/null || break
            cp -rv cheats /etc/skel/.cheats
            # the following simulate the install.sh for all users
            #$mdp /etc/skel/bin
            #cp -v cheats.sh /etc/skel/bin
            #grep -qs 'cheats.sh' $_brc ||
            #printf "\n\nsource ~/bin/cheats.sh" >>$_brc
            # but I prefer this 
            cp -rv cheats.sh /etc/profile.d/
            ;;
        5|weakish)
            # https://github.com/weakish/cheat
            _g_clone weakish/cheat || break
            for _item in $( ls -1 cheat*.sh )
            do
                cp -f $_item $_ulb/$( basename $_item .sh ) &&
                    chmod 755 $_ulb/$( basename $_item .sh )
            done
            ;;
        6|srsudar)
            # https://github.com/srsudar/eg
            $epi eg
            cat >/etc/skel/.egrc << EOF
[eg-config]
custom-dir = ~/.cheats
#examples-dir = 
#pager-cmd = 'cat'
#squeeze = true
#color = false
[eg-color]
#pound = '\x1b[34m\x1b[1m'
#heading = '\x1b[31m\x1b[1m'
heading = '\x1b[38;5;172m'
#prompt = '\x1b[36m\x1b[1m'
#code = '\x1b[32m\x1b[1m'
#backticks = '\x1b[34m\x1b[1m'
#[substitution]
#remove-indents = ['^    ', '', True]
EOF
            $mdp /etc/skel/.cheats
            cd "$_ulb"
            ln -s eg cheat
            cd -
            ;;
        7|lord63)
            # https://github.com/lord63/tldr.py
            $epi tldr.py
            _g_clone tldr-pages/tldr || break
            ln -s "$_uls/tldr" /etc/skel/.cheats
            cat >/etc/skel/.tldrrc << EOF
colors:
    command: cyan
    description: magenta
    usage: yellow
platform: linux
repo_directory: $_uls/tldr
#colours in: black, red, green, yellow, blue, magenta, cyan, white
EOF
            cd "$_ulb"
            ln -s tldr.py cheat
            cd -
            ;;
        8|arthurnn)
            # https://github.com/arthurnn/cheatly
            $eri cheatly
            ;;
        9|chhsiao90)
            # https://github.com/chhsiao90/cheat-ext
            $epi cheat cheat-ext
            ;;
        x|torsten)
            # https://github.com/torsten/cheat
            _g_clone torsten/cheat || break
            ln -s "$( pwd )/cheat.rb" $_ulb/cheat
            ;;
    esac
fi


_at_p "$_def Remote Cheats$_bro"
# clients for tldr-pages are mainly grab from
# - https://github.com/tldr-pages/tldr/blob/master/README.md#clients
# - https://github.com/tldr-pages/tldr/wiki/TLDR-clients#console-clients
# - https://tldr.sh#installation
# ToDo: consider adding my own for
# - https://www.CommandLineFu.com/site/api
# - https://github.com/Kapeli/cheatsheets
#  (that's primary made for https://kapeli/dash)
# - https://github.com/rstacruz/cheasheets
#  (that's primary made for https://devhints.io)
# - https://www.mankier.com/api
#  (especially for https://ww.mankier.com/explain)
if ! _cmd_ok cht.sh cht bro tldr tlcr
then
    _select \
        "chubin - Igor Chubin, CLI for https://cheat.sh/ " \
        "hubsmoke - Sina Iman, Ruby script for http://bropages.org" \
        "raylee - Ray Lee, Bash$_nlr" \
        "pepa65 - ?, Bash$_nlr" \
        "porras - Sergio Gil Pérez de la Manga, Crystal$_nlr" \
        "pranavraja - Pranav Raja, Go$_nlr" \
        "4d63 - Leigh McCulloch, Go$_nlr" \
        "elecprog - Evert Provoost, Go$_nlr" \
        "isacikgoz - Ibrahim Serdar Acikgoz, Go$_nlr" \
        "k3mist - Daniel Robbins, Go$_nlr" \
        "psibi - P. Sibi, Haskel$_nlr" \
        "tldr-pages - , Node.JS$_nlr" \
        "RosalesJ - Jacob Rosales Chase, OCaml$_nlr" \
        "skaji - Shoichi Kaji, PERL$_nlr" \
        "BrainMaestro - Ezinwa Okpoechi, PHP$_nlr" \
        "tldr pages - , Python$_nlr" \
        "YellowApple - Ryan S. Northrup, Ruby on Bales$_nlr" \
        "rilut - Rizky Luthfianto, Rust$_nlr" \
        "dbrgn - Danilo Bargen, Rust$_nlr" \
        #"defunkt - Chris Wanstrath, Ruby CLI for http://cheat.errthelog.com/ " \
    case $_c in
        1|chubin)
            # https://github.com/chubin/cheat.sh
            # https://github.com/chubin/cheat.sheets
            # https://www.linuxuprising.com/2019/07/cheatsh-shows-cheat-sheets-on-command.html
            $gul -O $_ulb/cht.sh https://cht.sh/:cht.sh &&
                chmod a+x $_ulb/cht.sh &&
                $agi curl rlwrap
            ;;
        2|hubsmoke)
            # https://github.com/hubsmoke/cheatly
            # http://bropages.org
            $eri bro
            ;;
        3|raylee)
            # https://github.com/raylee/tldr
            $gul -O "$_pdb/tldr" \
                https://raw.githubusercontent.com/raw/raylee/tldr/master/tldr &&
                chmod a+x "$_pdb/tldr"
            grep -qs 'tldr' $_bcd/* ||
                echo 'complete -W "$(tldr 2>/dev/null --list)" tldr' >$_bcd/tldr
            $agi coreutils grep unzip
            ;;
        4|pepa65)
            # https://gitlab.com/pepa65/tldr-bash-client
            $gul -O "$_pdb/tldr" https://4e4.win/tldr &&
                chmod a+x "$_pdb/tldr"
            grep -qs 'tldr' $_bcd/* ||
                cat >$_bcd/tldr << 'EOF'
cachedir=~/local/share/tldr
complete -W "$(q=($cachedir/*/*); sed "s@\.md @ @g" <<<$({q[@]##*/})" tldr
EOF
            $agi coreutils grep unzip
            ;;
        5|porras)
            # https://github.com/porras/tlcr
            $agi tlcr
            ;;
        6|pranavraja)
            # https://github.com/pranavraja/tldr
            _make_go github.com/pranavraja/tldr
            ;;
        7|4d63)
            # https://github.com/leighmcculloch/tldr
            _make_go 4d63.com/tldr
            ;;
        8|elecprog)
            # https://github.com/elecprog/tldr
            _make_go github.com/elecprog/tldr
            env "PATH=$PATH" sh -c "tldr --bash-completion >$_bcd/tldr"
            chmod 644 $_bcd/tldr
            ;;
        9|isacikgoz)
            # https://github.com/isacikgoz/tldr
            _make_go github.com/isacikgoz/tldr
            grep -qs 'TLDR_OS' /etc/profile.d/* ||
                echo "export TLDR_OS=linux" >/etc/profile.d/tldr.sh
            ;;
        10|k3mist)
            # https://github.com/k3mist/tldr
            _make_go bitbucket.org/djr2/tldr
            $mdp /etc/skel/.tldr
            cat >/etc/skel/.tldr/config.json << EOF
{
"pages_uri": "https://raw.githubusercontent.com/tldr-pages/tldr/master/pages/",
"zip_uri": "https://tldr-pages.github.io/assets/tldr.zip",
"banner_color_1": 36,
"banner_color_2": 34,
"tldr_color": 97,
"header_color": 34,
"header_decor_color": 97,
"platform_color": 90,
"description_color": 0,
"example_color": 36,
"hypen_color": 0,
"syntax_color": 31,
"variable_color": 0,
}
EOF
            ;;
        11|psibi)
            # https://github.com/psibi/tldr-hs
            $wic cabal ||
                {
                    $agi haskell-platform
                    cabal update
                } ||
                break
            $wic stack ||
                {
                    $gul -O- https://get.haskellstack.org/ | sh
                    stack upgrade 
                } ||
                break
            stack install tldr
            ;;
        12|tldr-pages-npm)
            $wic npm ||
                $agi software-properties-common nodejs ||
                break
            # https://github.com/tldr-pages/tldr-node-client
            npm install -g node-gyp
            npm install -g webworker-threads
            npm install -g tldr
            ;;
        13|RosalesJ)
            # https://github.com/RosalesJ/tldr-ocaml
            $wic opam ||
                $agi ocaml-nox ocaml-tools ||
                break
            opam install tldr
            ;;
        14|skaji)
            # https://github.com/skaji/perl-tldr
            $agi cpanminus
            #cpan -i App::tldr
            cpanm -nq App::tldr
            ;;
        15|brainmaestro)
            # https://github.com/brainmaestro/tldr-php
            $agi php5-cli php-cli #php7.0-cli
            $wic composer ||
                {
                    $gul https://getcomposer.org/installer | php
                    mv composer.phar "$_ulb/composer"
                    chmod a+x "$_ulb/composer"
                } ||
                break
            composer global require brainmaestro/tldr
            ;;
        16|tldr-pages-pip)
            # https://github.com/tldr-pages/tldr-python-client
            $epi tldr
            ;;
        17|YellowApple)
            # https://github.com/YellowApple/tldrb
            $wic gem >/dev/null || $agi ruby
            $eri tldrb
            ;;
        18|rilut)
            # https://github.com/rilut/rust-tldr
            _inst_ru tldr
            ;;
        19|dbrgn)
            # https://github.com/dbrgn/tealdeer
            _inst_ru tealdeer
            ;;
        x|defunkt)
            # https://github.com/defunkt/cheat
            $eri cheat
            ;;
    esac
fi


_at_p "$_def DotFiles$_man"
# They're many solutions available. This script can install only solution
# available in repositories (that's to keep things simple.)  However it's
# aware when something else is in use (installed manually or via .setup
# script in a know path isn't it?) The following are tested:
# - https://github.com/koenwoortman/dots (things are defined in dotsrc.json and it uses jq command)
_cmd_ok dots ||
    _dipick 'rcm' 'stow' 'vcsh' 'xstow' 'git-annex'
    # beware, for RCM, be sure to add the repository before
    # look at instructions at https://github.com/thoughbot/rcm


_at_p "Install Extra Python Packages"
# ensure the following packages are there
test -e "$_sdn/$_hos.pip.lst" &&
    _instalf "$_sdn/$_hos.pip.lst" "$epi -U"

