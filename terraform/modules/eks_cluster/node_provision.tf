locals {
  join_script = <<SCRIPT
  sudo /etc/eks/bootstrap.sh \
    --apiserver-endpoint '${aws_eks_cluster.demo.endpoint}' \
    --b64-cluster-ca '${aws_eks_cluster.demo.certificate_authority[0].data}' '${local.cluster_name}'
  SCRIPT
}

resource "null_resource" "cluster_join" {
  count = var.node_count

  triggers = {
    node_id = aws_instance.node[count.index].id
  }

  connection {
    user        = "ec2-user" # default user for the ami
    host        = aws_instance.node[count.index].public_ip
    private_key = tls_private_key.node_key_pair[count.index].private_key_pem
  }

  # Join the Kubernetes cluster.
  provisioner "remote-exec" {
    inline = [local.join_script]
  }
}
