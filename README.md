# bashword

Simple password manager in bash.

## Usage
* Download bashword.sh
* `mv bashword.sh /usr/local/bin/bw`.
* bw + commands

![alt text](https://github.com/mandomat/bashword/blob/master/bashword.png)

At its first launch, bashword will ask you for a password to encrypt the database located in `$HOME/.bashword/bashword_db.enc`.

To generate a password for facebook type `bw new -s facebook`, bashword will generate a random 8 chars long password. 

If you want to specify the length of the password (for example 16) type `bw new -s facebook -l 16`.

To specify a custom password: `bw new -s facebook -p mypass`

The command `bw update` can be used with the same flags.

`bw get -s facebook ` will return the password on your screen.

`bw ls` lists all the services in the database.

## Todo
Copy the passwords in the clipboard instead of printing them on the screen.

