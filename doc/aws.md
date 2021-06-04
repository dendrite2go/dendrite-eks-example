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
```

Add permissions to create and attach EBS volumes to instances in the node group:
1. In the AWS console go to EKS > clusters > rustic > Configuration > Compute > <_the node group_> > Node IAM Role ARN
2. Click Attach policies
3. Search for AmazonEKS_CNI_Policy select it and click Attack policy
4. Click Add inline policy
5. Goto tge JSON tab
6. Paste the contents of "etc/aws-create-volume-policy.json" and replace ${AWS_ACCOUNT_ID} by your AWS account ID
7. Click Review policy
8. Enter the name "EC2CreateVolume" and Click Create policy

Create pod with Nginx:
```shell
helm install nginx "${PROJECT_DIR}/nginx" 
```

Setup a port-forward into the nginx pod:
```shell
POD_NAME="$(kubectl get pods -l "app.kubernetes.io/name=nginx,app.kubernetes.io/instance=nginx" -o jsonpath="{.items[0].metadata.name}")"
aws-kubectl-port-forward.sh -v -v 8077 80 --namespace rustic-test port-forward "${POD_NAME}"
```