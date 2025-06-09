# juno_k3s

your role description

## Table of content

- [Role variables](#role-variables)
- [Example playbook - online/internet-enabled installation](#example-playbook---onlineinternet-enabled-installation)
- [Example playbook - airgapped installation](#example-playbook---airgapped-installation)
- [Dependencies](#dependencies)
- [License](#license)
- [Author](#author)

---

## Role variables
| Name | Default value | Description |
|:-----|:--------------|:------------|
| k3s_airgap_install |  | ['  If true, the playbook will perform an airgapped install. Make sure all the URLs above are set to file:// or point to a local mirror.', '  When setting the URLs to file://, they will be copied from your Ansible control host to the remote hosts.'] |
| k3s_binary_url |  | ['  URL for the k3s binary. Can be http://, https:// OR file://', '  When using file://, a path from your ansible control host (where your run the playbook from) will be used.', '  The files will be copied to the remote kubernetes hosts. This is useful for airgap installs.'] |
| k3s_bootstrap_node |  | ['  The node used to bootstrap the cluster. This should only ever be a single node in your inventory!', '  The playbook example we provide discovers this dynamically, but you can also set it manually.'] |
| k3s_bootstrap_node_ip |  | ['  The IP address of an existing controlplane node, used to join the cluster.', '  In most cases, we can automatically discover this, check out the playbook example - it does that out of the box!'] |
| k3s_bootstrap_node_token |  |  |
| k3s_clusterjoin_address |  | ['The address of the cluster to join. Can only be false when k3s_bootstrap_node is true.'] |
| k3s_control_plane_node |  | ['  When true, join the node to an existing cluster as a control plane node.', '  When neither k3s_bootstrap_node nor k3s_control_plane_node is true, the node will be a worker node.'] |
| k3s_force_reinstall |  | ['  If true, rerun the k3s install script even if the node is already part of a cluster.'] |
| k3s_images_url |  | ['  URL for the k3s images tarball. Can be http://, https:// OR file://', '  When using file://, a path from your ansible control host (where your run the playbook from) will be used.', '  The files will be copied to the remote kubernetes hosts. This is useful for airgap installs.'] |
| k3s_install_script_url |  | ['  URL for the k3s install script. Can be http://, https:// OR file://', '  When using file://, a path from your ansible control host (where your run the playbook from) will be used.', '  The files will be copied to the remote kubernetes hosts. This is useful for airgap installs.'] |
| k3s_join_token |  | ['  The token used to join the cluster. You can specify it explicitly or let the playbook autodiscover it.', '  Check out the example playbook for how to do that.', 'k3s_join_token: false'] |
| k3s_registries_yaml |  | ['  If true, the playbook will configure the registries.yaml file to use your internal mirror.', '  For syntax refer to https://docs.k3s.io/installation/private-registry', '  The data you pass in here will be DIRECTLY templated into the registries.yaml file.'] |
| validate_os_version |  | ['Check we are on a supported OS version, error otherwise.'] |



# Example playbook - online/internet-enabled installation

```yaml

---
- name: Ensure the correct state of all nodes in the cluster
  hosts: all
  vars:
  tasks:
    - name: Check if the join token file exists
      ansible.builtin.stat:
        path: /var/lib/rancher/k3s/server/token
      become: true
      register: stat_k3s_bootstrap_node_token_file
    
    - any_errors_fatal: true
      block:
        - name: If the join token doesn't exist at all, bootstrap the cluster on the 1st control plane node in the inventory
          vars:
            k3s_bootstrap_node: true
          ansible.builtin.include_role:
            name: "juno-fx.juno_k3s"
          when:
            - inventory_hostname == (
                ansible_play_hosts_all
                | map('extract', hostvars)
                | selectattr('k3s_control_plane_node', 'defined')
                | selectattr('k3s_control_plane_node', 'equalto', true)
                | map(attribute='inventory_hostname')
                | list
                | first
              )
            - not stat_k3s_bootstrap_node_token_file.stat.exists
            - k3s_control_plane_node | default(false) | bool


    - name: Check if the join token file exists (again)
      ansible.builtin.stat:
        path: /var/lib/rancher/k3s/server/token
      become: true
      register: stat_k3s_bootstrap_node_token_file

    - name: If the join token file exists across any of the control plane nodes, set the variable
      become: true
      ansible.builtin.slurp:
        src: /var/lib/rancher/k3s/server/token
      when: stat_k3s_bootstrap_node_token_file.stat.exists
      register: slurp_k3s_bootstrap_node_token_file
      run_once: true

    - name: Make the variable available to the play
      ansible.builtin.set_fact:
        k3s_bootstrap_node_token: "{{ slurp_k3s_bootstrap_node_token_file.content | b64decode }}"
        k3s_bootstrap_node_ip: "{{ ansible_default_ipv4.address }}"
      when: stat_k3s_bootstrap_node_token_file.stat.exists
      loop: "{{ ansible_play_hosts }}"
      run_once: true
      delegate_to: "{{ item }}"
    - name: Gather service facts on the control plane nodes
      ansible.builtin.service_facts:
      when: k3s_control_plane_node | default(false) | bool

    - name: Ensure k3s control plane nodes
      vars:
        k3s_join_token: "{{ k3s_bootstrap_node_token }}"
      when:
        - k3s_control_plane_node | default(false) | bool
      ansible.builtin.include_role:
        name: "juno-fx.juno_k3s"

    - name: Ensure k3s worker nodes
      vars:
        k3s_join_token: "{{ k3s_bootstrap_node_token }}"
      when:
        - not k3s_control_plane_node | default(false) | bool
      ansible.builtin.include_role:
        name: "juno-fx.juno_k3s"
```
# Example playbook - airgapped installation

The below playbook assumes you have downloaded all the necessary files listed in `vars:` and passed in the paths to them.
You can check the detailed information for each file in the vars section above.


```yaml

---
- name: Ensure the correct state of all nodes in the cluster
  hosts: all
  vars:
    k3s_install_script_url: "file://{{ playbook_dir }}/airgap_files/install.sh"
    k3s_binary_url: "file://{{ playbook_dir }}/airgap_files/k3s"
    k3s_images_url: "file://{{ playbook_dir }}/airgap_files/k3s-airgap-images-amd64.tar.zst"
    k3s_airgap_install: true
  tasks:
    - name: Check if the join token file exists
      ansible.builtin.stat:
        path: /var/lib/rancher/k3s/server/token
      become: true
      register: stat_k3s_bootstrap_node_token_file

    - any_errors_fatal: true
      block:
        - name: If the join token doesn't exist at all, bootstrap the cluster on the 1st control plane node in the inventory
          vars:
            k3s_bootstrap_node: true
          ansible.builtin.include_role:
            name: "juno-fx.juno_k3s"
          when:
            - inventory_hostname == (ansible_play_hosts | selectattr('k3s_control_plane_node', 'defined') | selectattr('k3s_control_plane_node', 'equalto', true) | first).inventory_hostname
            - not stat_k3s_bootstrap_node_token_file.stat.exists
            - k3s_control_plane_node | default(false) | bool

    - name: Check if the join token file exists (again)
      ansible.builtin.stat:
        path: /var/lib/rancher/k3s/server/token
      become: true
      register: stat_k3s_bootstrap_node_token_file

    - name: If the join token file exists across any of the control plane nodes, set the variable
      become: true
      ansible.builtin.slurp:
        src: /var/lib/rancher/k3s/server/token
      when: stat_k3s_bootstrap_node_token_file.stat.exists
      register: slurp_k3s_bootstrap_node_token_file
      run_once: true

    - name: Make the variable available to the play
      ansible.builtin.set_fact:
        k3s_bootstrap_node_token: "{{ slurp_k3s_bootstrap_node_token_file.content | b64decode }}"
        k3s_bootstrap_node_ip: "{{ ansible_default_ipv4.address }}"
      when: stat_k3s_bootstrap_node_token_file.stat.exists
      loop: "{{ ansible_play_hosts }}"
      run_once: true
      delegate_to: "{{ item }}"
    - name: Gather service facts on the control plane nodes
      ansible.builtin.service_facts:
      when: k3s_control_plane_node | default(false) | bool

    - name: Ensure k3s control plane nodes
      vars:
        k3s_join_token: "{{ k3s_bootstrap_node_token }}"
      when:
        - k3s_control_plane_node | default(false) | bool
      ansible.builtin.include_role:
        name: "juno-fx.juno_k3s"

    - name: Ensure k3s worker nodes
      vars:
        k3s_join_token: "{{ k3s_bootstrap_node_token }}"
      when:
        - not k3s_control_plane_node | default(false) | bool
      ansible.builtin.include_role:
        name: "juno-fx.juno_k3s"

```


## Dependencies

None.

## License

Apache-2.0

## Author

Juno Innovations


# Development workflow

This repository comes in with a Makefile providing targets for testing & linting the role.

For usage examples see: [CONTRIBUTING.md](CONTRIBUTING.md)