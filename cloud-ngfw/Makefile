touch = touch -r .base.date

.PHONY: clean clean-sec clean-tgw commit
if_exist = $(shell if [ -e $(1) ]; then echo $(2); fi)
if_not_exist = $(shell if [! -e $(1) ]; then echo $(2); fi)

clean-tgw:
	cd tgw-ngfw && \
		terraform plan -destroy -out p1 && \
		terraform apply p1
	-rm .state.sec
	-rm .state.vpce

clean-sec:
	cd sec-routing && \
		terraform plan -destroy -out p1 && \
		terraform apply p1
	-rm .state.tgw

clean: $(call if_exist,.state.sec,clean-tgw) $(call if_exist,.state.tgw,clean-sec)
	true

.state.tgw:
	cd tgw-ngfw && \
		terraform plan -out p1 && \
		terraform apply p1
	$(touch) $@

.state.vpce: .state.tgw
	cd ~/prog/ce-aws/cloud-ngfw/tgw-ngfw/ && \
		vpcid=$$(terraform show -json | jq -r '.values.outputs."vpc-sec".value.vpc.id') && \
		region=$$(terraform show -json | jq -r '.values.outputs.region.value') && \
		echo $$vpcid $$region && \
		cd ~/prog/ce-aws/tgw/ && \
		python3 gwlbe.py --region $$region --vpc $$vpcid vpce-wait
	$(touch) $@

.state.sec: .state.vpce
	cd sec-routing && \
		terraform plan -out p1 && \
		terraform apply p1
	$(touch) $@

all: .state.sec

commit:
	cd rules && \
		terraform plan -out p1 && \
		terraform apply p1
	cd commit && \
		terraform plan -out p1 && \
		terraform apply p1
	
