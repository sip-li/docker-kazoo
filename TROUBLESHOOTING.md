# kazoo troubleshooting

### Problem
kazoo loads up an extra zone, 'local', complains about not finding amqp broker on localhost and sup command fails.

### Solution
verify that kazoo is starting up with correct -name argument in vm.args. Verify it's kazoo_apps!
