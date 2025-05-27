.PHONY: docs

debian12_AMI = ami-02da2f5b47450f5a8
ubuntu22_AMI = ami-04f167a56786e4b09
rocky95_AMI = ami-05150ea4d8a533099

export AWS_VPC_SUBNET_ID ?= subnet-090d8a0ac7e70b207
export AWS_REGION ?= us-east-2
export AWS_INSTANCE_TYPE ?= t2.large

venv/bin/activate:
	python3 -m venv venv
	. venv/bin/activate; pip install -r requirements.txt
	. venv/bin/activate; ansible-galaxy install -r test_requirements.yml

docs: venv/bin/activate
	venv/bin/ansible-doctor

login: venv/bin/activate
	. venv/bin/activate; venv/bin/molecule login

converge-%: venv/bin/activate
	. venv/bin/activate; AWS_AMI_ID=${$*_AMI} venv/bin/molecule -vvv converge -s ec2

test-%: venv/bin/activate
	. venv/bin/activate; AWS_AMI_ID=${$*_AMI} venv/bin/molecule -vvv test -s ec2

destroy-%: venv/bin/activate
	. venv/bin/activate; AWS_AMI_ID=${$*_AMI} venv/bin/molecule -vvv destroy -s ec2


#tab autocomplete
converge-debian12: converge-debian12
converge-ubuntu22: converge-ubuntu22
converge-rocky95: converge-rocky95
test-debian12: test-debian12
test-ubuntu22: test-ubuntu22
test-rocky95: test-rocky95
destroy-debian12: destroy-debian12
destroy-ubuntu22: destroy-ubuntu22
destroy-rocky95: destroy-rocky95
