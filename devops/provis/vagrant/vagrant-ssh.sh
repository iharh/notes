# read http://nerderati.com/2011/03/simplify-your-life-with-an-ssh-config-file/
ssh vagrant@127.0.0.1 -p 2222 -o LogLevel=FATAL -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i /d/dev/Utils/Virtualization/Vagrant/insecure_private_key
  
