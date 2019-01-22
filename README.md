# Stockpile
Tool to gather information from systems using Ansible.

# Contributing

    Please visit http://gerrithub.io/ and Sign In with your github account.
    Make sure to import your ssh keys.

    Now, clone the github repository

    ::

        $ git clone https://github.com/redhat-performance/stockpile.git

    Make sure, you've git-review installed, following should work.


    ::

        $ sudo pip install git-review


    To set up your cloned repository to work with Gerrit

    ::

        $ git review -s

    It's suggested to create a branch to do your work,
    name it something related to the change you'd like to introduce.

    ::

        $ git branch my_special_enhancement
        $ git checkout !$

    Make your changes and then commit them using the instructions
    below.

    ::

        $ git add /path/to/files/changed
        $ git commit -m "your commit title"

    Use a descriptive commit title followed by an empty space.
    You should type a small justification of what you are
    changing and why.

    Please try to run linters before you submit for review, as this would
    enable reviewers to focus mainly on logic and not syntax.
    ::

        $ tox .

    Now you're ready to submit your changes for review:

    ::

        $ git review


    If you want to make another patchset from the same commit you can
    use the amend feature after further modification and saving.

    ::

        $ git add /path/to/files/changed
        $ git commit --amend
        $ git review

    If you want to submit a new patchset from a different location
    (perhaps on a different machine or computer for example) you can
    clone the repo again (if it doesn't already exist) and then
    use git review against your unique Change-ID:

    ::

        $ git review -d Change-Id

    Change-Id is the change id number as seen in Gerrit and will be
    generated after your first successful submission. So, in case of
    https://review.gerrithub.io/#/c/redhat-performance/scribe/+/425014/

    You can either do git review -d 425014 as it's the number

    or you can do git review -d If0b7b4f30615e46f009759b32a3fc533e811ebdc
    where If0b7b4f30615e46f009759b32a3fc533e811ebdc is the change-id present

    Make the changes on the branch that was setup by using the git review -d
    (the name of the branch is along the lines of
    review/username/branch_name/patchsetnumber).

    Add the files to git and commit your changes using,

    ::

        $ git commit --amend

    You can edit your commit message as well in the prompt shown upon
    executing above command.

    Finally, push the patch for review using,

    ::

        $ git review


# How to add to the Stockpile?
Stockpile uses Red Hat Ansible to collect system information. To add to the Stockpile, the user must create a new Anbile role that defines what they are looking to capture.

## How do I add to the existing Ansible roles?
Let's say for example you wanted to capture all the interface drivers on the SUT -- not particularly useful since this fact already exists. However, for the sake of the example, bear with me.

In order to create a new set of information to stockpile, create the Ansible role directory, *roles/example*

For this work, we just need to create the tasks, so in *roles/example/tasks/main.yml* add the relevant tasks.

## Norms to follow while adding roles

Please make sure that you follow the below mentioned norms:

1. Never use set_fact more than once in your role(per playbook).
2. Use register to set your vars and not set_fact.
3. Use set_fact at the end to build the dictionary according to the required hierarchy.
4. Prefix the dictionary with "stockpile_".
5. Don't try to build the dictionary using the vars directly, lets say if you
run a shell command to set var1, while building dictionary use var1.stdout
6. Make sure to add conditions in the roles in order to ensure that the data
is collected only if the intended component is installed.

Please look at the example below:

```yaml

- name: run the shell command
  shell: whoami
  register: var1
## Rest of the role where you collect info and use register to set vars

- name: set the collected info as facts
  set_fact:
    stockpile_role_hierarchy:
      var_1: "{{ var1.stdout }}"
  when: ( role_installed.rc == 0 )

```

For the role hierarchy, a good example would be to look at openshift roles:
Please read below on how 'hierarchy' should be named:

Following is how the role *openshift-cluster-topology* collects facts:

```yaml
- name: set the collected info as facts
  set_fact:
    stockpile_openshift_cluster_topology:
      running_pods_count: "{{ ocp_running_pods.stdout | from_json | json_query('items[].status.phase') | length }}"
      compute_count: "{{ ocp_compute_count.stdout }}"
      master_count: "{{ ocp_master_count.stdout }}"
      etcd_count: "{{ ocp_master_count.stdout }}"
      cluster_network_plugin: "{{ ocp_network_plugin.stdout | from_json | json_query('items[].pluginName') }}"
      client_version: "{{ oc_client_version.stdout }}"
      server_version: "{{ oc_server_version.stdout }}"
      user: "{{ ocp_user.stdout }}"
    when: ( oc_installed.rc == 0 and kubeconfig.stat.exists == True )
```

By naming the var stockpile_openshift_cluster_topology, the variable is self
explanatory about what it's collecting. Also if there's a new role that needs to be added
later for cluster performance, it's var can be named stockpile_openshift_cluster_perf

A bad example would be naming var as stockpile_openshift_cluster unless you're confident that
everything related to openshift_cluster will be collected as part of the role openshift_cluster.


### Scenario 1: You want to capture all the interface details. So, you might consider the below.

```yaml
---

# Capture the data you are interested in
- name: "my example name"
  shell: "ethtool -i {{item}} | grep driver | awk -F: '{print $2}'"
  with_items: "{{ ansible_interfaces }}"
  register: interface_drivers

# Easy way to create a YAML that we will translate into a dict

- set_fact:
    __dict: |
        {% for item in  interface_drivers.results %}
        {{item.item}}: "{{item.stdout}}"
        {% endfor %}

# Store the data using the role_name as the key.

- name: "Store example data"
  set_fact:
    stockpile_example: "{{__dict|from_yaml}}"

```

Once Stockpile completes, it will create * *metadata/machine_facts.json* *

Example output of the above Example role:
```json
    "stockpile_example": {
        "docker0": " bridge",
        "enp6s0": " sky2",
        "enp7s0": " sky2",
        "lo": "",
        "tun0": " tun",
        "veth2d88dbd": " veth",
        "virbr0": " bridge",
        "virbr0-nic": " tun"
    }
```

### Scenario 2: You want to capture details about a configuration file:

For this work, we just need to create the tasks, so in *roles/example2/tasks/main.yaml*

```yaml
---

# Capture the data you are interested in
- name: "crontab shell"
  shell: "cat /etc/crontab | grep SHELL | awk -F = '{print $2}'"
  register: crontab_shell

- name: "crontab mailto"
  shell: "cat /etc/crontab | grep MAILTO | awk -F = '{print $2}'"
  register: crontab_mailto

- name: "Store the crontab config"
  set_fact:
    stockpile_example2:
      - crontab_shell : "{{ crontab_shell.stdout }}"
      - crontab_mailto: "{{ crontab_mailto.stdout }}"

```

Example output

```json
    "stockpile_example2": [
        {
            "crontab_shell": "/bin/bash"
        },
        {
            "crontab_mailto": "root"
        }
    ]

```


We are not worried about the structure this currently creates. That is for Scribe to break down.


### Importing stockpile roles to ansible galaxy

The roles can be imported to Ansible Galaxy using the script like:
```
$ ./import_roles.sh <github_token> <github_user> <github_repo> [galaxy_server_url]
```
The galaxy_server_url is set to https://galaxy.ansible.com by default if not defined by the user.


The stockpile roles can be pulled/installed from Ansible Galaxy using:
```
$ mazer -s https://galaxy.ansible.com --roles-path=<roles_path> install <github_user> <github_repo>
```
If roles_path is not defined, then the roles will be installed under the default ANSIBLE_ROLES_PATH
which is /etc/ansible/roles or the path specified in the ansible.cfg.
