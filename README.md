# Stockpile
Tool to gather information from systems using Ansible.

# How to add to the Stockpile?
Stockpile uses Red Hat Ansible to collect system information. To add to the Stockpile, the user must create a new Anbile role that defines what they are looking to capture.

## How do I add to the existing Ansible roles?
Let's say for example you wanted to capture all the interface drivers on the SUT -- not an useful since this fact already exists. However, for the sake of the example, bare with me.

In order to create a new set of information to stockpile, create the Ansible role directory, *stockpile/roles/example*

For this work, we just need to create the tasks, so in *stockpile/roles/example/tasks/main.yaml*

### Scenario 1: You want to capture all the interface details. So, you might consider the below.

```ansible
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
    example: "{{__dict|from_yaml}}"

```

Once Stockpile completes, it will create * *metadata/machine_facts.json* *

Example output of the above Example role:
```json
    "example": {
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

For this work, we just need to create the tasks, so in *stockpile/roles/example2/tasks/main.yaml*

```ansible
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
    example2:
      - crontab_shell : "{{ crontab_shell.stdout }}"
      - crontab_mailto: "{{ crontab_mailto.stdout }}"

```

Example output

```json
    "example2": [
        {
            "crontab_shell": "/bin/bash"
        },
        {
            "crontab_mailto": "root"
        }
    ]

```


We are not worried about the structure this currently creates. That is for Scribe to break down.

