# freenomAutoIP

Freenom automatic ip updater.

"freenomAutoIP" is a simple script written in Ruby, with no externals gems used.
It only log into freenom page if ip changed, so no inneccesary requests are made


"config.yml" file must be on the same folder, and must be writable.
You can add as many sites as you need, just make sure that the entry name is not duplicated
on the yaml file (site1 and site2 in the example bellow).

Inside each record, you should specify "line", "type", "name", "ttl" and "value".
"priority" can be specified, but not required.

"domainid" field can be easily found:

Click "Manage Domain" on the desired domain
https://my.freenom.com/clientarea.php?action=domains 

Take the id from the url:
https://my.freenom.com/clientarea.php?action=domaindetails&id=*TAKETHISNUMBER*

`
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
`

# Work In Progress 👷‍♂️: #

* Add useful comments
* Implement logger
* Check ENV variable to specify another config file path
* Improve checks, update and logout are not beign verified right now
* Check for typos and misspelling on this readme


### Possible improvements ###

This will be only added if requested by other users

* Get domainid from webpage instead of specifying it on yaml file
* Your ideas


### Known issues ###

* Domain records must exists before running this script. New domains seems to use different requests