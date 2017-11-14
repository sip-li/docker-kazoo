FROM    alpine:latest

ADD     couchdb-data.tar.gz /volumes/couchdb

VOLUME  ["/volumes/couchdb/data"]

HEALTHCHECK --interval=15s --timeout=5s CMD /bin/true
