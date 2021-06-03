#!/bin/bash
cd /
sudo ln -s /etc/nginx/sites-available/chatapp /etc/nginx/sites-enabled/chatapp
cd /etc/nginx/sites-available/
sudo sed -i 's+shivsingh+http://internal-InternalLoadBalancer-248206746.ap-south-1.elb.amazonaws.com+g' chatapp
sudo systemctl restart nginx
