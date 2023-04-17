# TechOps playground

> If you would keep a secret from an enemy, tell it not to a friend. ;)

For all the ingress to work, add the following entries to your host file

```
127.0.0.1       argocd.localhost
127.0.0.1       prometheus.localhost
127.0.0.1       grafana.localhost
127.0.0.1       alertmanager.localhost
127.0.0.1       argo.localhost
127.0.0.1       gitea.localhost
127.0.0.1       events.localhost
```

Install [asdf](https://asdf-vm.com/guide/getting-started.html#_3-install-asdf) and then all tools:

```sh
asdf plugin add kind
asdf plugin add helm
asdf plugin add argo
asdf plugin add argocd
asdf install
```

To create the cluster:

```sh
./create_cluster.sh
```

To install all softs:

```sh
# Install all helm charts
./apply
```

To delete a cluster:

```sh
./delete_cluster.sh
```
