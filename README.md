# OPS-hm3
create webservers with load balance and rotating logs


Network section
create vpc and alb using modules

VPC wil create
new VPC
2 private subnet
2 public subnet
IGW
NAT GATEWAY
Routes

SG i created as resources
i didn't find a suitble module
they all seems more writing than with a resource

load balance will create and target
ALB with stickness of 1 min 


Application
after netowrk is set up 
we will run the app tf 

will create s3 bucket 
with iam role and policy 

will create 4 machines
2 WEB
2 DB  (not installed nothing there) 

provision the web to install nginx and change index.html 
also create a script that will run hourly and rotate logs
to s3 with folders sepereated by ips 

and will attach to ALB 

