# AWS

Place your AWS credentials in docker/context/home/aws. For example:
```shell
$ cp ~/.aws/credentials docker/context/home/aws/.
```

## ECR

## CodeBuild

## EKS

Setup bash environment:
```shell
$ source bin/project-set-env.sh
```

First, build the project locally: `bin/clobber-build-and-run.sh`

Tool [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html).

Create the `rustic` cluster with:
```shell
aws-ekctl-create-cluster.sh
```

To delete it (_e.g._, because it didn't finish correctly)
```shell
eksctl delete cluster --name rustic --region eu-west-1
```

Create a better node group with:
```shell
aws-eksctl-create-nodegroup.sh
```

Delete the default node group with:
```shell
eksctl delete nodegroup --cluster rustic '<cluster-name>'
```

Setup credentials for `kubectl` with
```shell
aws eks --region eu-west-1 update-kubeconfig --name rustic
```

Check `kubectl` with:
```shell
kubectl cluster-info
```

Added namespace `rustic-test`:
```shell
kubectl apply -f kubernetes/namespace-test.yaml
```

Use namespace `rustic-test`:
```shell
kubectl config set-context --current --namespace='rustic-test'
```

List all pods:
```shell
kubectl get pods --all-namespaces -o wide
```

Install ElasticSearch:
```shell
helm repo add elasticsearch https://helm.elastic.co/
helm repo update
helm install elasticsearch --version 7.12.1 elasticsearch/elasticsearch
kubectl get pods --namespace=rustic-test -l app=elasticsearch-master -w
bin/aws-kubectl-elasticsearch-svc-apply.sh -v
```

Add permissions to create and attach EBS volumes to instances in the node group:
1. In the AWS console go to EKS > clusters > rustic > Configuration > Compute > <_the-node-group_> > Node IAM Role ARN
2. Click Attach policies
3. Search for AmazonEKS_CNI_Policy select it and click Attach policy
4. Click Add inline policy
5. Goto tge JSON tab
6. Paste the contents of "etc/aws-create-volume-policy.json" and replace ${AWS_ACCOUNT_ID} by your AWS account ID
7. Click Review policy
8. Enter the name "EC2CreateVolume" and Click Create policy

(Maybe it is necessary to recreate all nodes for the policy to take effect, but I'm not sure.)

Install the [ebs-csi driver](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html) using script `bin/aws-eks-install-ebs-csi-driver.sh`. I needed to attach role AmazonEKS_EBS_CSI_Driver_Policy to the node group after running the script.

In AWS Elastic Container Registry (ECR) create the following repositories:

* rustic/axoniq/axonserver
* rustic/dendrite2go/build-protoc
* rustic/dendrite2go/config-manager
* rustic/elasticsearch
* rustic/gcr.io/distroless/cc-debian10
* rustic/nginx
* rustic/node
* rustic/rust
* rustic/rustic-proxy
* rustic/rustic-present
* rustic/rustic-api

Then run the script `bin/aws-transfer-docker-images.sh`.

```shell
cd helm/charts
helm install axonserver ./axonserver
# This takes a while the first time, because the EBS volume must be created

helm install present ./present
helm install proxy ./proxy
helm install monolith ./monolith
cd ../..
```

Forward port 3000 at localhost to a proxy daemon in EKS:

```shell
aws-kubectl-port-forward.sh 3000 8080 $(aws-kubectl-get-pod-name.sh proxy)
```

## Test with plain vanilla Nginx

Create pod with Nginx:
```shell
helm install nginx "${PROJECT_DIR}/nginx" 
```

Setup a port-forward into the nginx pod:
```shell
POD_NAME="$(kubectl get pods -l "app.kubernetes.io/name=nginx,app.kubernetes.io/instance=nginx" -o jsonpath="{.items[0].metadata.name}")"
aws-kubectl-port-forward.sh -v -v 8077 80 --namespace rustic-test port-forward "${POD_NAME}"
```