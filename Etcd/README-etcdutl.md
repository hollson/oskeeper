etcdutl
========

`etcdutl` is a command line administration utility for [etcd][etcd].

It's designed to operate directly on etcd data files.
For operations over a network, please use `etcdctl`.

### DEFRAG [options]

DEFRAG directly defragments an etcd data directory while etcd is not running. 
When an etcd member reclaims storage space from deleted and compacted keys, the space is kept in a free list and the database file remains the same size. By defragmenting the database, the etcd member releases this free space back to the file system.

In order to defrag a live etcd instances over the network, please use `etcdctl defrag` instead.

#### Options

- data-dir -- Optional. If present, defragments a data directory not in use by etcd.

#### Output

Exit status '0' when the process was successful.

#### Example

To defragment a data directory directly, use the `--data-dir` flag:

``` bash
# Defragment while etcd is not running
./etcdutl defrag --data-dir default.etcd
# success (exit status 0)
# Error: cannot open database at default.etcd/member/snap/db
```

#### Remarks

DEFRAG returns a zero exit code only if it succeeded in defragmenting all given endpoints.


### SNAPSHOT RESTORE [options] \<filename\>

SNAPSHOT RESTORE creates an etcd data directory for an etcd cluster member from a backend database snapshot and a new cluster configuration. Restoring the snapshot into each member for a new cluster configuration will initialize a new etcd cluster preloaded by the snapshot data.

#### Options

The snapshot restore options closely resemble to those used in the `etcd` command for defining a cluster.

- data-dir -- Path to the data directory. Uses \<name\>.etcd if none given.

- wal-dir -- Path to the WAL directory. Uses data directory if none given.

- initial-cluster -- The initial cluster configuration for the restored etcd cluster.

- initial-cluster-token -- Initial cluster token for the restored etcd cluster.

- initial-advertise-peer-urls -- List of peer URLs for the member being restored.

- name -- Human-readable name for the etcd cluster member being restored.

- skip-hash-check -- Ignore snapshot integrity hash value (required if copied from data directory)

#### Output

A new etcd data directory initialized with the snapshot.

#### Example

Save a snapshot, restore into a new 3 node cluster, and start the cluster:
```
./etcdutl snapshot save snapshot.db

# restore members
bin/etcdutl snapshot restore snapshot.db --initial-cluster-token etcd-cluster-1 --initial-advertise-peer-urls http://127.0.0.1:12380  --name sshot1 --initial-cluster 'sshot1=http://127.0.0.1:12380,sshot2=http://127.0.0.1:22380,sshot3=http://127.0.0.1:32380'
bin/etcdutl snapshot restore snapshot.db --initial-cluster-token etcd-cluster-1 --initial-advertise-peer-urls http://127.0.0.1:22380  --name sshot2 --initial-cluster 'sshot1=http://127.0.0.1:12380,sshot2=http://127.0.0.1:22380,sshot3=http://127.0.0.1:32380'
bin/etcdutl snapshot restore snapshot.db --initial-cluster-token etcd-cluster-1 --initial-advertise-peer-urls http://127.0.0.1:32380  --name sshot3 --initial-cluster 'sshot1=http://127.0.0.1:12380,sshot2=http://127.0.0.1:22380,sshot3=http://127.0.0.1:32380'

# launch members
bin/etcd --name sshot1 --listen-client-urls http://127.0.0.1:2379 --advertise-client-urls http://127.0.0.1:2379 --listen-peer-urls http://127.0.0.1:12380 &
bin/etcd --name sshot2 --listen-client-urls http://127.0.0.1:22379 --advertise-client-urls http://127.0.0.1:22379 --listen-peer-urls http://127.0.0.1:22380 &
bin/etcd --name sshot3 --listen-client-urls http://127.0.0.1:32379 --advertise-client-urls http://127.0.0.1:32379 --listen-peer-urls http://127.0.0.1:32380 &
```

### SNAPSHOT STATUS \<filename\>

SNAPSHOT STATUS lists information about a given backend database snapshot file.

#### Output

##### Simple format

Prints a humanized table of the database hash, revision, total keys, and size.

##### JSON format

Prints a line of JSON encoding the database hash, revision, total keys, and size.

#### Examples
```bash
./etcdutl snapshot status file.db
# cf1550fb, 3, 3, 25 kB
```

```bash
./etcdutl --write-out=json snapshot status file.db
# {"hash":3474280699,"revision":3,"totalKey":3,"totalSize":24576}
```

```bash
./etcdutl --write-out=table snapshot status file.db
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| cf1550fb |        3 |          3 | 25 kB      |
+----------+----------+------------+------------+
```



### VERSION

```bash
./etcdutl version
# etcdutl version: 3.5.0
# API version: 3.1
```


