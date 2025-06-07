# juno_k3s

your role description

## Table of content

- [Role variables](#role-variables)
- [Dependencies](#dependencies)
- [License](#license)
- [Author](#author)

---

## Role variables
| Name | Default value | Description |
|:-----|:--------------|:------------|
| k3s_airgap_install |  |  |
| k3s_binary_url |  | ['URL for the k3s binary. Can be https:// OR file://'] |
| k3s_bootstrap_node |  | ['The node used to bootstrap the cluster. This should only ever be a single node in your inventory!'] |
| k3s_images_url |  |  |
| k3s_install_script_url |  |  |
| my_var |  | ['This is my description'] |
| validate_os_version |  | ['Check we are on a supported OS version, error otherwise.'] |



## Dependencies

None.

## License

Apache-2.0

## Author

Juno Innovations


# Example playbook

```yaml
---
- name: Ensure the correct state of the bootstrap node
  groups: control_plane_bootstrap
  vars:
    k3s_bootstrap_node: true
  tasks:
    - name: Assert we only have one bootstrap node
      ansible.builtin.assert:
        that:
          - ansible_play_hosts | length == 1
        msg: "There should only be one bootstrap node in the control_plane group!!"
    - name: "Include juno_k3s"
      ansible.builtin.include_role:
        name: "juno-fx.juno_k3s"

- name: Ensure the correct state of the control plane nodes
  hosts: control_plane
  tasks:
    - name: "Include juno_k3s"
      ansible.builtin.include_role:
        name: "juno-fx.juno_k3s"

- name: Ensure the correct state of the worker nodes
  hosts: worker
  tasks:
    - name: "Include juno_k3s"
      ansible.builtin.include_role:
        name: "juno-fx.juno_k3s"
```
# Development workflow

This repository comes in with a Makefile providing targets for testing & linting the role.

For usage examples see: [CONTRIBUTING.md](CONTRIBUTING.md)
