# Ansible — Configuration Management

Idempotent configuration of the compute tier (EC2 / VMSS / MIG instances) after
Terraform provisions them. Terraform owns **infrastructure**; Ansible owns the
**in-guest state**: Docker Engine, OS hardening, CloudWatch agent.

> This is an *optional* alternative to the cloud-init user-data baked into the
> Terraform launch templates. Use one or the other — not both — for the same
> instance fleet.

## Layout

```text
ansible/
├── ansible.cfg              # sane defaults (inventory path, SSH user, retries)
├── inventory/
│   ├── hosts.ini.example    # static inventory template (copy to hosts.ini)
│   └── aws_ec2.yml.example  # dynamic inventory via AWS SSM/EC2 filters
├── playbooks/
│   └── site.yml             # entrypoint: hardening → docker → monitoring
├── group_vars/
│   └── all.yml              # shared variables (project, environment, region)
└── roles/
    ├── common/              # base packages, time sync, unattended upgrades
    ├── docker/              # Docker Engine + Compose plugin (official repo)
    ├── hardening/           # sshd config, firewall basics, auditd
    └── cloudwatch-agent/    # unified CloudWatch agent for EC2 fleets
```

## Quick start

```bash
cd ansible

# 1. Static inventory (simplest)
cp inventory/hosts.ini.example inventory/hosts.ini   # paste instance IPs/DNS
ansible all -m ping                                   # reachability check

# 2. Or dynamic inventory from AWS
cp inventory/aws_ec2.yml.example inventory/aws_ec2.yml
export AWS_REGION=ap-south-1
ansible-inventory -i inventory/aws_ec2.yml --graph
ansible-playbook -i inventory/aws_ec2.yml playbooks/site.yml
```

The playbook is fully idempotent — re-running it converges without side effects.

## Access model

Instances in this platform have **no SSH from the internet** (security groups +
SSM-only policy). Two supported paths:

1. **SSM tunnel** (recommended): `aws ssm start-session --target <id>
   --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["22"],"localPortNumber":["2222"]}'`
   then point `ansible_ssh_port=2222` at `localhost`.
2. **Bastion jump host** if you run one: set
   `ansible_ssh_common_args='-o ProxyJump=bastion'` in `group_vars/all.yml`.
