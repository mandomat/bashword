HOME='/opt'
BASHWORD_DB="$HOME/bashword.db" \
BASHWORD_KEY="$HOME/bashword.key"
BASHWORD_DB_KEY
: '
./bashword.sh /usr/local/bin/


	echo 'echo "DBPASS:$BASHWORD_DB_KEY"; while true; do sleep 3600; done' > /usr/local/bin/entrypoint.sh && \
	chmod +x /usr/local/bin/bashword.sh && \
	yes | adduser -s /dev/null -h /opt -u 1000 -D bw && \
	if [[ ! -e "$BASHWORD_DB.enc" ]]; then \
                touch $BASHWORD_DB; \
                openssl enc -aes-256-cbc -salt -in "$BASHWORD_DB" -out "$BASHWORD_DB.enc" -pass pass:"$BASHWORD_DB_KEY"; \
                rm $BASHWORD_DB; \
        fi
'
