.PHONY: docs

debian12_AMI = ami-02da2f5b47450f5a8
ubuntu22_AMI = ami-0b05d988257befbbe
ubuntu24_AMI = ami-0d1b5a8c13042c939
rocky95_AMI = ami-05150ea4d8a533099

export AWS_VPC_SUBNET_ID ?= subnet-090d8a0ac7e70b207
export AWS_REGION ?= us-east-2
export AWS_INSTANCE_TYPE ?= t2.large

venv/bin/activate:
	python3 -m venv venv
	. venv/bin/activate; python3 -m pip install -r requirements.txt
	. venv/bin/activate; ansible-galaxy install -r test_requirements.yml

docs: venv/bin/activate
	# the filters available to us in ansible-doctor doesn't cut it for escaping Jinja in the molecule spec.
	cp molecule/ec2/converge.yml docs/readme/molecule_converge_online_escaped.yml
	cp molecule/ec2-airgap/converge.yml docs/readme/molecule_converge_airgapped_escaped.yml
	# escape all jinja by injecting raw blocks at beginning and end of each file
	sed -i '1s/^/{% raw %}\n/' docs/readme/molecule_converge_online_escaped.yml
	sed -i '$$a{% endraw %}' docs/readme/molecule_converge_online_escaped.yml
	sed -i '1s/^/{% raw %}\n/' docs/readme/molecule_converge_airgapped_escaped.yml
	sed -i '$$a{% endraw %}' docs/readme/molecule_converge_airgapped_escaped.yml
	sed -i '/### BEGIN-TEST-ONLY ###/,/### END-TEST-ONLY ###/d' docs/readme/molecule_converge_online_escaped.yml
	sed -i '/### BEGIN-TEST-ONLY ###/,/### END-TEST-ONLY ###/d' docs/readme/molecule_converge_airgapped_escaped.yml
	ansible-doctor

login-%: venv/bin/activate
	. venv/bin/activate; venv/bin/molecule login -s ec2 --host k8s_${*}

login-airgap-%: venv/bin/activate
	. venv/bin/activate; venv/bin/molecule login -s ec2-airgap --host k8s_${*}

login-airgap-proxy: venv/bin/activate
	. venv/bin/activate; venv/bin/molecule login -s ec2-airgap --host airgap_proxy

converge-airgap-%: venv/bin/activate
	. venv/bin/activate; AWS_AMI_ID=${$*_AMI} venv/bin/molecule converge -s ec2-airgap

prepare-airgap-%: venv/bin/activate
	. venv/bin/activate; AWS_AMI_ID=${$*_AMI} venv/bin/molecule prepare -f -s ec2-airgap

test-airgap-%: venv/bin/activate
	. venv/bin/activate; AWS_AMI_ID=${$*_AMI} venv/bin/molecule test -s ec2-airgap

destroy-airgap-%: venv/bin/activate
	. venv/bin/activate; AWS_AMI_ID=${$*_AMI} venv/bin/molecule destroy -s ec2-airgap

converge-%: venv/bin/activate
	. venv/bin/activate; AWS_AMI_ID=${$*_AMI} venv/bin/molecule converge -s ec2

test-%: venv/bin/activate
	. venv/bin/activate; AWS_AMI_ID=${$*_AMI} venv/bin/molecule test -s ec2

destroy-%: venv/bin/activate
	. venv/bin/activate; AWS_AMI_ID=${$*_AMI} venv/bin/molecule destroy -s ec2


#tab autocomplete
converge-airgap-debian12: converge-airgap-debian12
converge-airgap-ubuntu22: converge-airgap-ubuntu22
converge-airgap-ubuntu24: converge-airgap-ubuntu24
converge-airgap-rocky95: converge-airgap-rocky95
test-airgap-debian12: test-airgap-debian12
test-airgap-ubuntu22: test-airgap-ubuntu22
test-airgap-ubuntu24: test-airgap-ubuntu24
test-airgap-rocky95: test-airgap-rocky95
destroy-airgap-debian12: destroy-airgap-debian12
destroy-airgap-ubuntu22: destroy-airgap-ubuntu22
destroy-airgap-ubuntu24: destroy-airgap-ubuntu24
destroy-airgap-rocky95: destroy-airgap-rocky95
converge-debian12: converge-debian12
converge-ubuntu22: converge-ubuntu22
converge-ubuntu24: converge-ubuntu24
converge-rocky95: converge-rocky95
test-debian12: test-debian12
test-ubuntu22: test-ubuntu22
test-ubuntu24: test-ubuntu24
test-rocky95: test-rocky95
destroy-debian12: destroy-debian12
destroy-ubuntu22: destroy-ubuntu22
destroy-ubuntu24: destroy-ubuntu24
destroy-rocky95: destroy-rocky95
login-control_plane01: login-control_plane01
login-control_plane02: login-control_plane02
login-control_plane03: login-control_plane03
login-worker01: login-worker01
login-airgap-control_plane01: login-airgap-control_plane01
login-airgap-control_plane02: login-airgap-control_plane02
login-airgap-control_plane03: login-airgap-control_plane03
login-airgap-worker01: login-airgap-worker01
