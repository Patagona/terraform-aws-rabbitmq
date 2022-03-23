# Salt core gains
https://docs.saltproject.io/en/latest/ref/grains/all/salt.grains.core.html#salt.grains.core.hostname

# Salt useful commands
```
salt-call --local grains.items
salt-call --local grains.item host

salt-call --local saltutil.refresh_pillar
```

For running docker compose
```
salt-call --local -l debug dockercompose.rm /root/docker-compose.yml
```