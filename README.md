# freenomAutoIP

Freenom automatic ip updater.

"freenomAutoIP" is a simple script written in Ruby, with no externals gems used.


Configuration file must be writable, as public ip is stored and used to check if ip has changed.

This script stops if ip has no changed so no unnecessary requests are made.

## CONFIG FILE 🔧 (config.yml) ##
You can add as many sites as you need, just make sure that the entry name is not duplicated
on the yaml file (site1 and site2 in the example bellow).

Inside each record, you should specify "line", "type", "name", "ttl" and "value".
"priority" can be specified, but not required.

"domainid" field can be easily found:

Click "Manage Domain" on the desired domain
https://my.freenom.com/clientarea.php?action=domains 

Take the id from the url:
https://my.freenom.com/clientarea.php?action=domaindetails&id=__TakeThisNumber__

```
---
lastIp: 127.0.0.1 # Used to check if update needed
username: # Your email
password: # Your password
sites:
  site1:
    name: # example.tk
    domainid: # domain id, found in url
    records:
      0:
        line:
        type: A
        name:
        ttl: 300
        value: _IP_ # _IP_ will be replaced with your public ip
      1:
        line:
        type: A
        name: WWW
        ttl: 300
        value: _IP_
      2:
        line:
        type: MX
        name:
        ttl: 300
        value: example.tk
        priority: 10

  site2:
    name: # example2.tk
    domainid: # domain id, found in url
    records: 
      0:
        line:
        type: A
        name:
        ttl: 300
        value: _IP_
      1:
        line:
        type: A
        name: WWW
        ttl: 300
        value: _IP_
```

### ENV Variables 💻 ###

There are some optional ENV variables

| ENV var       | Description|
| -------       | -----------|
| FNIP_CONFIG   | Yaml config file path |
| FNIP_LOG      | Store log into specified file |
| FNIP_LOGLEVEL | Logger verbosity level |

# Work In Progress 👷‍♂️: #

* Improve source code comments
* Improve logger, add log rotation, etc
* Improve update and logout checks, they are not beign verified right now
* Check for typos and misspelling on this readme


### Possible improvements ###

This will be only added if requested by other users

* Get domainid from webpage instead of specifying it on yaml file
* Your ideas


### Known issues ###

* Domain records must exists before running this script. New domains seems to use different requests