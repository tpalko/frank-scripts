# passwrap

A simple archive-encrypt/decrypt-unarchive -er for sensitive but frequently updated content.

To be placed in the workflow at the beginning and end of each session. Content sits archived and encrypted on disk 99% of the time. When access is needed, passwrap decrypts and unarchives. When changes are finished, passwrap can wrap it back up.

## operation 

### 1/8/25 notes 

Given a folder name `private`

The script expects in the current directory

1. a folder by this name 
2. an archive by the name `private.tar.gz.gpg.TIMESTAMP.box`
3. a file in an interim state such as `private.tar.gz` or `private.tar.gz.gpg`

The possible states are:

* `private`, unarchived folder 
* `private.tar.gz`, archived and compressed
* `private.tar.gz.gpg`, encrypted 
* `private.tar.gz.gpg.TIMESTAMP.box`, timestamp-encoded

We first search for and resolve any interim state files to the final `...TIMESTAMP.box` file. If there are any, it will operate on the first candidate found and then exit. A `.gpg` encrypted file will take priority over the `.tar.gz` archive to address potential filename collisions.

_Note that the final state `...TIMESTAMP.box` naming serves two purposes: to retain a snapshot history and to remove the need to compare contents for recency by giving all existing versions of the target a distinct final name congruent to their timeline._

Then, we search for the plain, unarchived folder, process that to completion, and then exit.

If all candidate files have been processed to the final `...TIMESTAMP.box` state at the beginning of the run, then the latest of these is chosen and unpacked to the plain unarchived folder.

