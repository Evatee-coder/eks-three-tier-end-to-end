backend will need a database --> terraform RDS
---> create the db secrets credientials --> terraform

frontend will need backend --> config for backend url


# To test the DNS (dns check), then run this command

db endpoint == devopsdojo-db-service.devopsdojo.svc.cluster.local

kubectl run -it --rm --restart=Never dns-test --image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 \
-- dig devopsdojo-db-service.devopsdojo.svc.cluster.local


from the above I got the rds endpoint below which correspond to the endpoint on aws and that shows the dns mappin is working inside the cluster

devopsquiz-dev-devopsdojo.cgh22wq6k3xy.us-east-1.rds.amazonaws.com.
devopsquiz-dev-devopsdojo.cgh22wq6k3xy.us-east-1.rds.amazonaws.com.

# to troubleshoot

kubectl run debug-pod --rm -it --image=postgres -- bash

# db test

## commands that enables me to connect to my db
## from config ---> secrets----> I got the db url postgresql://postgres:password@devopsquiz-dev-devopsdojo.cgh22wq6k3xy.us-east-1.rds.amazonaws.com:5432/postgres
hostname after @ to com: devopsquiz-dev-devopsdojo.cgh22wq6k3xy.us-east-1.rds.amazonaws.com
psql -h Host


psql -h devopsquiz-dev-devopsdojo.cgh22wq6k3xy.us-east-1.rds.amazonaws.com -d postgres -U postgres

pswd: MzKn6ShpLl (before the @)

once you paste the pswd

\du

you will see the tables

now run the migration.yaml








