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

## Sync Request

Here is how a user (e.g. Alice) will sync her `log` with the `room`'s.

1. To all members, Alice sends `(SYNC_REQUEST, latest_stamp, latest_checksum)`, where
`latest_checksum` is the `checksum` of the last entry in her `log`.
2. If Bob receives the request, and his TODO
