# [stackfeed/toolbox](https://hub.docker.com/r/stackfeed/toolbox/) cloud tools docker image

Docker image which bundles cloud automation software used by stackfeed projects and aims to make interaction with your cloud environment more delightful. *Finally it helps to keep your workstation CLEAN and DRY*😜

## Usage

The container is meant to be used with privileges of the "target" user (which is you at your workstation). This will make your experience smoother because you can map volumes with your files, create directories and files in the container and permissions of those can be on par with your host system. So **do not skip** important *Build dependent container* section.

##  AWS toolbox

 [![](https://images.microbadger.com/badges/version/stackfeed/toolbox:aws.svg)](https://microbadger.com/images/stackfeed/toolbox:aws "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/stackfeed/toolbox:aws.svg)](https://microbadger.com/images/stackfeed/toolbox:aws "Get your own image badge on microbadger.com")

AWS toolbox contains the following cloud automation tools:

* Terraform **0.11.7**
* Terragrunt **0.16.13**
* kops **1.9.2**
* helm **2.9.1**
* awscli (*latest at the time of build*)


### Build dependent container (pass the desired build arguments)

```
# Provide host UID and GID for the build
_USER=$(id -un)
_UID=$(id -u)
_GID=$(id -g)

mkdir -p /tmp/stackfeed-toolbox && cd /tmp/stackfeed-toolbox
echo "FROM stackfeed/toolbox:aws" > Dockerfile

docker build --no-cache -t stackbox:aws \
             --build-arg _USER=${_USER} \
             --build-arg _UID=${_UID} \
             --build-arg _GID=${_GID} .

cd - && rm -rf /tmp/stackfeed-toolbox
```

### Using toolbox container


```
# change to your terraform/kops/k8s project directory!
cd /path/to/my/project

# initiating container with name and hostname set to myproject
docker run -it --name myproject -h myproject -v $(pwd):/code stackbox:aws

# starting and attaching:
docker start myproject
docker attach myproject

# exec another shell process in the container
docker exec -it myproject bash
```

## Notes

### Toolbox volumes

When running the toolbox container we specify the **code** volume it's used to pass your project code into the toolbox container. Also the `/code` directory is set as the WORKDIR for convenience.

You may also want to pass other volumes into the container if required. Though **it's not suggested** to map volume to `/home/YOUR_USER`, since the user's home directory is already available inside the container.

### User's homedir initialization

Homedir specific for your user is created during the image build. There are also a few important steps which happen on build or container startup you should know about:

 1. [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh) is installed and configured on image build.
 2. _**`.aws, .hube, .kube, .ssh`**_ are linked into user's homedir in case they present in the *`/code`* volume, this is fired from the entrypoint.
