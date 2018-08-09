#!/usr/bin/env python

import yaml
import sys
import os
import json
import argparse

ocp_node_configmap_path = "/tmp/node-config.yaml"
ocp_webconsole_configmap_path = "/tmp/webconsole-config.yaml"
ocp_cluster_info_configmap_path = "/tmp/id"
ocp_config_dir = "/tmp"

def scrape_configmap(cfg_type, namespace, configmap_path):
    cmd = "oc extract configmap/%s -n %s --confirm --to=%s &>/dev/null" %(cfg_type,namespace,ocp_config_dir)
    os.system(cmd)
    with open(configmap_path, "r") as configmap:
        try:
            config = yaml.load(configmap)
        except yaml.YAMLError as e:
            print ("Error in the configmap file:%s" %(e))
        try:
            print (json.dumps(config, indent=4))
        except ValueError as err:
            print ("Error while converting to json: %s" %(err))

def main(cfg_type):
    if cfg_type == "node-config-compute":
       namespace = "openshift-node"
       scrape_configmap(cfg_type, namespace, ocp_node_configmap_path)
    elif cfg_type == "webconsole-config":
       namespace = "openshift-web-console"
       scrape_configmap(cfg_type, namespace, ocp_webconsole_configmap_path)
    elif cfg_type == "node-config-master":
       namespace = "openshift-node"
       scrape_configmap(cfg_type, namespace, ocp_node_configmap_path)
    elif cfg_type == "node-config-infra":
       namespace = "openshift-node"
       scrape_configmap(cfg_type, namespace, ocp_node_configmap_path)
    elif cfg_type == "cluster-info":
       namespace = "kube-service-catalog"
       scrape_configmap(cfg_type, namespace, ocp_cluster_info_configmap_path)
    else:
       print ("%s is not a valid config type, please check" %(cfg_type))
       sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("config_type", help="config_type can be one of the follwing: node-config-compute, node-config-master, node-config-infra, webconsole-config, cluster-info")
    args = parser.parse_args()
    status = main(args.config_type)
    sys.exit(status)
