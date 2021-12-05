# cross-impact-balances


# devbase

This is a repository for python testing purposes. The Dockerfile is based on an python image, installs the requirements and runs a jupyter-lab server.
It also contains a deployment script that can be used to host the container as a pod in a kubernetes environment (e.g. Minikube).

Currently the image is maintained and hosted on dockerhub: [leventlukas/devbase](https://hub.docker.com/repository/docker/leventlukas/devbase).

# Running and accessing the jupyter-lab server
There are two ways to run and access the jupyter-lab server:
    
1. Running the image and access container directly
2. Applying the k8s deployment script

## Running the image and access container directly
The most current image is version 0.3.3. Make sure to pull the most recent image or build and tag the image yourself.

```shell
docker pull leventlukas/devbase:0.3.3
docker build -t leventlukas/devbase:0.3.3 .
```

In the [Dockerfile](https://github.com/leventlukas/devbase/blob/4797289257f72fd15ad5f6f647de52cd19ba3672/Dockerfile#L12) you can see that the jupyter server is started on 0.0.0.0:8404.

Therefore, when running the container, make sure to publish the ports to the host's localhost and a arbitrary port.

```shell
docker run -d -p 0.0.0.0:8888:8404 --name devbase leventlukas/devbase:0.3.3
```

Verify that the container is running and exposes the correct port.

```shell
CONTAINER ID        IMAGE                       COMMAND                  CREATED             STATUS              PORTS                    NAMES
6dee0a2b34e2        leventlukas/devbase:0.3.3   "/bin/sh -c 'jupyter…"   9 minutes ago       Up 4 seconds        0.0.0.0:8888->8404/tcp   devbase
```
You can now access through ip:port that you assigned.
However you'll see as usual you'll need to access using a token. To retrieve the url with token execute the following cmd.

```shell
docker exec -it devbase jupyter notebook list
Currently running servers:
http://0.0.0.0:8404/?token=c48a3d43ea92ae06dadc6a97e9298c4fcef28ac3545f1f49 :: /usr/src/app
```
If you chose to use expose the port 8404 you can open the lab server by clicking on the url, otherwise open 0.0.0.0 at the specified port and paste the token.
## Applying the k8s deployment script

The devbase kubernetes deplyoment leverages kubernetes secrets as files. Any sensitive information can be stored as a secret. For the deployment to work you will first have to create the secret general-purpose-secret.

```shell
kubectl create secret generic general-purpose-secret \
--from-literal="Username=leventlukas" \
--from-literal="Password=123456"
secret/general-purpose-secret created
```

The secret is stored in kubernetes and can be accessed through the mounted volume /mnt/secret from within the pod.
Verify that the secret was created.

```shell
NAME                       TYPE                                  DATA   AGE
general-purpose-secret     Opaque                                3      7m35s
```

To edit the secret as in vi run the following command. Note that the secrets are stored under data as key value pairs, where the value has been hashed:

```shell
kubectl edit secret general-purpose-secret
```

```yaml
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
data:
  Password: MTIzNDU2
  Username: bGV2ZW50bHVrYXM=
kind: Secret
metadata:
  creationTimestamp: "2020-11-28T19:44:27Z"
  name: general-purpose-secret
  namespace: default
  resourceVersion: "244247"
  selfLink: /api/v1/namespaces/default/secrets/general-purpose-secret
```

Finally, to deploy service and deployment apply the [devbase_deployment.yaml](https://github.com/leventlukas/devbase/blob/master/devbase_deployment.yaml) from the root of this repository.

```shell
kubectl apply -f devbase_deployment.yaml 
deployment.apps/devbase-deployment created
service/davebase-service created
```

You can see that the service and the deployment are separate constructs. To verify the installation for each, run the following.

```shell
kubectl get pod
NAME                                  READY   STATUS    RESTARTS   AGE
devbase-deployment-84f7964b48-wmmcj   1/1     Running   0          4m14s

kubectl get service
NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
davebase-service   NodePort    10.109.218.187   <none>        8402:30000/TCP   4m36s
kubernetes         ClusterIP   10.96.0.1        <none>        443/TCP          4d5h
```

The jupyter-lab server should now be reachable at 0.0.0.0:30000. However, as with the docker deployment, you will need the token. The token can be retrieved using a similar approach as with to container deployment.

```shell
kubectl exec -it devbase-deployment-84f7964b48-wmmcj -- jupyter notebook list
Currently running servers:
http://0.0.0.0:8404/?token=f715b62612ffac1114b37dc8848d0b89a9681e1e525b0a28 :: /usr/src/app
```


# How it works (k8s)
