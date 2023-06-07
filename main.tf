locals {
  roles = [{
    rolearn  = var.nodes_role
    username = "system:node:{{EC2PrivateDNSName}}"
    groups = [
      "system:bootstrappers",
      "system:nodes"
    ]
  }]

  master_roles = [
    for role_arn in var.master_roles :
    {
      rolearn  = role_arn
      username = role_arn
      groups = [
        "system:masters"
      ]
    }

  ]

  users = [
    for user_obj in var.master_users :
    {
      userarn  = user_obj.arn
      username = user_obj.username
      groups = [
        "system:masters"
      ]
    }
  ]
}
    
resource "kubernetes_config_map" "aws_auth" {
  
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(concat(local.roles, local.master_roles))
    mapUsers = yamlencode(local.users)
  }
  
  lifecycle {
    # We are ignoring the data here since we will manage it with the resource below
    # This is only intended to be used in scenarios where the configmap does not exist
    ignore_changes = [data, metadata[0].labels, metadata[0].annotations]
  }
}
    
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    // The name of the ConfigMap needs to be `aws-auth`, as specified by AWS. 
    // For more info, please see here: https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
    name      = "aws-auth"
    namespace = "kube-system"
  }

  force = true 
  
  data = {
    mapRoles = yamlencode(concat(local.roles, local.master_roles))
    mapUsers = yamlencode(local.users)
  }
  
  depends_on = [
    # Required for instances where the configmap does not exist yet to avoid race condition
    kubernetes_config_map.aws_auth,
  ]
}
