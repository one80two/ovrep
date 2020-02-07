# OpenVAS Reporter

This is just a plain simple bash script that eats a list of OpenVAS tasks (names or UUIDs), together with a list of hosts and then spits a PDF report for each host in the list. 
It's only purpose is to easily **automate** and **crontab** the generation of reports for more than one task and more than one host, by using lists for both.
#### Table of contents
[1. Requirements](#Requirements)

[2. Usage](#Usage)

[3. Future improvements](#Future-improvements)

## 1. Requirements

####  OpenVAS Management Protocol (omp)
[Link](https://docs.greenbone.net/GSM-Manual/gos-3.1/en/omp.html)

The OpenVAS Management Protocol utility is used for the interaction with the OpenVAS manager. It actually queries for a certain host in the OpenVAS list of findings for the specified task and then generates the PDF reports.
You need to have configured the connection details in `$(HOME)/omp.config`. For example:
```[Connection]
host=gsm
port=9390
username=webadmin
password=password
```
The default filter for the query is the default one used also on the web dashboard.
```
filter="host=<host> autofp=0 apply_overrides=1 notes=1 overrides=1 result_hosts_only=1 first=1 rows=100 sort-reverse=severity levels=hml min_qod=70"
```
Currently, there is no option for changing the default filter, but it can be done by modifying the script.
####  XMLStarlet
[Link](http://xmlstar.sourceforge.net/)

OMP is XML based. It sends commands formatted in XML and receives XML responses. XMLStarlet parses the XML response.
## 2. Usage
#### a. Options
```
Just a simple script, that auto-generates OpenVAS pdf reports by getting as input a list of task names and a list of hosts.
Usage: ./ovrep.sh <[-T <task|list_of_tasks> | -F <file>]> 
OPTIONS:
	-T <task1,task2,...>	Specify the name of the task or the UUID. Multiple tasks should be separated by comma
	-F <filepath>		Specify a list containing the names or UUID of tasks. Should be separated by an endline
	-A			Specifies that one report should be generated for all the hosts.
	-H <filepath>		Specifies a file containing the list of hosts.
	-O <directory_path>	Specifies a filepath for the directory in which to save the reports.
```
#### b. The list of hosts
It expects to find in the current directory a list of hosts with the same name as the task and with the `.list` extension. For example for task `Example-Task` it expects to find in the current directory `Example-Task.list` which contains the hosts for which the reports should be generated, in the following format:
```
123.123.123.123
host.example.com
222.222.222.222
```
**Tip**: Even if you give it the task UUID instead of the task name, it still expects the list of hosts as the name of the task, not the UUID.
`<task-name>.list`
## 3. Future improvements
- add an option to specify the output format
- add an option to specify other flags
- add an option to specify the list of hosts on command line
