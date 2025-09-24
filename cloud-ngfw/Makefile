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

clean-rules:
	cd rules && \
		terraform plan -destroy -out p1 && \
		terraform apply p1
	-rm .state.rules

#clean: $(call if_exist,.state.tgw,clean-sec) $(call if_exist,.state.sec,clean-tgw) $(call if_exist,.state.rule,clean-rules)
clean: $(call clean-sec) $(call clean-tgw) $(call clean-rules)
	true

.state.tfinit:
	for p in rules commit sec-routing tgw-ngfw; do \
		echo ===== $$p; \
		(cd $$p; terraform init -upgrade); \
		echo ===; \
		done
	$(touch) $@

.state.rules:
	cd rules && \
		terraform plan -out p1 && \
		terraform apply p1
	$(touch) $@

.state.tgw:
	cd tgw-ngfw && \
		terraform plan -out p1 && \
		terraform apply p1
	$(touch) $@

.state.vpce: .state.tgw
	cd tgw-ngfw && \
		vpcid=$$(terraform show -json | jq -r '.values.outputs."vpc-sec".value.vpc.id') && \
		region=$$(terraform show -json | jq -r '.values.outputs.region.value') && \
		echo $$vpcid $$region && \
		cd ~/prog/ce-aws/tgw/ && \
		uv run gwlbe.py --region $$region --vpc $$vpcid vpce-wait
	$(touch) $@

.state.sec: .state.vpce
	cd sec-routing && \
		terraform plan -out p1 && \
		terraform apply p1
	$(touch) $@

all: .state.tfinit .state.rules .state.sec

commit:
	cd rules && \
		terraform plan -out p1 && \
		terraform apply p1
	cd commit && \
		terraform plan -out p1 && \
		terraform apply p1

refresh:
	cd sec-routing && \
		terraform refresh
	cd tgw-ngfw && \
		terraform refresh
	
update-terraform:
	for p in rules commit sec-routing tgw-ngfw; do \
		echo ===== $$p; \
		(cd $$p; terraform init -upgrade); \
		echo ===; \
		done
