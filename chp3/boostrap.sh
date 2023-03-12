#!/bin/bash
# Description: User script to bootstrap cluster in ECS optimized EC2 instance

sudo amazon-linux-extras install nano
echo ECS_CLUSTER={cluster_name} >> /etc/ecs/ecs.config
echo ECS_CONTAINER_INSTANCE_TAGS={"tag_key": "tag_value"}
