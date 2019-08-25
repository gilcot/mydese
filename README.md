# My Debian-likes Setup

This repository holds my recipes to set up **my working box** quickly.

             _sudZUZ#Z#XZo=_
          _jmZZ2!!~---~!!X##wa
       .<wdP~~            -!YZL,
      .mX2'       _%aaa__     XZ[.
      oZ[      _jdXY!~?S#wa   ]Xb;
     _#e'     .]X2(     ~Xw|  )XXc
    ..2Z`      ]X[.       xY|  ]oZ(
    ..2#;      )3k;     _s!~   jXf`
     1Z>      -]Xb/    ~    __#2(
     -Zo;       +!4ZwaaaauZZXY'
      *#[,        ~-?!!!!!!-~
       XUb;.
        )YXL,,
          +3#bc,
            -)SSL,,
               ~~~~~

Frech companies are funny: they hire you as a _Unix_ or _Linux_ 
administrator (for example), and you spent all your working hours,
but you have to work from a _Windows_ station. I try to used on that,
but, after a week with _PuTTy_ windows everywhere, I end up installing
a virtual machine with a _Debian_ distro (this is my favorive at work,
whereas I use _Slackware_ at home, and really don't need neither any
rolling release nor some other nice solid reach featured.)

Well, as Ops/Admin networks can't and shouldn't accessed from outside, I
cannot have a working box outside the corporation. It may take arond a
month to get everything set up because I don't remeber everything I've
installed for some reason, until I need it again and have to take time to
get it work as I like. I don't go a template way either because I need to
stay flexible (depending on the contractor, I may use _VMware workstation_
or _Oracle VirtualBox_ or even some container! also there're specific parts
to care of) So this repository is a work-in-progress with very few changes.

## new machine base

Of course, the first step is to create the <abbr
title="virtual machine">VM</abbr> (or configure a <abbr
title="physical machine">PM</abbr> for the purpose) then install the 
<abbr title="operating system">OS</abbr>.

### Post-Install Configuration

After a fresh install, with a mininal/net ISO, I need some tweaking and
have to add some enterprise stuffs to have a box ready for my own use.
That's the purpose of this script. It usage is very simple:
```shell
# be sure to switch to root first, e.g:
su -
# download the script second, e.g:
wget https://raw.githubusercontent.com/gilcot/mydese/master/pic.sh
# launch the script at last, e.g:
sh pic.sh
```
Well, but what if you have different needs? Easy: before launching the
script, prepare one of those files:
  - some files for specific things related to the organisation
    - `*.list`: specific source lists to add
    - `$domainname.setup`: shell commands source before other processing
    - `root_bashrc`: own `~/root/.bashrc` instead of script default
  - two files to override default packages installation
    - `all.deb.lst`: list of system packages to install
    - `all.pip.lst`: list of _Python_ packages to install
  - two files for additional packages installation
    - `$hostname.deb.lst`: list of system packages to install
    - `$hostname.pip.lst`: list of _Python_ packages to install

Packages lists can be retrieved, for example, from:
```shell
# Debian packages currently installed
dpkg --get-selections
# Python packages currently installed
pip list
```
But beware: only the first column is used, and therefore versions
information are left (in fact one may use comments there.) However,
if you need a specific version instead of the latest, add it to the
name with the packages manager syntax.

Last words: Known alternatives are provided for some console programms.
(I don't use any X application, and won't include things not in standard
repositories.)

