# Suthsung Design Doc

This lays out the high-level design specification for Suthsung.

A user Alice chooses a `username`, a `password`, and a `session_id` (to
differentiate between different devices). If _both_ the username and pass
clash with another user Bob, then shit will hit the fan. So Alice better
choose something unique.

We define the following functions.
* `HASH(z)` is the main hashing method used by this site. It utilizes 
    SHA512 and xors to produce 256-bit hashes.
* `bcrypt(msg, salt, rounds)` returns the bcrypt digest of `msg` using salt 
    `salt` and `rounds` number of rounds.

Alice's 256-bit `secret_id` will be `secret_id = bcrypt(HASH(password),
HASH(username), 12)`. `session_id` is chosen by Alice (e.g. "Alice's Home
Desktop"), taking care not to clash with any of her other `session_id`'s.

For a particular chat `room` with ID `room_id`, Alice will generate her
`public_key` and `secret_key` via [ED25519](https://ed25519.cr.yp.to/),
using `seed=HASH([secret_id, room_id])` to [seed the
generation](https://www.npmjs.com/package/tweetnacl#naclsignkeypairfromseedseed).

## Start a Chat Room

All communications (even those amongst just 2 people), are done in chat
`room`s. Alice can start a chat `room` called "Pianists" as follows. She
randomly chooses a `room_id` and makes a folder `room_id/` to her home
directory. In that folder, she puts 
* a `META` file, which will give various facts about the room.
* a `logs` directory, which will contain log files of what happens in the 
    chat room.
* a `content` folder, which will contain messages/media/videos that are 
    used in the room.

The `META` file will be a dictionary with the following keys/values.
* `room_name`: Name of the room, in this case "Pianists".
* `room_image`: The hash of the cover image for this room.
* `room_id`: Randomly generated id used to identify this room.
* `admin_list`: Set containing the `(public_key, nickname, session_ids)`s 
    for admins (who are allowed to invite/remove people, etc.). In this
    case, the set starts out as `{(public_key_Alice, "Alice",
    session_ids_Alice)}`, where `session_ids_Alice` is a list of the
    different `session_id`'s for Alice's different sessions (e.g. running
    on her different devices), and `"Alice"` is the preferred nickname
    she'd like to be known by in the room.
* `guest_list`: Set contianing the `(public_key, nickname, session_ids)`s 
    for guests in the `room` (who are allowed to participate). Starts
    empty.
* `last_seen_list`: Dictionary containing entries 
    `{ (public_key, session_id): (stamp, sign) }` for each member of the
    `room`.  Here, `stamp` is the Unix timestamp of when you think that
    member was last seen in the room, and `sign` is a digital signature of
    them signing the `stamp` (to make sure no one just forged them being
    online).

The `logs` directory will contain many `log` files. Each `log` file is a
dictionary containing at most 100 entries. Each entry's value will
correspond to an event, and each key will be a `stamp` corresponding to
when the event happened. The last 5 characters of `stamp` are random (to
prevent collisions), and the beginning of the `stamp` will be a unix
timestamp of when the event happened. The value will be an ordered list
`(event, checksum, verification)`. 
* `event` will be the event that happened (e.g. Alice posted video `x`).
* `checksum = HASH(event) + (prev_checksum)`, where `prev_checksum` is the 
    checksum for the event that prior to this one.  Traversing through
    `log` in order of `stamp`, the sequence of checksums should obey this
    property.
* `verification` is a digital signature by a member of the network 
    confirming that they encountered this event around the time `stamp`
    says it was created. This e.g. makes it harder for Bob to say "I posted
    this message 1 week ago!", because he'll need at least 1 member of the
    network to actually confirm they encountered the message around that
    time.

The name of a `log` file is taken to be the most recent `(stamp, checksum)`
in it.

## Communication

Communication is done on a PeerJS channel with a chosen `peerjs_id`.

Communication in `room`s is very decentralized. When in a room together,
Alice and Bob will very selectively communicate (see below in the
**Decentralized Network Topology**). When Alice and Bob *are* to
communicate, they choose a channel as follows. Since both know each other's
`public_key`, they have access to a `shared_key` via Diffie-Hellman. Let
`t=stamp//60` be the unix time in seconds divided by 60 (e.g. the minutes
since Jan 01 1970 UTC), and let `sesh_hash =
HASH(HASH(session_id_Alice)^HASH(session_id_Bob))`. Then Alice and Bob
choose the channel `peerjs_id = HASH([shared_key, t, sesh_hash])`.

## Decentralized Network Topology

To save significantly on network bandwidth and processing power, all
members of a `room` aren't constantly connected to every other member on
some channel. Instead, each member is only connected to a few other members
at a time, while still keeping the overall network of members of the room
robustly connected.

The connections chosen by the `room` are dictated by 2 independent
[Hypercubes](https://en.wikipedia.org/wiki/Hypercube_internetwork_topology)
`C_0` and `C_1`. Furthermore, `C_0` changes every even minute, and `C_1`
changes every odd minute. For `C_i`, let `t_i = (stamp + i*60)//120` be the
current time index of the hypercube. Let `m` be the number of recently seen
room members (e.g. seen in the last 10 minutes). Then the dimension of
`C_i` will be `d=floor(log2(m))`, and each member is assigned a `d`-bit
address `addr`. For a member Alice on a particular session, the `j`th bit
of her address `addr_Alice[j]` will be assigned by PNRG seeded with
`seed=HASH([room_id, public_key_Alice, session_id_Alice, t_i, j])`. Thus,
any member can communicate any other member's `addr`. Alice's `neighbors`
(the people she will communicate with) will be all the members with an
`addr` off from hers by no more than 1 bit. It is only with these
`neighbors` whom Alice will connect (until the hypercube changes in 2
minutes). Also, Alice will mainly initiate communications with the most
recently updated hypercube, while still listening to the other hypercube.

## Syncing Logs

For the purpose of keeping `logs` synced, here are some `commands` that
Alice can send her neighbors, and how a neighbor Bob could respond to such
commands.

* To begin a sync, Alice can send `(SYNC_REQUEST, latest_stamp, 
    latest_checksum, prev_stamp, prev_checksum)`, where `stamp`s and
    `checksum`s come from her latest and 2nd most latest `log` files
    respectively.
* If Alice receives such a request, he searches `logs` for those two files.
    * If they are also his 2 latest `logs`, then he does nothing.
    * If he has both `log`s, but they're not his 2 latest, then he will 
        send Alice `(SYNC_REQUEST, next_stamp, next_checksum, latest_stamp,
        latest_checksum)`.
    * If he has the `prev_log` match with one of his `log` files, but 
        `latest_log` doesn't, then he will send Alice `(LOG_REQUEST,
        prev_stamp, prev_checksum)`, which will let Alice know to send
        every log after `prev_log`.
    * If neither `log`s match for Bob, then he will find `before_log` that 
        has the most recent time before `prev_stamp`, and he will send
        Alice `(SYNC_REQUEST, next_stamp, next_checksum, before_stamp,
        before_checksum)`.
* If Alice receives `(LOG_REQUEST, prev_stamp, prev_checksum)` from Bob, 
    then she searches for that `log` file.
    * If she has it, she sends every `log` file after it, in order from 
        oldest to newest. She sends a `log` file as `(LOG_FILE, log)`
    * If she doesn't have it, then she finds a `before_log` that has the 
        most recent time before `prev_log`, and sends Bob `(SYNC_REQUEST,
        next_stamp, next_checksum, before_stamp, before_checksum)`

At least once per a minute, Alice will initiate a sync with each of her
neighbors on the network.

## Inviting Someone to a Room

If Alice wants to invite Bob to a room (in which she is allowed to), she
goes through the following steps.
* Randomly generate a 6-character `pin`. 
* Alice communicates this `pin` to Bob by other means (preferably, in 
    person), and then they both go to the temporary channel `peerjs_id =
    HASH(pin)`.
* Alice sends Bob `(INVITE, room_id)`
* When Bob receives this, he sends Alice his `(INVITE_ACCEPT, public_key, 
    nickname, session_id)`.
* To her `logs` for the room, Alice adds the appropriate `ADD_GUEST` 
    command (see below). Alice also treats Bob as a neighbor for 5 minutes.
* Bob initiates a sync request with Alice.

## Syncing Last Seen List and Other Miscellania

At least once a minute, send her `last_seen_list` to all her neighbors. She
does this as follows.

* Alice updates her own last seen time in the `last_seen_list` to the 
    current time.
* Alice sends the message `(LAST_SEEN, last_seen_list)` to her neighbors.
* If Bob receives this, he updates each entry of his `last_seen_list` 
    that's out of date.

If Alice starts to type, she can send `(TYPING, public_key_Alice, stamp,
sign)` to her neighbors.
* If Bob receives such a message, he will pass it on to his neighbors if 
    `stamp` is not more than 10 seconds old.

## Types of Events.

The following is a list of types of `event`s (which are recorded in the
the `logs`).

* `(POST_MESSAGE, public_key, msg, sig)`: Corresponds to person with public 
    key `public_key` posting text message `msg`. `sig` is a digital
    signature verifying the person sent that message.
* `(POST_FILE, public_key, file_hash, file_name, sig)`: Corresponds to 
    person with public key `public_key` posting a file with hash
    `file_hash` and suggested file name `file_name`. `sig` is the digital
    signature verifying the person did this. If you don't have a file of
    that hash stored, you must request it from the `room`.
* `(ADD_GUEST, public_key, new_public_key, nickname, sig)`: Corresponds to 
    an admin with public key `public_key` telling the room to add a guest
    with the pubic key `new_public_key` and nickname `nickname` to the
    `guest_list`.
* `(ADD_SESSION, public_key, session_id, sig)`: Corresponds to anyone with 
    public key `public_key` saying to add another one of their sessions
    with ID `session_id`. `sig` is the digital signature verifying the
    person did this.
* `(PROMOTE_GUEST, public_key, guest_public_key, sig)`: Corresponds to an 
    admin with public key `public_key` suggesting to promote guest with
    public key `guest_public_key` to an admin. `sig` is the digital
    signature verifying the admin requests this.
* `(DEMOTE_ADMIN, id, admin_id, sig)`: Similar to the above.
* `(ROOM_IMAGE, public_key, file_hash, file_name, sig)`: Similar to 
    `POST_FILE`, but specifies the file should be set as the `room_image`.
* `(ROOM_NAME, public_key, new_room_name, sig)`: Corresponds to a member 
    with public key `public_key` requesting to change the `room_name` to
    `new_room_name`.
* `(CHANGE_NICKNAME, public_key, new_nickname, sig)`: Corresponds to a 
    member with public key `public_key` requesting to change their nickname
    to `new_nickname`.

## Request a File

If Alice needs a file with hash `file_hash`, then she gets it from the
network with the following torrent-like protocol.

* Alice sends her neighbors `(FILE_REQUEST, file_hash)`. 
* If Bob receives such a message, he sends `(FILE_METADATA, piece_tags)`,
    where `piece_tags` is the list of 32-bit hashes of the pieces of the
    file Bob has. For pieces he doesn't have, `null`s are placed. If Bob
    doesn't have the file, he sends a single `(null)`. Each piece is a
    maximum of 256kB, with only the final piece possibly being smaller.
* Alice collects the `piece_tags` from everyone who responds to her
    request. She then proceeds to make piece requests in random order.
* To request the piece with index `i` from Bob, she sends him 
    `(PIECE_REQUEST, file_hash, i)`
* If Bob receives such a request, he will respond with 
    `(PIECE_SERVE, file_hash, i, piece)`.
* Upon successfully receiving a piece, Alice announces she has it to all 
    current neighbors she thinks doesn't have the piece. She does this
    announce by sending `(PIECE_HAVE, file_hash, i)`.
* If Bob receives such an announce but already has that piece, then he 
    sends Alice his up-to-date `(FILE_METADATA, piece_tags)`

## Getting Synchronized Time

`Date.now()` gets the client-side time. This could be off for whatever
reason. To make sure time is roughly synchronized for all parties,
`getCurrTime()` will be the function used. This function will return the
time as `Date.now() - time_offset`. If `time_offset` hasn't yet been set
(or if a big jump in time is detected), then `time_offset` is set by
getting the synchronized current time from
`https://showcase.api.linx.twenty57.net/UnixTime/tounix?date=now`.
