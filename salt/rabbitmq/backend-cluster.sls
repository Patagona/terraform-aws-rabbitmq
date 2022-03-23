add-rabbit-env-file:
  file.managed:
    - name : /root/rabbit.env
    - mode: 0644
    - template: jinja
    - source: salt://rabbitmq/templates/rabbit-env.tmpl

activate-plugins:
  file.managed:
    - name : /root/conf/enabled_plugins
    - mode: 0644
    - makedirs: True
    - dir_mode: 755
    - contents: |
        [rabbitmq_management, rabbitmq_peer_discovery_aws]

add-rabbit-configuration:
  file.managed:
    - name : /root/conf/rabbitmq.conf
    - mode: 0644
    - makedirs: True
    - dir_mode: 755
    - contents: |
        cluster_formation.peer_discovery_backend = aws
        cluster_formation.aws.region = eu-west-1
        cluster_formation.aws.access_key_id = TODO_SOME_ACCESS_KEY
        cluster_formation.aws.secret_key = TODO_SOME_ACCESS_SECRET
        cluster_formation.aws.use_autoscaling_group = true

        cluster_formation.discovery_retry_limit = 20
        cluster_formation.discovery_retry_interval = 1000

add-erlang-cookies:
  file.managed:
    - name : /root/data/.erlang.cookie
    - mode: 0644
    - makedirs: True
    - dir_mode: 755
    - contents: TODO_SOME_ACCESS_SECRET

add-rabbitmq-metric-collector-config:
  file.managed:
    - template: jinja
    - mode: 0644
    - name : /root/metricbeat.yml
    - source: salt://rabbitmq/templates/metricbeat.yml.tmpl

run-rabbitmq-container:
  docker_container.running:
  - name: rabbitmq
  - image: rabbitmq:{{ pillar.rabbitmq.version }}
  - port_bindings:
    - "15672:15672"
    - "5672:5672"
  - hostname: {{ grains['host'] }}
  # - binds:
    # - /root/conf:/etc/rabbitmq

run-metricbeat-container:
  docker_container.running:
  - name: metricbeat
  - network_mode: "host"
  - image: docker.elastic.co/beats/metricbeat:{{ pillar.metricbeat.version }}
  - binds:
    - /root/metricbeat.yml:/usr/share/metricbeat/metricbeat.yml:ro
    - /var/run/docker.sock:/var/run/docker.sock:ro
    - /sys/fs/cgroup:/hostfs/sys/fs/cgroup:ro
    - /proc:/hostfs/proc:ro
    - /:/hostfs:ro
  - command: metricbeat -e -strict.perms=false
