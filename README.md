# [stackfeed/k8s-ops](https://hub.docker.com/r/stackfeed/k8s-ops/) cloud tools docker image

Docker image which bundles cloud automation software used for operating kubernetes. Apart from that the container bundles lots of useful tools to provide you a ready-to-go container workstation without need to install anything on your host machine.

## Tools

List of software bundled into this container:

* [Terraform](https://www.terraform.io/) - infrastructure managment which works with almost any cloud provider
* [Terragrunt](https://github.com/gruntwork-io/terragrunt) - a thin terraform wrapper-tool which meant to make experience smoother when working with multiple terraform stages and environments
* [KOPS](https://github.com/kubernetes/kops) - the easiest way to get a production grade Kubernetes cluster up and running
* [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) - kubernetes CLI tool
* [Helm](https://helm.sh/) - the package manager for Kubernetes
* [Helmfile](https://github.com/roboll/helmfile) - is a declarative spec for deploying helm charts
* [AWS CLI](https://aws.amazon.com/cli/) - AWS CLI tool (*available in AWS container flavour*)
* [Heptio Ark](https://github.com/heptio/ark) - is an utility for managing disaster recovery, specifically for your Kubernetes cluster resources and persistent volumes (*available in AWS container flavour*).

## Container environment

| Name | Description | Default |
|------|-------------|:----:|
| ZSH_THEME | Zsh theme to use. | `cloud` |
| ZSH_PLUGINS | Zsh plugins enabled. | `aws helm kops kubectl terraform` |
| HELM_FORCE_TLS | Specify y/yes/enabled/enable/true to force Helm `--tls` option. | `no` |

## k8s-ops for AWS

[![](https://images.microbadger.com/badges/version/stackfeed/k8s-ops:aws.svg)](https://microbadger.com/images/stackfeed/k8s-ops:aws "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/stackfeed/k8s-ops:aws.svg)](https://microbadger.com/images/stackfeed/k8s-ops:aws "Get your own image badge on microbadger.com")

## Usage

This container uses [fixuid](https://github.com/boxboat/fixuid) a go binary to change Docker container user/group and file permissions at runtime. That's why **it's recommended to run as unprivileged user matching your host UID, GID**.

Typical workstation container initialization looks like:

```bash
docker run -ti --name myproject -u $(id -u):$(id -g) -v /some/path:/code -w /code stackfeed/k8s-ops:aws
```

Here above we create a container and name it `myproject`, provide UID/GID of the host system and also we can pass any volumes which might be required.


### Stopping/starting the k8s-ops tools container


```bash
docker stop myproject
docker start myproject
```

### Getting the console

To get any number of consoles running you can simply exec into the running container as simple as this:

```bash
docker exec -ti myproject zsh
```

also **note that** if you want to get **fancy colors and proper terminal width and height** you have to enhance the docker exec by providing additional options:

```bash
docker exec -ti --env COLUMNS=`tput cols` --env LINES=`tput lines` myproject zsh
```

But better make yourself an alias: `alias deti="docker exec -ti --env COLUMNS=`tput cols` --env LINES=`tput lines`"`

### Volumes

Here are a few best practices. When working on the workstation almost any application makes use of the home directory. Tools bundled into this container are no exception, for example kubectl uses `~/.kube` directory and helm uses `~/.helm`.

**_In case if you recreate container to update the tools all the configuration will be lost!_**

That's why the first rule is to always pre-createa a volume for the container user home. The second rule is not to forget to pass volumes with the code.

### Best practice example

```bash
# create volume to store home directory files
docker volume create myproject-home

# we admit that the code we work with is in ~/code, so we keep this in when we initiate the container
docker run -ti  --name myproject --hostname myproject \
  -u $(id -u):$(id -g) \
  -v myproject-home:/home/fixuid \
  -v ~/code:/home/fixuid/code \
  stackfeed/k8s-ops:aws

# create container with CAP_NET_ADMIN privilege to enable iptables usage
docker run -ti --name myproject --hostname myproject \
  --cap-add=NET_ADMIN \
  -u $(id -u):$(id -g) \
  -v myproject-home:/home/fixuid \
  -v ~/code:/home/fixuid/code \
  stackfeed/k8s-ops:aws
```

#### MacOS

There are known issues with volumes when running the container on MacOS. It's recommended not to use volumes!

```bash
mkdir myproject-home

# we admit that the code we work with is in ~/code, so we keep this in when we initiate the container
docker run -ti  --name myproject --hostname myproject \
  -u $(id -u):$(id -g) \
  -v $(pwd)/myproject-home:/home/fixuid \
  -v ~/code:/home/fixuid/code \
  stackfeed/k8s-ops:aws
```

#### Forcing TLS on KOPS environments

```bash
docker run -ti --name myproject --hostname myproject \
  --cap-add=NET_ADMIN \
  --env HELM_FORCE_TLS=yes \
  ...
```
