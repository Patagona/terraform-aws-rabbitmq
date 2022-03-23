install-docker-amz-linux-2:
  cmd.run:
    - name: amazon-linux-extras install docker=stable -y
    - require_in:
      - docker-post-installation

docker-post-installation:
  service.running:
    - name: docker
    - enable: True
