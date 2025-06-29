# juno_k3s

A role deploying k3s&bootstrapping [Juno Innovations Orion](https://www.juno-innovations.com/)
Supporting both airgapped and online environments


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
| argo_install_manifest_url | https://raw.githubusercontent.com/argoproj/argo-cd/v3.0.9/manifests/install.yaml |  The URL of the ArgoCD install manifest. This can be a file://, http:// or https:// URL.  If you use file://, the file will be copied from your Ansible control host to the remote hosts. |
| juno_bootstrap_chart_repo_revision | main |  The revision of the Juno-Bootstrap repository to use. This can be a branch name, tag or commit hash. |
| juno_bootstrap_chart_values | {} |  Values to pass to the Juno Bootstrap chart. See: https://github.com/juno-fx/Juno-Bootstrap If you do not use a direct OCI proxy and leverage the k3s_registries_yaml var, you also could need to adjust the repository from which to pull images. For details, see: https://github.com/juno-fx/Juno-Bootstrap and the example airgapped playbook. |
| juno_bootstrap_git_password | {{ juno_git_password }} | This authenticates only the Juno-Bootstrap repository. You can leave it unchanged if both Juno-Bootstrap and Genesis-Deployment are accessible via juno_git_username&juno_git_password. |
| juno_bootstrap_git_url | https://github.com/juno-fx/Juno-Bootstrap.git |  The URL of the Juno-Bootstrap repository. This only needs to be adjusted if you forked it or are using an airgapped environment. |
| juno_bootstrap_git_username | {{ juno_git_username }} |  This authenticates only the Juno-Bootstrap repository. You can leave it unchanged if both Juno-Bootstrap and Genesis-Deployment are accessible via juno_git_username&juno_git_password. |
| juno_genesis_deployment_git_password | {{ juno_git_password }} |  This authenticates only the Juno Genesis Deployment repository. You can leave it unchanged if |
| juno_genesis_deployment_git_url | https://github.com/juno-fx/Genesis-Deployment.git |  The URL of the Genesis-Deployment repository. Note you still need to set the juno_bootstrap_chart_values.genesis.url value to point to the Genesis-Deployment repository.  This argument is only used to create the git sercet. It can be left empty on a default, non-airgapped install. |
| juno_genesis_deployment_git_username | {{ juno_git_username }} |  This authenticates only the Juno Genesis Deployment repository. You can leave it unchanged if both Juno-Bootstrap and Genesis-Deployment are accessible via juno_git_username&juno_git_password. |
| juno_git_password | False |  The password used to authenticate with all Juno repositories you specified. If left to the default (false), a public repository is assumed. |
| juno_git_username | oauth2 |  The username used to authenticate with all Juno repositories you specified. This is needed when you use a private fork of the Juno Bootstrap repository.  It is particularly useful in airgapped environments, where you might neither have access to the public version and might require authentication on your Git host. |
| juno_install | True |  Bootstrap Juno's Orion using https://github.com/juno-fx/Juno-Bootstrap |
| k3s_airgap_install | False |  If true, the playbook will perform an airgapped install. Make sure all the URLs above are set to file:// or point to a local mirror.  When setting the URLs to file://, they will be copied from your Ansible control host to the remote hosts. |
| k3s_binary_url | https://github.com/k3s-io/k3s/releases/download/v1.33.1%2Bk3s1/k3s |  URL for the k3s binary. Can be http://, https:// OR file://  When using file://, a path from your ansible control host (where your run the playbook from) will be used.  The files will be copied to the remote kubernetes hosts. This is useful for airgap installs. |
| k3s_bootstrap_node | False |  The node used to bootstrap the cluster. This should only ever be a single node in your inventory!  The playbook example we provide discovers this dynamically, but you can also set it manually. |
| k3s_bootstrap_node_ip | False |  The IP address of an existing controlplane node, used to join the cluster.  In most cases, we can automatically discover this, check out the playbook example - it does that out of the box! |
| k3s_clusterjoin_address | False |The address of the cluster to join. Can only be false when k3s_bootstrap_node is true. |
| k3s_control_plane_node | False |  When true, join the node to an existing cluster as a control plane node.  When neither k3s_bootstrap_node nor k3s_control_plane_node is true, the node will be a worker node. |
| k3s_copy_images | {{ k3s_airgap_install and not k3s_registries_yaml }} |  If true, the role will copy the k3s images tarball to the standard location where k3s can load them.  By default, we don't perform this if you define registries.yaml, as it is assumed you will have a local mirror. |
| k3s_force_reinstall | False |  If true, rerun the k3s install script even if the node is already part of a cluster. |
| k3s_images_url | https://github.com/k3s-io/k3s/releases/download/v1.33.1%2Bk3s1/k3s-airgap-images-amd64.tar.gz |  URL for the k3s images tarball. Can be http://, https:// OR file://  When using file://, a path from your ansible control host (where your run the playbook from) will be used.  The files will be copied to the remote kubernetes hosts. This is useful for airgap installs. |
| k3s_install_script_url | https://get.k3s.io/ |  URL for the k3s install script. Can be http://, https:// OR file://  When using file://, a path from your ansible control host (where your run the playbook from) will be used.  The files will be copied to the remote kubernetes hosts. This is useful for airgap installs. |
| k3s_join_token |  |  The token used to join the cluster. You can specify it explicitly or let the playbook autodiscover it.  Check out the example playbook for how to do that.k3s_join_token: false |
| k3s_node_labels | ["{{ k3s_control_plane_node | ternary('juno-innovations.com/service=true', 'juno-innovations.com/workstation=true') }}"] |  A list of labels to apply to a node on provisioning, only when k3s_perform_node_labeling is true.  Defaults to making each control plane node a Juno service node and each worker node a workstation node.  For details on how labels affect your Orion deployment, check out: https://juno-fx.github.io/Orion-Documentation/installation/pre-reqs/requirements/?h=label#1-labeling-nodes |
| k3s_perform_node_labeling | True |  Whether to label nodes when performing the initial k3s install.  Already existing nodes will not be labeled - use kubectl instead, per: https://juno-fx.github.io/Orion-Documentation/installation/pre-reqs/requirements/?h=label#1-labeling-nodes |
| k3s_registries_yaml | False |  If true, the playbook will configure the registries.yaml file to use your internal mirror.  For syntax refer to https://docs.k3s.io/installation/private-registry  The data you pass in here will be directly templated into the registries.yaml file. |
| k3s_uninstall | False |  If true, the playbook will run the default uninstall script (/usr/local/bin/k3s-uninstall.sh)  This is intended mostly for quick testing - in production, ideally you'd reprovision freshly. |
| validate_os_version | True |Check we are on a supported OS version, error otherwise. |



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
    - name: If the token exists on any node, set the skip_bootstrap variable
      ansible.builtin.set_fact:
        k3s_skip_bootstrap: false
      when: stat_k3s_bootstrap_node_token_file.stat.exists
      run_once: true

    - name: Make k3s_skip_bootstrap available to all hosts
      ansible.builtin.set_fact:
        k3s_skip_bootstrap: "{{ k3s_skip_bootstrap | default(false) }}"
      loop: "{{ ansible_play_hosts }}"
      delegate_to: "{{ item }}"
      run_once: true
    
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
            - not k3s_skip_bootstrap | default(false)


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
  hosts:
    - control_plane
    - k8s_worker
  vars:
    juno_git_user: "oauth2"
    juno_git_password: "password"
    juno_genesis_deployment_git_url: "http://{{ proxy_address }}/git/Genesis-Deployment.git"
    argo_install_manifest_url: "file://{{ playbook_dir }}/airgap_files/argo-install.yaml"
    juno_bootstrap_git_url: "http://{{ proxy_address }}/git/Juno-Bootstrap.git"
    k3s_install_script_url: "file://{{ playbook_dir }}/airgap_files/install.sh"
    k3s_binary_url: "file://{{ playbook_dir }}/airgap_files/k3s"
    # For more details on using a private registry, eg. using authentication, see:
    # https://docs.k3s.io/installation/private-registry
    k3s_registries_yaml: |
      mirrors:
        docker.io:
          endpoint:
            - "http://{{ proxy_address }}:5000"
        quay.io:
          endpoint:
            - "http://{{ proxy_address }}:5001"
        ghcr.io:
          endpoint:
            - "http://{{ proxy_address }}:5002"
    k3s_airgap_install: true
    juno_bootstrap_chart_values:
      genesis:
        repoURL: "http://{{ proxy_address }}/git/Genesis-Deployment.git"
  tasks:
    - name: Check if the join token file exists
      ansible.builtin.stat:
        path: /var/lib/rancher/k3s/server/token
      become: true
      register: stat_k3s_bootstrap_node_token_file
    - name: If the token exists on any node, set the skip_bootstrap variable
      ansible.builtin.set_fact:
        k3s_skip_bootstrap: false
      when: stat_k3s_bootstrap_node_token_file.stat.exists
      run_once: true

    - name: Make k3s_skip_bootstrap available to all hosts
      ansible.builtin.set_fact:
        k3s_skip_bootstrap: "{{ k3s_skip_bootstrap | default(false) }}"
      loop: "{{ ansible_play_hosts }}"
      delegate_to: "{{ item }}"
      run_once: true

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
            - not k3s_skip_bootstrap | default(false)

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