# Suthsung Design Doc

This lays out the design specification for Suthsung.

A user Alice chooses a `username` and a `password`. If _both_ the un and
pass clash with another user Bob, then shit will hit the fan. So Alice
better choose something unique.

Alice's `id` will be `HASH(username) + HASH(password)`, where `HASH(z) =
SHA3(z + SALT)` is the hash function this website uses, and
`SALT="suthsung"` is the site-wide "salt" we will employ for our hasher (so
it doesn't by mistake clash with hashers employed by other sites).

Alice can start a chat `room` as follows. She chooses the `room_name` to be
"Pianists", and makes a folder `room_name/` to her home directory. In that
folder, she puts 
* a `META` file, which will give various facts about the room.
* a `log` file, which will contain information the information 
    of what happens in the chat room.
* a `media` folder, which will contain media/videos that are used in the 
    room.

The `META` file will be a dictionary with the following keys/values.
* `room_name`: Name of the room, in this case "Pianists".
* `room_id`: Randomly generated ID for this room.
* `admin_list`: Set containing the `id`s for admins (who are allowed to 
    invite/remove people, etc.). In this case, the set starts out as
    {`id_Alice`}.
* `guest_list`: Set contianing the `id`s for guests in the `room` (who are 
    allowed to participate). Starts empty.
* `version`: a string. The last 5 characters are random (to prevent 
    collisions), and the beginning of the string is the unix timestamp of
    when that version of the `META` file was made.

The `log` file will be a dictionary. Each value will correspond to an
event, and each key will be a `stamp` corresponding to when the event
happened. The last 5 characters of `stamp` are random (to prevent
collisions), and the beginning of the `stamp` will be a unix timestamp of
when the event happened. The value will be an ordered pair `(event,
checksum)`. `event` will be the event that happened (e.g. Alice posted
video `x`), and `checksum = HASH(event) + (prev_checksum)`, where
`prev_checksum` is the checksum for the event that prior to this one.
Traversing through `log` in order of `stamp`, the sequence of checksums
should obey this property.

## Communication

Communication is done on a PeerJS channel with a chosen `peerjs_id`.
Alice's main channel to recieve communication requests for `room` has as
its ID `Alice_main_peerjs_id = HASH(room_id) + id_Alice`. If Alice receives
a request on that channel from Bob to talk, then they move to the channel
with ID `peerjs_id = HASH(room_id) + id_Alice + id_Bob` for the bulk of
their communication and free up `Alice_main_peerjs_id` so others can
request communications with Alice.

## Sync Request

Here is how a user (e.g. Alice) will sync her `log` with the `room`'s.

* To all members, Alice sends `(SYNC_REQUEST, latest_stamp, 
    latest_checksum)`, where `latest_stamp` and `latest_checksum` are the
    `stamp` and `checksum` of the last entry in her `log`.
* If Bob receives the request, he searches his log for `latest_stamp` and 
    `latest_checksum`. 
    * If that is also his latest entry, then he sends the single-entry 
        tuple `(SYNC_UNNECESSARY)`. 
    * If he can't find it, then Bob himself will
        initiate a sync request with the `room` (similar to how Alice did).
    * If he finds both of them further into his log, then as response, 
        he will send `(SYNC_NECESSARY, new_entries)`, where `new_entries`
        is every one of the subsequent entries Alice didn't have that Bob
        does.
    * If he finds `latest_stamp`, but `latest_checksum` 
        doesn't match his `checksum`, then it means Alice is missing some
        entries in between. The following process initiates between Alice
        and Bob to restore and update Alice's log.
        * Bob sends `(SYNC_MISSING, stamps, checksums)` where `stamps` and 
            `checksums` are from his 10 latest entries
        * If Alice finds a `stamp` & `checksum` she agrees with, it means 
            Bob and her agree up until that point. So next Alice sends Bob
            `(SYNC_REQUEST, stamp, checksum)`, and they act as is already
            specified from there.
        * If Alice doesn't yet find a `stamp` & `checksum` she agrees with, 
            she sends Bob `(SYNC_MORE)`.
        * If Bob receives `(SYNC_MORE)`, he'll go back to the first 
            substep here, but send the next set of 10 entries.
* After Alice sends her request to everyone, she'll end up with a 
    large collection of responses. 
    * If all those responses are 
        `(SYNC_UNNECESSARY)`, then Alice is happy. 
    * Else, she merges all the log entries into her own log to end up with
        a synced log. As she does this, she is careful to populate a TODO
        list of actions she needs to take that are specified by those
        missing log entries (e.g. request files she is missing, or make
        changes to the `META` file).

## Types of Events.

The following is a list of types of `event`s (which are recorded in the
`log`). a

* `(POST_MESSAGE, id, msg, sig)`: Corresponds to person with ID `id` 
    posting text message `msg`. `sig` is a digital signature verifying the
    person sent that message.
* `(POST_FILE, id, file_hash, file_name, sig)`: Corresponds to person with ID `id` 
    posting a file with hash `file_hash` and suggested file name
    `file_name`. `sig` is the digital signature verifying the person did
    this. If you don't have a file of that hash stored, you must request it
    from the `room`.
* `(ADD_GUEST, id, new_id, sig)` corresponds to an admin with ID `id` 
    telling the room to add a guest with the ID `new_id` to the
    `guest_list`.
* `REMOVE_GUEST`, `ADD_ADMIN`, and `REMOVE_ADMIN` all work similarly to the 
    above.

## Request a File

If Alice needs a file with hash `file_hash`, then she gets it from the
network with the following torrent-like protocol.

* Alice sends everyone `(FILE_REQUEST, file_hash)`. 
* If Bob receives such a message, TODO
