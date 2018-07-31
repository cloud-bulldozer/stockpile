# Stockpile
Tool to gather information from systems using Ansible.

# How to add to the Stockpile?
Stockpile uses Red Hat Ansible to collect system information. To add to the Stockpile, the user must create a new Anbile role that defines what they are looking to capture.

## How do I add to the existing Ansible roles?
Let's say for example you wanted to capture all the interface drivers on the SUT -- not an useful since this fact already exists. However, for the sake of the example, bare with me.

In order to create a new set of information to stockpile, create the Ansible role directory, *stockpile/roles/example*

For this work, we just need to create the tasks, so in *stockpile/roles/example/tasks/main.yaml*

```ansible
---

- name: "my example name"
  shell: "ethtool -i {{item}} | grep driver | awk -F: '{print $2}'"
  with_items: "{{ ansible_interfaces }}"
  register: interface_drivers

- name: "Store example data"
  set_fact:
    "interface" : "{{ item.item }}"
    "driver" : "{{ item.stdout }}"
  with_items: "{{ interface_drivers.results }}"
```

Once Stockpile completes, it will create * *metadata/machine_facts.json* *

Example output of the above Example role:
```json
{
    "interface_drivers": {
        "changed": true,
            "msg": "All items completed",
            "results": [
            {
                "_ansible_ignore_errors": null,
                "_ansible_item_result": true,
                "_ansible_no_log": false,
                "_ansible_parsed": true,
                "changed": true,
                "cmd": "ethtool -i docker0 | grep driver | awk -F: '{print $2}'",
                "delta": "0:00:00.006694",
                "end": "2018-07-27 15:26:56.870726",
                "failed": false,
                "invocation": {
                    "module_args": {
                        "_raw_params": "ethtool -i docker0 | grep driver | awk -F: '{print $2}'",
                        "_uses_shell": true,
                        "chdir": null,
                        "creates": null,
                        "executable": null,
                        "removes": null,
                        "stdin": null,
                        "warn": true
                    }
                },
                "item": "docker0",
                "rc": 0,
                "start": "2018-07-27 15:26:56.864032",
                "stderr": "",
                "stderr_lines": [],
                "stdout": " bridge",
                "stdout_lines": [
                    " bridge"
                ]
            }
    }
}
```

We are not worried about the structure this currently creates. That is for Scribe to break down.

