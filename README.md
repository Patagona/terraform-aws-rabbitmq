# Dead simple Terraform configuration for creating RabbitMQ cluster on AWS.

## What it does ?

1. Uses [official](https://hub.docker.com/_/rabbitmq/) RabbitMQ docker image.
1. Creates Autoscaling Group and ELB to load balance nodes
1. Configures `/` vhost queues in High Available (Mirrored) mode with automatic synchronization (`"ha-mode":"all", "ha-sync-mode":"3"`)
1. uses the aws peer discorvery for cluster creation
1. removes old nodes from the cluster and rebalances quorum queues when a new node joins the cluster
1. the names of the various resources is formed by ${name_prefix}-${resource_abreviation}-${region}-${name_postfix}, thereby allowing you to conform to the [naming scheme](https://stepan.wtf/cloud-naming-convention/). The prefix should contain prefix, project and env. The postfix should contain description and suffix.


## How to use it ?
The following configuration options exist:

```
module "rabbitmq" {
  name_prefix                       = ""
  name_postfix                      = ""
  source                            = "github.com/Patagona/terraform-aws-rabbitmq?ref=001055c"
  vpc_id                            = ""
  ssh_key_name                      = ""
  subnet_ids                        = [""]
  elb_additional_security_group_ids = [""]
  size                              = "3"
  service_tag                       = ""
  instance_type                     = "t2.micro"
  rabbitmq_version                  = "3.9.13-management"
  instance_volume_type              = "gp3"
  instance_volume_size              = "10"
  instance_volume_iops              = "3000"
  instance_volume_throughput        = "125"
}
```
