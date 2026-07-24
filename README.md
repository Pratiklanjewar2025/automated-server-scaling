# ☁️ Automated Server Scaling & Load Management

A Cloud & DevOps project that automatically scales a **Dockerized Flask application on AWS EC2** based on CPU utilization and active connections.

The project uses **Terraform** for infrastructure provisioning, **Ansible** for server configuration, **Docker** for containerization, and **NGINX** for reverse proxy and load balancing.

---

## 🏗️ Architecture

```text
                    Users
                      │
                      ▼
              ┌───────────────┐
              │     NGINX     │
              │ Load Balancer │
              └───────┬───────┘
                      │
            ┌─────────┼─────────┐
            ▼         ▼         ▼
          EC2-1     EC2-2     EC2-3
            │         │         │
          Docker    Docker    Docker
            │         │         │
          Flask     Flask     Flask
          :5000     :5000     :5000

              Automated Scaling
                     │
      CPU + Active Connections
                     │
                     ▼
                Bash Script
                     │
          ┌──────────┴──────────┐
          ▼                     ▼
      Terraform              Ansible
     Create EC2          Configure EC2
          │                     │
          └──────────┬──────────┘
                     ▼
             Update NGINX
```

---

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| ☁️ AWS EC2 | Cloud infrastructure |
| 🏗️ Terraform | Infrastructure provisioning |
| ⚙️ Ansible | Server configuration |
| 🐳 Docker | Application containerization |
| 🌐 NGINX | Reverse proxy & load balancing |
| 🐍 Flask | Web application |
| 📜 Bash | Monitoring & scaling automation |

---

## ⚙️ How It Works

The system continuously monitors:

- **CPU utilization** using `mpstat`
- **Active connections** using NGINX `stub_status`

Scaling is triggered when:

```text
CPU > 80%
     AND
Active Connections > 300
     AND
More Server Capacity Required
```

The automated workflow is:

```text
High Load Detected
        ↓
Terraform Creates New EC2
        ↓
Get New EC2 Public IP
        ↓
Ansible Configures Server
        ↓
Dockerized Flask App Starts
        ↓
Add New EC2 IP to NGINX
        ↓
Reload NGINX
        ↓
New Server Receives Traffic
```

---

## 📂 Project Structure

```text
Automated-Server-Scaling/
│
├── app.py
├── requirements.txt
├── Dockerfile
├── main.tf
├── Configuration_instance.yml
├── increment_instance.sh
├── nginx.conf
├── new_ips.conf
├── .gitignore
└── README.md
```

### Important Files

- `main.tf` — Provisions AWS EC2 infrastructure using Terraform.
- `Configuration_instance.yml` — Configures new EC2 instances using Ansible.
- `increment_instance.sh` — Monitors load and performs automated scaling.
- `Dockerfile` — Containerizes the Flask application.
- `nginx.conf` — Configures NGINX reverse proxy and load balancing.
- `new_ips.conf` — Maintains the backend server list.

---

## 🚀 Basic Setup

### 1. Initialize Terraform

```bash
terraform init
terraform plan
terraform apply
```

### 2. Run Ansible

```bash
ansible-playbook Configuration_instance.yml
```

### 3. Validate NGINX

```bash
sudo nginx -t
```

### 4. Start Auto-Scaling Script

```bash
chmod +x increment_instance.sh
./increment_instance.sh
```

---

## ✨ Key Features

- Automated AWS EC2 provisioning
- Infrastructure as Code with Terraform
- Automated server configuration with Ansible
- Dockerized Flask deployment
- NGINX reverse proxy and load balancing
- CPU and active-connection monitoring
- Automatic scale-up during high load
- Dynamic addition of new EC2 instances to NGINX

---

## 👨‍💻 Author

**Pratik Lanjewar**

Cloud • DevOps • Software Development
