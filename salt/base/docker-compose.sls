install-docker-compose:
    file.managed:
    - name : /usr/bin/docker-compose
    - source: https://github.com/docker/compose/releases/latest/download/docker-compose-{{ grains['kernel'] }}-{{ grains['cpuarch'] }}
    - skip_verify: True
    - mode: 0755
    - require:
      - service: docker