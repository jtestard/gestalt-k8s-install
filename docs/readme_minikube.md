# Quick Start for Minikube (on MacOS)

Recommend 4 CPUs and 8GB memory for the minikube cluster.

### Option 1 - Install Minikube with virtual-box VM driver
```sh
brew cask install minikube

minikube start --memory 8192 --cpus 4 --vm-driver virtualbox

```


### Option 2 - Install Minikube with xhyve VM driver

```sh
brew cask install minikube

brew install docker-machine-driver-xhyve

# docker-machine-driver-xhyve need root owner and uid
sudo chown root:wheel $(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
sudo chmod u+s $(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve

minikube start --memory 8192 --cpus 4 --vm-driver xhyve
```

### Install Gestalt Platform on a Running Minikube Cluster

```sh
# Ensure kubectl is pointing to minikube
kubectl config current-context   # should report 'minikube'

# Check that kubernetes is up
minikube dashboard

# Enable ingress
minikube addons enable ingress

# Install helm on the cluster
helm init

# Create Gestalt namespace
kubectl create namespace gestalt-system

# Run the Gestalt Platform installer
./install-gestalt-platform minikube.conf

```
