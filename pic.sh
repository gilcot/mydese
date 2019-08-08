#!/bin/sh
# ex: ai:sw=4:ts=4
# vim: ai:ft=sh:sw=4:ts=4:ff=unix:sts=4:et:fenc=utf8
# -*- sh; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4;
# atom: set usesofttabs tabLength=4 encoding=utf-8 lineEnding=lf grammar=shel;
# mode: shell; tabsoft; tab:4; encoding: utf-8; coding: utf-8;
##########################################################################
# Put things I used to add to my De(bi|vu)an box
# everytime I create a new box, I use to perfom those setings

# for _at_? functions, set terminal's width
# $_w: is 0 if term. can't handle colors, 
#      otherwise is known available columns
if command -v tput >/dev/null
then
    if command -v stty >/dev/null
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

# title of current part (main step)
# $1: message to show
_at_p() {
    if test $_w -ne 0
    then
        printf "\033[44;37m => %*s\033[0m\n" \
            "-$(( _w - 4 ))" "$1"
    else
        echo " => $1"
    fi
}

# title of current task (a sub step)
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

# ask for choice within passed items
# $@: items to choose from, in order
# $_c: result (i.e. choice...)
_c=0
_select() {
    _i=0
    for _m in 'none' "$@"
    do
        if test $_w -ne 0
        then
           printf "\033[44;37m\t%d\t%*s\033[0m\n" \
               $_i "-$(( _w - 16 ))" "$_m"
        else
            printf "\t%d\t%s\n" $_i "$_m"
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
}

# alias for recurrent commands
# agi -qq or -q=2 implies -y that is tempered with --trivial-only
agi="apt-get -qq --trivial-only install"
epi="pip -qq --retries 2 --timeout 7 install"

# install with list from file
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

##### let's proceed now ###


_at_p "checking"

# All the following actions should be performed as root
_at_t "user is root"
test $( id -u ) -eq 0 || exit 1

# Following commands are used before packages installation
# (except for DMIDecode, but it may not be in your default list)
for _c in readlink dirname hostname apt-get dmidecode
do
    _at_t "$_c in path"
    command -v $_c || exit 1
done

# so I won't repeat myself later
_dir="$( readlink -fns "$( dirname $0 )" )"
_dom="$( hostname -d )"


_at_p "update system"

# Put client or other specific additions
# note that this can be done later with Ansible
_at_t "site extra sources lists"
find $_dir \
    -name "*${_dom:-localnet}.list" \
    -exec cp -nuv {} /etc/apt/sources.list.d/ \;

# Alternatively, you may use the following to add setting
# (e.g. files in /etc/profile.d/ /etc/apt/apt.conf.d/ and so)
# if this is not relevant for the following (for example,
# exporting http_proxy and https_proxy in the environment),
# it's better to do it later via nice Ansible playbook
if test -e "${_dom:-localnet}.setup"
then
    _at_t "load site extra settings"
    . "${_dom:-localnet}.setup"
fi

# Usefull if source list is changed before
# Stop on network issue or if lists need to be fix...
_at_t "refresh repositories data"
apt-get -qq update || exit 2

# Upgrade to correct latest
# Also stop if the process went wrong...
_at_t "refrest installed files"
apt-get -qq upgrade || exit 2

_at_p "install additionnal D packages"
# ensure the following packages are there
if test -e "$_dir/all.deb.lst"
then
    # As I'm sharing this on a public Git, let's give ability to have
    # own default packages (e.g. one may prefere Nano instead of ViM)
    # So people won't need to patch my maintenance releases for that!
    _instalf "$_dir/all.deb.lst"
else
    # I should keep that list as small as possible, as I have Ansible
    # playbooks to add and configure some other stuffs when required.
    for _p in ssh sshpass sudo vim gnupg-agent pwgen cowsay mtr \
        cpm screen byobu vim git tig ca-certificates linuxlogo \
        cifs-utils lsb-release gpm shelldap ldap-utils sl jq rlpr
    do
        _at_t "$_p"
        $agi $_p
    done
fi

# Install virtual machine additionals
_virt="$( dmidecode -s system-product-name )"
case $_virt in
    'VirtualBox') # Sun/Oracle VirtualBox
        # this is required to mount shared folders...
        _p='virtualbox-guest-dkms'
        ;;
    'VMware Virtual Platform') # VMware Workstation
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
            _p="autoconf gcc-4.1* make psmisc linux-header-$(uname -r)"
            #_p="autoconf gcc-4.3* make psmisc linux-header-$(uname -r)"
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
    'HVM domU') # Xen
        _p=''
        ;;
    *) # Xen
        _p=''
        ;;
esac
if test -n "$_p"
then
    _at_t "$_p"
    $agi $_p
fi

# Install specific packages to that host
# note that this can be done later with Ansible
if test -e "$_dir/$( hostname -s).deb.lst"
then
    _instalf "$_dir/$( hostname -s).deb.lst"
fi

# Now some clean up bfore going on
_at_t "cleaning up"
apt-get autoremove --purge &&
    apt-get autoclean


_at_p "set system configuration"
# some setings I used to

if command -v linuxlogo #>/dev/null
then
    _at_t "login banner"
    linuxlogo -b >/etc/issue
fi

_at_t "root bashrc"
if test -e $_dir/root_bashrc
then
    # As I'm sharing this on a public Git, let's give ability to have
    # something different from mine
    # So people won't need to patch my maintenance releases for that!
    cat $_dir/root_bashrc > /root/.bashrc
else
    cat > /root/.bashrc << 'EOF'
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
    cat > /root/.profile << 'EOF'
# ~/.profile: executed by Bourne-compatible login shells.

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

mesg n
EOF


_at_p "setup Python packages manager"
# Let's go beyong 'easy_install' but get the latest from source
# (an "$agi python-pip" will leave us with an outdate version)
if ! command -v pip #>/dev/null
then
    # instructions from https://github.com/pypa/get-pip
    _at_t "retrieve installer"
    test -e get-pip.py ||
        wget https://bootstrap.pypa.io/get-pip.py || exit 2
    _at_t "installer pip: lastest"
    python get-pip.py || exit 2
fi

if test -e "$_dir/all.pip.lst"
then
    # As I'm sharing this on a public Git, let's give ability to have
    # own default packages instead of always patching this script
    _at_p "install common P packages"
    _instalf "$_dir/all.pip.lst" "$epi"
else

    _at_p "install Ansible:base"
    # I always use the latest stable that may not be available for old distro
    # Also, one may add the file /etc/apt/sources.list.d/ansible.list
    # with this content for example:
    # deb http://ppa.launchpag.net/ansible/ubuntu trusty main
    # Those steps are performed under Ubuntu with the command:
    # (you'll need to do before: $agi software-properties-common )
    # apt-add-repository ppa:ansible/ansible
    # cryptography-packaging
    # pyOpenSSL
    if ! command -v ansible #>/dev/null
    then
        for _p in \
            'PyYAML' \
            'MarkupSafe jinja2' \
            'pycparser cffi' \
            'six ipaddress enum34 cffi asn1crypto cryptography' \
            'ansible'
        do
            _at_t "$_p"
            $epi $_p
            #$epi -U urllib3[secure] $_p # avoid switching to full URLlib
        done
    fi

    _at_p "hosts infrastructure"
    # https://docs.ansible.com/latest/plugins/inventory.html
    _select \
        "Amazon Web Service EC2/RDS" \
        "Azure Resource Manager" \
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
        1)
            # https://docs.ansible.com/latest/plugins/inventory/aws_ec2.html
            # https://docs.ansible.com/latest/plugins/inventory/aws_rds.html
            _p='boto3 botocore'
            ;;
        2)
            # https://docs.ansible.com/latest/plugins/inventory/azure_rm.htl
            _p='azure>=2.0.0'
            ;;
        3)
            # https://docs.ansible.com/latest/plugins/inventory/docker_swarm.html
            _p='docker'
            ;;
        5)
            # https://docs.ansible.com/latest/plugins/inventory/gitlab_runners.html
            _p='python-gitlab>=1.8.0'
            ;;
        4)
            # https://docs.ansible.com/latest/plugins/inventory/gcp_compute.html
            _p='google-auth>=1.3.0'
            ;;
        6)
            # https://docs.ansible.com/latest/plugins/inventory/hcloud.html
            _p='hcloud-python>=1.0.0'
            ;;
        7)
            # https://docs.ansible.com/latest/plugins/inventory/k8s.html
            # https://docs.ansible.com/latest/plugins/inventory/kubevirt.html
            # https://docs.ansible.com/latest/plugins/inventory/openshift.html
            _p='openshift>=0.6'
            ;;
        8)
            # https://docs.ansible.com/latest/plugins/inventory/openstack.html
            _p='openstacksdk'
            ;;
        9)
            # https://docs.ansible.com/latest/plugins/inventory/linode.html
            _p='linode_api4>=2.0.0'
            ;;
        10)
            # https://docs.ansible.com/latest/plugins/inventory/nmap.html
            # Wheezy has all those (and their libs) as dependencies to nmap :o
            _p=''
            for _i in \
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
                _at_p "$_i"
                $agi $_i
            done
            ;;
        11)
            # https://docs.ansible.com/latest/plugins/inventory/vmware_inventory.html
            # pyvmomi uses: requests and six (installed with Ansible)
            # requests uses: certifi chardet idna urllib3
            _p='urllib3[secure] idna chardet certifi requests pyvmomi'
            ;;
        12)
            # https://docs.ansible.com/ansible/latest/user_guide/windows_winrm.html
            for _i in krb5-user libkrb5-dev python-dev
            do
                _at_p "$_i"
                $agi $_i
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

    _at_p "setup Ansible:extra"
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
    for _p in \
        ansible-inventory-grapher \
        ansible-playbook-grapher \
        ansible-roles-graph \
        ansible-cmdb \
        ansible-lint
    do
        if ! command -v $_p
        then
            _at_t "$_p"
            $epi $_p
        fi
    done
fi


_at_p "install web browser"
if ! command -v elinks &&
    ! command -v links2 &&
    ! command -v netrik &&
    ! command -v links &&
    ! command -v lynx &&
    ! command -v w3m
then
    _select \
        "elinks" \
        "elinks-lite" \
        "links" \
        "links2" \
        "lynx" \
        "lynx-cur" \
        "netrik" \
        "surfraw" \
        "w3m"
    case $_c in
        1)
            _p='elinks'
            ;;
        2)
            _p='elinks-lite'
            ;;
        3)
            _p='links'
            ;;
        4)
            _p='links2'
            ;;
        5)
            _p='lynx'
            ;;
        6)
            _p='lynx-cur'
            ;;
        7)
            _p='netrik'
            ;;
        8)
            _p='surfraw'
            ;;
        9)
            _p='w3m'
            ;;
        *)
            _p=''
            ;;
    esac
    test -n "$_p" &&
        $agi "$_p"
fi


_at_p "install mail-n-news client"
# NotMuch can be used standalone... or with a front-end:
# https://wiki.archlinux.org/index.php/Notmuch lists them
if ! command -v notmuch-emacs-mua &&
    ! command -v sup-mail &&
    ! command -v notmuch &&
    ! command -v s-nail &&
    ! command -v alpine &&
    ! command -v mailx &&
    ! command -v pine &&
    ! command -v mutt &&
    ! command -v cone &&
    ! command -v mail
then
    _select \
        "Alpine" \
        "cone" \
        "Mutt" \
        "BSD mailx" \
        "Heirloom mailx" \
        "GNU mail utils" \
        "S-nail" \
        "Notmuch-mutt" \
        "NeoMutt" \
        "Alot" \
        "Sup-mail" \
        "Notmuch-vim" \
        "elpa-Notmuch" \
        "Bower" \
        "Notmuch Email Reader" \
        #"what else?" \
    case $_c in
        1)
            _p='alpine'
            ;;
        2)
            _p='cone'
            ;;
        3)
            _p='mutt mutt-profiles'
            ;;
        4)
            _p='bsd-mailx'
            ;;
        5)
            _p='heirloom-mailx'
            ;;
        6)
            _p='mailutils'
            ;;
        7)
            _p='s-nail'
            ;;
        8)
            _p='notmuch mutt mutt-profiles notmuch-mutt'
            ;;
        9)
            # https://www.neomutt.org/distro.html
            _p='neomutt'
            ;;
        10)
            _p='notmuch alot'
            ;;
        11)
            _p='ruby-chronic ruby-highline ruby-locale ruby-lockfile ruby-rubymail ruby-mime-types ruby-trollop ruby-unicode ruby-xapian sup-mail'
            ;;
        12)
            _p='ruby-mail vim-nox vim-addon-manager ruby-notmuch notmuch notmuch-vim'
            ;;
        13)
            _p='emacsen-common elpa-notmuch'
            ;;
        14)
            _p='python3 python3-configobj python3-notmuch python3-magic python3-gpg alot'
            ;;
        15)
            # here in fact, we need to download and compile
            # https://gitthub.com/wangp/bower
            _p='bower'
            ;;
        16)
            # here in fact, we need to download and compile
            # https://gitthub.com/pioto/ner
            _p='ner'
            ;;
        *)
            _p=''
            ;;
    esac
    test -n "$_p" &&
        $agi "$_p"
    # we'll also need one of: getmail4 fetchmail MTA-relay
fi


_at_p "install file manager"
if ! command -v ranger &&
    ! command -v vifm &&
    ! command -v lfm &&
    ! command -v mc
then
    _select \
        "lfm: Ligthweigh File Manager" \
        "vifm: File Manager with vi keybing" \
        "ranger: File Manager in Python" \
        "mc: Midnight Commander" \
        #"add yours" 
    case $_c in
        1)
            $agi lfm
            ;;
        2)
            $agi vifm
            ;;
        3)
            $agi img2txt atool pdftotext exiftool
            #$agi ranger
            $epi ranger-fm
            ;;
        4)
            $agi mc
            ;;
    esac
fi


_at_p "install cheat manager"
if ! command -v cheat &&
    ! command -v cheat-ext
then
    _select \
        "cheat/cheat" \
        "chhsiao90/cheat-ext" \
        "jahendrie/cheat"
    case $_c in
        1)
            $epi cheat
            ;;
        2)
            $epi cheat-ext
            ;;
        3)
        # We could use trick from https://gist.github.com/jwebcat/5122366
        # and https://unix.stackexchange.com/a/421576
        #wget --no-check-certificate --content-disposition \
        #    https://github.com/jaheadrie/cheat/a/master.zip
        # but we'll need unzip. So let's use git way as it's installed
        # and without depth limit: https://stackoverflow.com/a/31733152
            #git clone -q https://github.com/jahendrie/cheat.git &&
            git clone -q https://github.com/jahendrie/cheat.git &&
                cd cheat || break
        # Also need to have 'make' installed... Let's do it manually
            PREFIX=/usr
            MANPATH="$PREFIX/share/man1"
            MANFILE=cheat.1.gz
            DATAPATH="$PREFIX/share/cheat"
            install -D -m 0755 "src/cheat.sh"  "$PREFIX/bin/cheat" &&
            mkdir -pv "$DATAPATH" &&
            cp -rv data "$DATAPATH/sheets" &&
            install -v -D -m 0644 LICENSE "$DATAPATH/LICENSE" &&
            install -v -D -m 0644 README "$DATAPATH/README" &&
            install -D -m 0644 "doc/$MANFILE" "$MANPATH/$MANFILE"
            ;;
    esac
fi


_at_p "install extra P packages"
# ensure the following packages are there
if test -e "$_dir/$( hostname -s).pip.lst"
then
    _instalf "$_dir/$( hostname -s).pip.lst" "$epi -U"
fi

