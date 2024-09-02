## How to run the playbook

### Install PIP

```
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
```

### Activate Python Virtual Environment

```
python3 -m venv ~/.fluence/venvs/ansible
source ~/.fluence/venvs/ansible/bin/activate
```

### Install Python Dependencies

```
pip3 install -r requirements.txt
```

### Intall Ansible dependencies

```
ansible-galaxy collection install fluencelabs.provider --force
```

### Run the playbook

```
ansible-playbook nox.yml -i inventory.yml
```
