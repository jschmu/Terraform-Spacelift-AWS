resource "aws_key_pair" "tsa_auth" {
  key_name   = "tsakey"
  public_key = file("/mnt/workspace/tsakey.pub") #for spacelift deployment
  #public_key = file("../tsakey.pub") #for local testing without pushing to repository
}

resource "aws_instance" "dev_node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.tsa_auth.key_name
  vpc_security_group_ids = var.security_group_id
  subnet_id              = var.subnet_id
  user_data              = file("${path.module}/userdata.tpl")
  tags = {
    Name = "dev_node"
  }

  #provisioner is not used when running in Spacelift
  # provisioner "local-exec" {
  # command = templatefile("${var.host_os}-ssh-config.tpl", {
  #   hostname = self.public_ip,
  #   user = "ubuntu",
  #   identityfile = "C:/Users/schmu/.ssh/mtckey"})
  #   interpreter = var.host_os == "windows" ? ["PowerShell", "-Command"] : ["Bash", "-c"]
  # }
}