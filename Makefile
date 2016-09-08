all: push

# 0.0 shouldn't clobber any released builds
TAG = 0.4.4
PREFIX = thehumaneffort/kube-haproxy-lb
HAPROXY_IMAGE = contrib-haproxy

builder: .builder
	docker build -t golang_godep -f Dockerfile.build .
	touch .builder

build: service_loadbalancer.go
	CGO_ENABLED=0 GOOS=linux godep go build -v -a -installsuffix cgo -ldflags '-w' -o service_loadbalancer ./service_loadbalancer.go ./loadbalancer_log.go

service_loadbalancer: service_loadbalancer.go
	docker run --rm --volume $(shell pwd):/go/app golang_godep bash -c 'cd /go/app && make build'

container: service_loadbalancer FORCE
	docker build -t $(PREFIX):$(TAG) .

push: container
	gcloud docker push $(PREFIX):$(TAG)

clean:
	# remove servicelb and contrib-haproxy images
	docker rmi -f $(HAPROXY_IMAGE):$(TAG) || true
	docker rmi -f $(PREFIX):$(TAG) || true
	rm .builder

datadog:
	docker build -t us.gcr.io/kubetest-1319/haproxy-datadog:latest -f Dockerfile-datadog .
	gcloud docker push us.gcr.io/kubetest-1319/haproxy-datadog:latest


FORCE:
