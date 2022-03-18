rabbit_env_file:
  file.managed:
    - name : /root/rabbit.env
    - template: jinja
    - source: salt://rabbitmq/templates/rabbit-env.tmpl