全局环境变量

```shell
ETCDCTL_DIAL_TIMEOUT=3s
ETCDCTL_CACERT=/tmp/ca.pem
ETCDCTL_CERT=/tmp/cert.pem
ETCDCTL_KEY=/tmp/key.pem
```

# 键值命令

## PUT

格式:  `PUT [options] <key> <value>` 

- lease -- 附加到密钥的租约 ID（十六进制）。 

- prev-kv -- 返回修改之前的键值对。 

- ignore-value -- 忽略值(即仅用于更新租约)

- ignore-lease -- 使用当前租约更新密钥。 

```bash
etcdctl put foo bar --lease=694d8cbb10ce9b27
etcdctl get foo
etcdctl put foo --ignore-value # to detache lease
```

```bash
etcdctl put foo bar --lease=1234abcd
etcdctl put foo bar1 --ignore-lease # to use existing lease 1234abcd
etcdctl get foo
```

```bash
etcdctl put foo bar1 --prev-kv
# OK
# foo
# bar
etcdctl get foo
# foo
# bar1
```



## GET

> `GET [options] <key> [range_end]`

- hex -- 将键和值打印为十六进制编码字符串 
- limit -- 最大结果数 
- prefix -- 通过匹配前缀获取键 
- order——结果的顺序；  上升或下降 
- sort-by -- 排序目标；  创建、键入、修改、赋值或版本 
- rev -- 指定 kv 修订版 
- print-value-only -- 与 write-out=simple 一起使用时仅打印值 
- consistency ——Linear 可化（l）或可序列化（s），默认为可线性化（l）。 
- from-key -- 使用字节比较获取大于或等于给定键的键 
- key-only -- 只获取键 

```bash
etcdctl put foo bar
# OK
etcdctl put foo1 bar1
# OK
etcdctl put foo2 bar2
# OK
etcdctl put foo3 bar3
# OK
```

Get the key named `foo`:

```bash
etcdctl get foo
# foo
# bar
```

Get all keys:

```bash
etcdctl get --from-key ''
# foo
# bar
# foo1
# bar1
# foo2
# foo2
# foo3
# bar3
```

Get all keys with names greater than or equal to `foo1`:

```bash
etcdctl get --from-key foo1
# foo1
# bar1
# foo2
# bar2
# foo3
# bar3
```

Get keys with names greater than or equal to `foo1` and less than `foo3`:

```bash
etcdctl get foo1 foo3
# foo1
# bar1
# foo2
# bar2
```



## DEL

> 根据键或范围删除元素
>
> DEL [options] \<key\> [range_end]

- prefix -- 通过匹配前缀删除键 
- prev-kv -- 返回删除的键值对 
- from-key -- 使用字节比较删除大于或等于给定键的键 

```bash
etcdctl put foo bar
# OK
etcdctl del foo
# 1
etcdctl get foo
```

```bash
etcdctl put key val
# OK
etcdctl del --prev-kv key
# 1
# key
# val
etcdctl get key
```

```bash
etcdctl put a 123
etcdctl put b 456
etcdctl put f fff
etcdctl put j JJJ
etcdctl put z 789
etcdctl del --from-key c k 
etcdctl get --from-key a
```

```bash
etcdctl put zoo val
# OK
etcdctl put zoo1 val1
# OK
etcdctl put zoo2 val2
# OK
etcdctl del --prefix zoo
# 3
etcdctl get zoo2
```

## TXN

TXN [options]

TXN reads multiple etcd requests from standard input and applies them as a single atomic transaction.
A transaction consists of list of conditions, a list of requests to apply if all the conditions are true, and a list of requests to apply if any condition is false.

RPC: Txn

### Options

- hex -- print out keys and values as hex encoded strings.

- interactive -- input transaction with interactive prompting.

### Input Format
```ebnf
<Txn> ::= <CMP>* "\n" <THEN> "\n" <ELSE> "\n"
<CMP> ::= (<CMPCREATE>|<CMPMOD>|<CMPVAL>|<CMPVER>|<CMPLEASE>) "\n"
<CMPOP> ::= "<" | "=" | ">"
<CMPCREATE> := ("c"|"create")"("<KEY>")" <CMPOP> <REVISION>
<CMPMOD> ::= ("m"|"mod")"("<KEY>")" <CMPOP> <REVISION>
<CMPVAL> ::= ("val"|"value")"("<KEY>")" <CMPOP> <VALUE>
<CMPVER> ::= ("ver"|"version")"("<KEY>")" <CMPOP> <VERSION>
<CMPLEASE> ::= "lease("<KEY>")" <CMPOP> <LEASE>
<THEN> ::= <OP>*
<ELSE> ::= <OP>*
<OP> ::= ((see put, get, del etcdctl command syntax)) "\n"
<KEY> ::= (%q formatted string)
<VALUE> ::= (%q formatted string)
<REVISION> ::= "\""[0-9]+"\""
<VERSION> ::= "\""[0-9]+"\""
<LEASE> ::= "\""[0-9]+\""
```

### Output

`SUCCESS` if etcd processed the transaction success list, `FAILURE` if etcd processed the transaction failure list. Prints the output for each command in the executed request list, each separated by a blank line.

### Examples

txn in interactive mode:
```bash
etcdctl txn -i
# compares:
mod("key1") > "0"

# success requests (get, put, delete):
put key1 "overwrote-key1"

# failure requests (get, put, delete):
put key1 "created-key1"
put key2 "some extra key"

# FAILURE

# OK

# OK
```

txn in non-interactive mode:
```bash
etcdctl txn <<<'mod("key1") > "0"

put key1 "overwrote-key1"

put key1 "created-key1"
put key2 "some extra key"

'

# FAILURE

# OK

# OK
```

### Remarks

When using multi-line values within a TXN command, newlines must be represented as `\n`. Literal newlines will cause parsing failures. This differs from other commands (such as PUT) where the shell will convert literal newlines for us. For example:

```bash
etcdctl txn <<<'mod("key1") > "0"

put key1 "overwrote-key1"

put key1 "created-key1"
put key2 "this is\na multi-line\nvalue"

'

# FAILURE

# OK

# OK
```

## COMPACTION

COMPACTION 会丢弃给定修订之前的所有 etcd 事件历史记录。  由于etcd使用多版本并发控制 模型，它将所有关键更新保留为事件历史记录。  当不再需要某些修订的事件历史记录时， 所有被取代的键都可以被压缩以回收 etcd 后端数据库中的存储空间。 

> COMPACTION [options] \<revision>

### Options

- physical -- 'true' to wait for compaction to physically remove all old revisions

### Output

Prints the compacted revision.

### Example

```bash
etcdctl compaction 1234
# compacted revision 1234
```

## WATCH
- hex -- print out key and value as hex encode string

- interactive -- begins an interactive watch session

- prefix -- watch on a prefix if prefix is set.

- prev-kv -- get the previous key-value pair before the event happens.

- rev -- the revision to start watching. Specifying a revision is useful for observing past events.

```
watch [options] <key or prefix>\n
```

#### Non-interactive

```bash
etcdctl watch foo
# PUT
# foo
# bar
```

```bash
ETCDCTL_WATCH_KEY=foo etcdctl watch
# PUT
# foo
# bar
```

Receive events and execute `echo watch event received`:

```bash
etcdctl watch foo -- echo watch event received
# PUT
# foo
# bar
# watch event received
```

Watch response is set via `ETCD_WATCH_*` environmental variables:

```bash
etcdctl watch foo -- sh -c "env | grep ETCD_WATCH_"

# PUT
# foo
# bar
# ETCD_WATCH_REVISION=11
# ETCD_WATCH_KEY="foo"
# ETCD_WATCH_EVENT_TYPE="PUT"
# ETCD_WATCH_VALUE="bar"
```

Watch with environmental variables and execute `echo watch event received`:

```bash
export ETCDCTL_WATCH_KEY=foo
etcdctl watch -- echo watch event received
# PUT
# foo
# bar
# watch event received
```

```bash
export ETCDCTL_WATCH_KEY=foo
export ETCDCTL_WATCH_RANGE_END=foox
etcdctl watch -- echo watch event received
# PUT
# fob
# bar
# watch event received
```

#### Interactive

```bash
etcdctl watch -i
watch foo
watch foo
# PUT
# foo
# bar
# PUT
# foo
# bar
```

Receive events and execute `echo watch event received`:

```bash
etcdctl watch -i
watch foo -- echo watch event received
# PUT
# foo
# bar
# watch event received
```

Watch with environmental variables and execute `echo watch event received`:

```bash
export ETCDCTL_WATCH_KEY=foo
etcdctl watch -i
watch -- echo watch event received
# PUT
# foo
# bar
# watch event received
```

```bash
export ETCDCTL_WATCH_KEY=foo
export ETCDCTL_WATCH_RANGE_END=foox
etcdctl watch -i
watch -- echo watch event received
# PUT
# fob
# bar
# watch event received
```



# 租约管理

LEASE提供密钥租约管理命令。

## LEASE GRANT \<ttl\>

LEASE GRANT creates a fresh lease with a server-selected time-to-live in seconds
greater than or equal to the requested TTL value.

RPC: LeaseGrant

### Output

Prints a message with the granted lease ID.

### Example

```bash
etcdctl lease grant 60
# lease 32695410dcc0ca06 granted with TTL(60s)
```

## LEASE REVOKE \<leaseID\>

LEASE REVOKE destroys a given lease, deleting all attached keys.

RPC: LeaseRevoke

### Output

Prints a message indicating the lease is revoked.

### Example

```bash
etcdctl lease revoke 32695410dcc0ca06
# lease 32695410dcc0ca06 revoked
```

## LEASE TIMETOLIVE \<leaseID\> [options]

LEASE TIMETOLIVE retrieves the lease information with the given lease ID.

RPC: LeaseTimeToLive

### Options

- keys -- Get keys attached to this lease

### Output

Prints lease information.

### Example

```bash
etcdctl lease grant 500
# lease 2d8257079fa1bc0c granted with TTL(500s)

etcdctl put foo1 bar --lease=2d8257079fa1bc0c
# OK

etcdctl put foo2 bar --lease=2d8257079fa1bc0c
# OK

etcdctl lease timetolive 2d8257079fa1bc0c
# lease 2d8257079fa1bc0c granted with TTL(500s), remaining(481s)

etcdctl lease timetolive 2d8257079fa1bc0c --keys
# lease 2d8257079fa1bc0c granted with TTL(500s), remaining(472s), attached keys([foo2 foo1])

etcdctl lease timetolive 2d8257079fa1bc0c --write-out=json
# {"cluster_id":17186838941855831277,"member_id":4845372305070271874,"revision":3,"raft_term":2,"id":3279279168933706764,"ttl":465,"granted-ttl":500,"keys":null}

etcdctl lease timetolive 2d8257079fa1bc0c --write-out=json --keys
# {"cluster_id":17186838941855831277,"member_id":4845372305070271874,"revision":3,"raft_term":2,"id":3279279168933706764,"ttl":459,"granted-ttl":500,"keys":["Zm9vMQ==","Zm9vMg=="]}

etcdctl lease timetolive 2d8257079fa1bc0c
# lease 2d8257079fa1bc0c already expired
```

## LEASE LIST

LEASE LIST lists all active leases.

RPC: LeaseLeases

### Output

Prints a message with a list of active leases.

### Example

```bash
etcdctl lease grant 60
# lease 32695410dcc0ca06 granted with TTL(60s)

etcdctl lease list
32695410dcc0ca06
```

## LEASE KEEP-ALIVE \<leaseID\>

LEASE KEEP-ALIVE periodically refreshes a lease so it does not expire.

RPC: LeaseKeepAlive

### Output

Prints a message for every keep alive sent or prints a message indicating the lease is gone.

### Example
```bash
etcdctl lease keep-alive 32695410dcc0ca0
# lease 32695410dcc0ca0 keepalived with TTL(100)
# lease 32695410dcc0ca0 keepalived with TTL(100)
# lease 32695410dcc0ca0 keepalived with TTL(100)
...
```



# 集群命令

## MEMBER \<subcommand\>

MEMBER provides commands for managing etcd cluster membership.

## MEMBER ADD \<memberName\> [options]

MEMBER ADD introduces a new member into the etcd cluster as a new peer.

RPC: MemberAdd

### Options

- peer-urls -- comma separated list of URLs to associate with the new member.

### Output

Prints the member ID of the new member and the cluster ID.

### Example

```bash
etcdctl member add newMember --peer-urls=https://127.0.0.1:12345

Member ced000fda4d05edf added to cluster 8c4281cc65c7b112

ETCD_NAME="newMember"
ETCD_INITIAL_CLUSTER="newMember=https://127.0.0.1:12345,default=http://10.0.0.30:2380"
ETCD_INITIAL_CLUSTER_STATE="existing"
```

## MEMBER UPDATE \<memberID\> [options]

MEMBER UPDATE sets the peer URLs for an existing member in the etcd cluster.

RPC: MemberUpdate

### Options

- peer-urls -- comma separated list of URLs to associate with the updated member.

### Output

Prints the member ID of the updated member and the cluster ID.

### Example

```bash
etcdctl member update 2be1eb8f84b7f63e --peer-urls=https://127.0.0.1:11112
# Member 2be1eb8f84b7f63e updated in cluster ef37ad9dc622a7c4
```

## MEMBER REMOVE \<memberID\>

MEMBER REMOVE removes a member of an etcd cluster from participating in cluster consensus.

RPC: MemberRemove

### Output

Prints the member ID of the removed member and the cluster ID.

### Example

```bash
etcdctl member remove 2be1eb8f84b7f63e
# Member 2be1eb8f84b7f63e removed from cluster ef37ad9dc622a7c4
```

## MEMBER LIST

MEMBER LIST prints the member details for all members associated with an etcd cluster.

RPC: MemberList

### Output

Prints a humanized table of the member IDs, statuses, names, peer addresses, and client addresses.

### Examples

```bash
etcdctl member list
# 8211f1d0f64f3269, started, infra1, http://127.0.0.1:12380, http://127.0.0.1:2379
# 91bc3c398fb3c146, started, infra2, http://127.0.0.1:22380, http://127.0.0.1:22379
# fd422379fda50e48, started, infra3, http://127.0.0.1:32380, http://127.0.0.1:32379
```

```bash
etcdctl -w json member list
# {"header":{"cluster_id":17237436991929493444,"member_id":9372538179322589801,"raft_term":2},"members":[{"ID":9372538179322589801,"name":"infra1","peerURLs":["http://127.0.0.1:12380"],"clientURLs":["http://127.0.0.1:2379"]},{"ID":10501334649042878790,"name":"infra2","peerURLs":["http://127.0.0.1:22380"],"clientURLs":["http://127.0.0.1:22379"]},{"ID":18249187646912138824,"name":"infra3","peerURLs":["http://127.0.0.1:32380"],"clientURLs":["http://127.0.0.1:32379"]}]}
```

```bash
etcdctl -w table member list
+------------------+---------+--------+------------------------+------------------------+
|        ID        | STATUS  |  NAME  |       PEER ADDRS       |      CLIENT ADDRS      |
+------------------+---------+--------+------------------------+------------------------+
| 8211f1d0f64f3269 | started | infra1 | http://127.0.0.1:12380 | http://127.0.0.1:2379  |
| 91bc3c398fb3c146 | started | infra2 | http://127.0.0.1:22380 | http://127.0.0.1:22379 |
| fd422379fda50e48 | started | infra3 | http://127.0.0.1:32380 | http://127.0.0.1:32379 |
+------------------+---------+--------+------------------------+------------------------+
```

## ENDPOINT \<subcommand\>

ENDPOINT provides commands for querying individual endpoints.

### Options

- cluster -- fetch and use all endpoints from the etcd cluster member list

## ENDPOINT HEALTH

ENDPOINT HEALTH checks the health of the list of endpoints with respect to cluster. An endpoint is unhealthy
when it cannot participate in consensus with the rest of the cluster.

### Output

If an endpoint can participate in consensus, prints a message indicating the endpoint is healthy. If an endpoint fails to participate in consensus, prints a message indicating the endpoint is unhealthy.

### Example

Check the default endpoint's health:

```bash
etcdctl endpoint health
# 127.0.0.1:2379 is healthy: successfully committed proposal: took = 2.095242ms
```

Check all endpoints for the cluster associated with the default endpoint:

```bash
etcdctl endpoint --cluster health
# http://127.0.0.1:2379 is healthy: successfully committed proposal: took = 1.060091ms
# http://127.0.0.1:22379 is healthy: successfully committed proposal: took = 903.138µs
# http://127.0.0.1:32379 is healthy: successfully committed proposal: took = 1.113848ms
```

## ENDPOINT STATUS

ENDPOINT STATUS queries the status of each endpoint in the given endpoint list.

### Output

#### Simple format

Prints a humanized table of each endpoint URL, ID, version, database size, leadership status, raft term, and raft status.

#### JSON format

Prints a line of JSON encoding each endpoint URL, ID, version, database size, leadership status, raft term, and raft status.

### Examples

Get the status for the default endpoint:

```bash
etcdctl endpoint status
# 127.0.0.1:2379, 8211f1d0f64f3269, 3.0.0, 25 kB, false, 2, 63
```

Get the status for the default endpoint as JSON:

```bash
etcdctl -w json endpoint status
# [{"Endpoint":"127.0.0.1:2379","Status":{"header":{"cluster_id":17237436991929493444,"member_id":9372538179322589801,"revision":2,"raft_term":2},"version":"3.0.0","dbSize":24576,"leader":18249187646912138824,"raftIndex":32623,"raftTerm":2}}]
```

Get the status for all endpoints in the cluster associated with the default endpoint:

```bash
etcdctl -w table endpoint --cluster status
+------------------------+------------------+----------------+---------+-----------+-----------+------------+
|        ENDPOINT        |        ID        |    VERSION     | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
+------------------------+------------------+----------------+---------+-----------+-----------+------------+
| http://127.0.0.1:2379  | 8211f1d0f64f3269 | 3.2.0-rc.1+git |   25 kB |     false |         2 |          8 |
| http://127.0.0.1:22379 | 91bc3c398fb3c146 | 3.2.0-rc.1+git |   25 kB |     false |         2 |          8 |
| http://127.0.0.1:32379 | fd422379fda50e48 | 3.2.0-rc.1+git |   25 kB |      true |         2 |          8 |
+------------------------+------------------+----------------+---------+-----------+-----------+------------+
```

## ENDPOINT HASHKV

ENDPOINT HASHKV fetches the hash of the key-value store of an endpoint.

### Output

#### Simple format

Prints a humanized table of each endpoint URL and KV history hash.

#### JSON format

Prints a line of JSON encoding each endpoint URL and KV history hash.

### Examples

Get the hash for the default endpoint:

```bash
etcdctl endpoint hashkv
# 127.0.0.1:2379, 1084519789
```

Get the status for the default endpoint as JSON:

```bash
etcdctl -w json endpoint hashkv
# [{"Endpoint":"127.0.0.1:2379","Hash":{"header":{"cluster_id":14841639068965178418,"member_id":10276657743932975437,"revision":1,"raft_term":3},"hash":1084519789,"compact_revision":-1}}]
```

Get the status for all endpoints in the cluster associated with the default endpoint:

```bash
etcdctl -w table endpoint --cluster hashkv
+------------------------+------------+
|        ENDPOINT        |    HASH    |
+------------------------+------------+
| http://127.0.0.1:2379  | 1084519789 |
| http://127.0.0.1:22379 | 1084519789 |
| http://127.0.0.1:32379 | 1084519789 |
+------------------------+------------+
```

## ALARM \<subcommand\>

Provides alarm related commands

## ALARM DISARM

`alarm disarm` Disarms all alarms

RPC: Alarm

### Output

`alarm:<alarm type>` if alarm is present and disarmed.

### Examples

```bash
etcdctl alarm disarm
```

If NOSPACE alarm is present:

```bash
etcdctl alarm disarm
# alarm:NOSPACE
```

## ALARM LIST

`alarm list` lists all alarms.

RPC: Alarm

### Output

`alarm:<alarm type>` if alarm is present, empty string if no alarms present.

### Examples

```bash
etcdctl alarm list
```

If NOSPACE alarm is present:

```bash
etcdctl alarm list
# alarm:NOSPACE
```

## DEFRAG [options]

DEFRAG defragments the backend database file for a set of given endpoints while etcd is running, ~~or directly defragments an etcd data directory while etcd is not running~~. When an etcd member reclaims storage space from deleted and compacted keys, the space is kept in a free list and the database file remains the same size. By defragmenting the database, the etcd member releases this free space back to the file system.

**Note: to defragment offline (`--data-dir` flag), use: `etcutl defrag` instead**

**Note that defragmentation to a live member blocks the system from reading and writing data while rebuilding its states.**

**Note that defragmentation request does not get replicated over cluster. That is, the request is only applied to the local node. Specify all members in `--endpoints` flag or `--cluster` flag to automatically find all cluster members.**

### Options

- data-dir -- Optional. **Deprecated**. If present, defragments a data directory not in use by etcd. To be removed in v3.6.

### Output

For each endpoints, prints a message indicating whether the endpoint was successfully defragmented.

### Example

```bash
etcdctl --endpoints=localhost:2379,badendpoint:2379 defrag
# Finished defragmenting etcd member[localhost:2379]
# Failed to defragment etcd member[badendpoint:2379] (grpc: timed out trying to connect)
```

Run defragment operations for all endpoints in the cluster associated with the default endpoint:

```bash
etcdctl defrag --cluster
Finished defragmenting etcd member[http://127.0.0.1:2379]
Finished defragmenting etcd member[http://127.0.0.1:22379]
Finished defragmenting etcd member[http://127.0.0.1:32379]
```

To defragment a data directory directly, use the `etcdutl` with `--data-dir` flag 
(`etcdctl` will remove this flag in v3.6):

``` bash
# Defragment while etcd is not running
./etcdutl defrag --data-dir default.etcd
# success (exit status 0)
# Error: cannot open database at default.etcd/member/snap/db
```

### Remarks

DEFRAG returns a zero exit code only if it succeeded defragmenting all given endpoints.

## SNAPSHOT \<subcommand\>

SNAPSHOT provides commands to restore a snapshot of a running etcd server into a fresh cluster.

## SNAPSHOT SAVE \<filename\>

SNAPSHOT SAVE writes a point-in-time snapshot of the etcd backend database to a file.

### Output

The backend snapshot is written to the given file path.

### Example

Save a snapshot to "snapshot.db":
```
etcdctl snapshot save snapshot.db
```

## SNAPSHOT RESTORE [options] \<filename\>

Note: Deprecated. Use `etcdutl snapshot restore` instead. To be removed in v3.6.

SNAPSHOT RESTORE creates an etcd data directory for an etcd cluster member from a backend database snapshot and a new cluster configuration. Restoring the snapshot into each member for a new cluster configuration will initialize a new etcd cluster preloaded by the snapshot data.

### Options

The snapshot restore options closely resemble to those used in the `etcd` command for defining a cluster.

- data-dir -- Path to the data directory. Uses \<name\>.etcd if none given.

- wal-dir -- Path to the WAL directory. Uses data directory if none given.

- initial-cluster -- The initial cluster configuration for the restored etcd cluster.

- initial-cluster-token -- Initial cluster token for the restored etcd cluster.

- initial-advertise-peer-urls -- List of peer URLs for the member being restored.

- name -- Human-readable name for the etcd cluster member being restored.

- skip-hash-check -- Ignore snapshot integrity hash value (required if copied from data directory)

### Output

A new etcd data directory initialized with the snapshot.

### Example

Save a snapshot, restore into a new 3 node cluster, and start the cluster:
```
etcdctl snapshot save snapshot.db

# restore members
bin/etcdctl snapshot restore snapshot.db --initial-cluster-token etcd-cluster-1 --initial-advertise-peer-urls http://127.0.0.1:12380  --name sshot1 --initial-cluster 'sshot1=http://127.0.0.1:12380,sshot2=http://127.0.0.1:22380,sshot3=http://127.0.0.1:32380'
bin/etcdctl snapshot restore snapshot.db --initial-cluster-token etcd-cluster-1 --initial-advertise-peer-urls http://127.0.0.1:22380  --name sshot2 --initial-cluster 'sshot1=http://127.0.0.1:12380,sshot2=http://127.0.0.1:22380,sshot3=http://127.0.0.1:32380'
bin/etcdctl snapshot restore snapshot.db --initial-cluster-token etcd-cluster-1 --initial-advertise-peer-urls http://127.0.0.1:32380  --name sshot3 --initial-cluster 'sshot1=http://127.0.0.1:12380,sshot2=http://127.0.0.1:22380,sshot3=http://127.0.0.1:32380'

# launch members
bin/etcd --name sshot1 --listen-client-urls http://127.0.0.1:2379 --advertise-client-urls http://127.0.0.1:2379 --listen-peer-urls http://127.0.0.1:12380 &
bin/etcd --name sshot2 --listen-client-urls http://127.0.0.1:22379 --advertise-client-urls http://127.0.0.1:22379 --listen-peer-urls http://127.0.0.1:22380 &
bin/etcd --name sshot3 --listen-client-urls http://127.0.0.1:32379 --advertise-client-urls http://127.0.0.1:32379 --listen-peer-urls http://127.0.0.1:32380 &
```

## SNAPSHOT STATUS \<filename\>

Note: Deprecated. Use `etcdutl snapshot restore` instead. To be removed in v3.6.

SNAPSHOT STATUS lists information about a given backend database snapshot file.

### Output

#### Simple format

Prints a humanized table of the database hash, revision, total keys, and size.

#### JSON format

Prints a line of JSON encoding the database hash, revision, total keys, and size.

### Examples
```bash
etcdctl snapshot status file.db
# cf1550fb, 3, 3, 25 kB
```

```bash
etcdctl --write-out=json snapshot status file.db
# {"hash":3474280699,"revision":3,"totalKey":3,"totalSize":24576}
```

```bash
etcdctl --write-out=table snapshot status file.db
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| cf1550fb |        3 |          3 | 25 kB      |
+----------+----------+------------+------------+
```

## MOVE-LEADER \<hexadecimal-transferee-id\>

MOVE-LEADER transfers leadership from the leader to another member in the cluster.

### Example

```bash
# to choose transferee
transferee_id=$(etcdctl \
  --endpoints localhost:2379,localhost:22379,localhost:32379 \
  endpoint status | grep -m 1 "false" | awk -F', ' '{print $2}')
echo ${transferee_id}
# c89feb932daef420

# endpoints should include leader node
etcdctl --endpoints ${transferee_ep} move-leader ${transferee_id}
# Error:  no leader endpoint given at [localhost:22379 localhost:32379]

# request to leader with target node ID
etcdctl --endpoints ${leader_ep} move-leader ${transferee_id}
# Leadership transferred from 45ddc0e800e20b93 to c89feb932daef420
```



# 并发命令

## LOCK [options] \<lockname\> [command arg1 arg2 ...]

LOCK 获取具有给定名称的分布式互斥体。  一旦获得锁，它将一直保持到 etcdctl 终止。

### Options

- ttl - time out in seconds of lock session.

### Output

Once the lock is acquired but no command is given, the result for the GET on the unique lock holder key is displayed.

If a command is given, it will be executed with environment variables `ETCD_LOCK_KEY` and `ETCD_LOCK_REV` set to the lock's holder key and revision.

### Example

Acquire lock with standard output display:

```bash
etcdctl lock mylock
# mylock/1234534535445
```

Acquire lock and execute `echo lock acquired`:

```bash
etcdctl lock mylock echo lock acquired
# lock acquired
```

Acquire lock and execute `etcdctl put` command
```bash
etcdctl lock mylock etcdctl put foo bar
# OK
```

### Remarks

LOCK returns a zero exit code only if it is terminated by a signal and releases the lock.

If LOCK is abnormally terminated or fails to contact the cluster to release the lock, the lock will remain held until the lease expires. Progress may be delayed by up to the default lease length of 60 seconds.

## ELECT [options] \<election-name\> [proposal]

ELECT participates on a named election. A node announces its candidacy in the election by providing
a proposal value. If a node wishes to observe the election, ELECT listens for new leaders values.
Whenever a leader is elected, its proposal is given as output.

### Options

- listen -- observe the election.

### Output

- If a candidate, ELECT displays the GET on the leader key once the node is elected election.

- If observing, ELECT streams the result for a GET on the leader key for the current election and all future elections.

### Example

```bash
etcdctl elect myelection foo
# myelection/1456952310051373265
# foo
```

### Remarks

ELECT returns a zero exit code only if it is terminated by a signal and can revoke its candidacy or leadership, if any.

If a candidate is abnormally terminated, election rogress may be delayed by up to the default lease length of 60 seconds.



# 授权命令

## AUTH \<enable or disable\>

`auth enable` activates authentication on an etcd cluster and `auth disable` deactivates. When authentication is enabled, etcd checks all requests for appropriate authorization.

RPC: AuthEnable/AuthDisable

### Output

`Authentication Enabled`.

### Examples

```bash
etcdctl user add root
# Password of root:#type password for root
# Type password of root again for confirmation:#re-type password for root
# User root created
etcdctl user grant-role root root
# Role root is granted to user root
etcdctl user get root
# User: root
# Roles: root
etcdctl role add root
# Role root created
etcdctl role get root
# Role root
# KV Read:
# KV Write:
etcdctl auth enable
# Authentication Enabled
```

## ROLE \<subcommand\>

ROLE is used to specify different roles which can be assigned to etcd user(s).

## ROLE ADD \<role name\>

`role add` creates a role.

RPC: RoleAdd

### Output

`Role <role name> created`.

### Examples

```bash
etcdctl --user=root:123 role add myrole
# Role myrole created
```

## ROLE GET \<role name\>

`role get` lists detailed role information.

RPC: RoleGet

### Output

Detailed role information.

### Examples

```bash
etcdctl --user=root:123 role get myrole
# Role myrole
# KV Read:
# foo
# KV Write:
# foo
```

## ROLE DELETE \<role name\>

`role delete` deletes a role.

RPC: RoleDelete

### Output

`Role <role name> deleted`.

### Examples

```bash
etcdctl --user=root:123 role delete myrole
# Role myrole deleted
```

## ROLE LIST \<role name\>

`role list` lists all roles in etcd.

RPC: RoleList

### Output

A role per line.

### Examples

```bash
etcdctl --user=root:123 role list
# roleA
# roleB
# myrole
```

## ROLE GRANT-PERMISSION [options] \<role name\> \<permission type\> \<key\> [endkey]

`role grant-permission` grants a key to a role.

RPC: RoleGrantPermission

### Options

- from-key -- grant a permission of keys that are greater than or equal to the given key using byte compare

- prefix -- grant a prefix permission

### Output

`Role <role name> updated`.

### Examples

Grant read and write permission on the key `foo` to role `myrole`:

```bash
etcdctl --user=root:123 role grant-permission myrole readwrite foo
# Role myrole updated
```

Grant read permission on the wildcard key pattern `foo/*` to role `myrole`:

```bash
etcdctl --user=root:123 role grant-permission --prefix myrole readwrite foo/
# Role myrole updated
```

## ROLE REVOKE-PERMISSION \<role name\> \<permission type\> \<key\> [endkey]

`role revoke-permission` revokes a key from a role.

RPC: RoleRevokePermission

### Options

- from-key -- revoke a permission of keys that are greater than or equal to the given key using byte compare

- prefix -- revoke a prefix permission

### Output

`Permission of key <key> is revoked from role <role name>` for single key. `Permission of range [<key>, <endkey>) is revoked from role <role name>` for a key range. Exit code is zero.

### Examples

```bash
etcdctl --user=root:123 role revoke-permission myrole foo
# Permission of key foo is revoked from role myrole
```

## USER \<subcommand\>

USER provides commands for managing users of etcd.

## USER ADD \<user name or user:password\> [options]

`user add` creates a user.

RPC: UserAdd

### Options

- interactive -- Read password from stdin instead of interactive terminal

### Output

`User <user name> created`.

### Examples

```bash
etcdctl --user=root:123 user add myuser
# Password of myuser: #type password for my user
# Type password of myuser again for confirmation:#re-type password for my user
# User myuser created
```

## USER GET \<user name\> [options]

`user get` lists detailed user information.

RPC: UserGet

### Options

- detail -- Show permissions of roles granted to the user

### Output

Detailed user information.

### Examples

```bash
etcdctl --user=root:123 user get myuser
# User: myuser
# Roles:
```

## USER DELETE \<user name\>

`user delete` deletes a user.

RPC: UserDelete

### Output

`User <user name> deleted`.

### Examples

```bash
etcdctl --user=root:123 user delete myuser
# User myuser deleted
```

## USER LIST

`user list` lists detailed user information.

RPC: UserList

### Output

- List of users, one per line.

### Examples

```bash
etcdctl --user=root:123 user list
# user1
# user2
# myuser
```

## USER PASSWD \<user name\> [options]

`user passwd` changes a user's password.

RPC: UserChangePassword

### Options

- interactive -- if true, read password in interactive terminal

### Output

`Password updated`.

### Examples

```bash
etcdctl --user=root:123 user passwd myuser
# Password of myuser: #type new password for my user
# Type password of myuser again for confirmation: #re-type the new password for my user
# Password updated
```

## USER GRANT-ROLE \<user name\> \<role name\>

`user grant-role` grants a role to a user

RPC: UserGrantRole

### Output

`Role <role name> is granted to user <user name>`.

### Examples

```bash
etcdctl --user=root:123 user grant-role userA roleA
# Role roleA is granted to user userA
```

## USER REVOKE-ROLE \<user name\> \<role name\>

`user revoke-role` revokes a role from a user

RPC: UserRevokeRole

### Output

`Role <role name> is revoked from user <user name>`.

### Examples

```bash
etcdctl --user=root:123 user revoke-role userA roleA
# Role roleA is revoked from user userA
```



# 实用命令

## MAKE-MIRROR

[make-mirror][mirror] mirrors a key prefix in an etcd cluster to a destination etcd cluster.

- dest-cacert——目标集群的 TLS 证书颁发机构文件 
- dest-cert -- 目标集群的 TLS 证书文件 
- dest-key -- 目标集群的 TLS 密钥文件 
- prefix -- 镜像的键值前缀 
- dest-prefix -- 将前缀镜像到目标集群中不同前缀的目标前缀 
- no-dest-prefix -- 将键值镜像到目标集群的根 
- dest-insecure-transport -- 禁用客户端连接的传输安全 
- max-txn-ops -- 同步更新期间事务中允许的最大操作数 

```shell
# 传输到目标集群的密钥的大致总数，每30秒更新一次。 
etcdctl make-mirror mirror.example.com:2379
```

## VERSION

```bash
etcdctl version
# etcdctl version: 3.1.0-alpha.0+git
# API version: 3.1
```

## CHECK \<subcommand\>

CHECK provides commands for checking properties of the etcd cluster.

## CHECK PERF

> 效能检查

CHECK PERF 检查 etcd 集群的性能 60 秒。  运行 `check perf`通常可以创建一个大的密钥空间历史记录，可以使用以下命令自动压缩和碎片整理 `--auto-compact`和 `--auto-defrag`选项如下所述。 

请注意，不同的工作负载模型在客户端数量和吞吐量方面使用不同的配置。  以下是每个负载的配置： 

| 加载   | 客户数量 | 放置请求数（请求/秒） |
| ------ | -------- | --------------------- |
| 小的   | 50       | 10000                 |
| 中等的 | 200      | 100000                |
| 大的   | 500      | 1000000               |
| 超大   | 1000     | 3000000               |

该测试检查以下条件： 

- 吞吐量应至少为已发出请求的 90% 
- 所有请求应在 500 毫秒内完成 
- 请求的标准偏差应小于100毫秒 

因此，一种工作负载模型可能有效，而另一种可能会失败。 

RPC：检查性能 

### 选项 

- load——性能检查的工作负载模型。  接受的工作负载：s（小）、m（中）、l（大）、xl（xLarge） 
- prefix——写入性能检查键的前缀。 
- auto-compact -- 如果为 true，则在测试完成后压缩存储最新版本。 
- auto-defrag -- 如果为 true，则在测试完成后对存储进行碎片整理。 

### 输出 

打印不同标准（如吞吐量）的性能检查结果。  还打印检查的总体状态（通过或失败）。 

### Examples

显示通过和失败状态的示例。  失败的原因是在为开发和测试目的而创建的笔记本电脑环境上运行的单节点 etcd 集群上尝试了较大的工作负载。

```bash
etcdctl check perf --load="s"
# 60 / 60 Booooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo! 100.00%1m0s
# PASS: Throughput is 150 writes/s
# PASS: Slowest request took 0.087509s
# PASS: Stddev is 0.011084s
# PASS
etcdctl check perf --load="l"
# 60 / 60 Booooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo! 100.00%1m0s
# FAIL: Throughput too low: 6808 writes/s
# PASS: Slowest request took 0.228191s
# PASS: Stddev is 0.033547s
# FAIL
```

## CHECK DATASCALE

CHECK DATASCALE 检查给定服务器端点上不同工作负载保存数据的内存使用情况。  运行 `check datascale`通常可以创建一个大的密钥空间历史记录，可以使用以下命令自动压缩和碎片整理 `--auto-compact`和 `--auto-defrag`选项如下所述。

RPC: CheckDatascale

- load——数据规模检查的工作负载模型。  接受的工作负载：s（小）、m（中）、l（大）、xl（xLarge） 
- prefix -- 用于写入数据规模检查键的前缀。 
- auto-compact -- 如果为 true，则在测试完成后压缩存储最新版本。 
- auto-defrag -- 如果为 true，则在测试完成后对存储进行碎片整理。 

输出: 打印给定工作负载的系统内存使用情况。  如果通过了相关选项，还打印压缩和碎片整理的状态。 

```bash
etcdctl check datascale --load="s" --auto-compact=true --auto-defrag=true
# Start data scale check for work load [10000 key-value pairs, 1024 bytes per key-value, 50 concurrent clients].
# Compacting with revision 18346204
# Compacted with revision 18346204
# Defragmenting "127.0.0.1:2379"
# Defragmented "127.0.0.1:2379"
# PASS: Approximate system memory used : 64.30 MB.
```



## snapshot

```shell
ROOT="${HOME}/tmp/etcd"
etcdctl snapshot save ${ROOT}/backup/$(date +'%Y%m%d%H%M').db
```





# 输出格式

