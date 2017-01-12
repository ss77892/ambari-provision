## Expectations:

* Ambari server is installed on the first node.
* 3-Node HBase configuration provided.
* Hostnames in the cluster.json file need to be updated.

## Usage:

`./provision-gateway.sh ~/.ssh/my_key <ambari-server>`
`./provision-nodes.sh ~/.ssh/my_key <ambari-server> [<node> <node> ...]`
`./load-blueprint.sh ~/.ssh/my_key <blueprint-name> <ambari-server>`

The 2nd argument (e.g. "blueprint-name") is the name of a directory which contains a blueprint.json
and cluster.json file. The directory is expected to be co-located with the provision-nodes.sh script.
Be sure that the specified cluster.json file contains the correct hostnames for your system.

## New cluster creation:

1. Install an Ambari cluster to your liking
2. Run `curl -H "X-Requested-By: ambari" -X GET -u admin:admin "http://YOUR_AMBARI_SERVER:8080/api/v1/clusters/YOUR_CLUSTER_NAME?format=blueprint" > blueprint.json
3. Build your own cluster.json file based on one of the examples in the other. Make sure the host_groups in your blueprint.json match what you define in the cluster.json

## Oh no, I goofed my installation!

One downside including the cluster.json in revision control is that you (often) will not be deploying the same blueprint to
nodes with the same hostname. Up until recently, I didn't know of a way to recover from this as Ambari would be left in this
seriously broken state trying to install to nodes it didn't know about. Thankfully, I found there are some steps around this

* `ambari-server stop`
* `ambari-server reset` (entering "y" or "yes" where necessary)
* `ambari-server start`
* Re-run `provision-nodes.sh`

If it wasn't entirely clear yet, this will wipe the Ambari database. Don't do this if you care about that database.

## TODO:

* Create HDFS dir for test user
* Make sure test user can password-less SSH (authorized_keys)
* Disable requiretty for test user in /etc/sudoers
* install yum-utils
