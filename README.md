# SecureCorp Zero Trust Lab – Enterprise Access Portal POC

> A reproducible lab that simulates a modern enterprise-grade **Zero Trust** architecture for a fake company called **SecureCorp**.  
> It demonstrates **PKI**, **OIDC SSO**, **MFA**, **secret management**, **mutual TLS**, and **centralized logging** – all automated with **Infrastructure as Code**.

---

##  Objectives

This project is not “just a lab”.  
It is designed as a **Proof of Concept of an engineer mindset**:

- Design a **coherent architecture** (not a single random VM).
- Automate everything with **Vagrant + Ansible** (reproducible environment).
- Apply **real-world security patterns**:
  - 2-tier PKI (Root CA offline, Intermediate CA online).
  - ACME-based certificate issuance & renewal.
  - Centralized **Identity Provider (IdP)** with **OIDC SSO** & **MFA (TOTP)**.
  - **mTLS** between backend services.
  - Secrets managed via a **secret manager**, not hard-coded.
  - Logging, audit, and **certificate revocation** workflows.

---

##  High-Level Architecture

The lab runs fully on local VMs (VirtualBox) orchestrated by Vagrant and configured by Ansible.

### VM Roles

| VM Name          | Role                                           |  IP  address      |
|------------------|-----------------------------------------------|-------------------|
| `root-ca`        | Offline Root Certificate Authority            | `192.168.56.10`   |
| `intermediate-ca`| Online Intermediate CA (Step-CA / Vault PKI)  | `192.168.56.11`   |
| `idp`            | Identity Provider (Keycloak / Authentik)      | `192.168.56.12`   |
| `portal-app`     | SecureCorp Zero Trust Access Portal (web app) | `192.168.56.13`   |
| `db`             | Database (PostgreSQL / MariaDB)               | `192.168.56.14`   |
| `logs`           | Central logging server (rsyslog / Graylog)    | `192.168.56.15`   |

### Logical Components

- **PKI**
  - Root CA (offline, long lived).
  - Intermediate CA (online, issues all leaf certs).
  - ACME endpoint for automated certificate management.

- **IAM / IdP**
  - Keycloak realm `SecureCorp`.
  - OIDC client for the portal.
  - Roles: `ROLE_ADMIN`, `ROLE_DEV`, `ROLE_USER`.
  - MFA via TOTP (Google Authenticator, etc.).

- **Application**
  - “SecureCorp Zero Trust Access Portal”:
    - Users authenticate via OIDC + MFA.
    - Access to protected backend endpoints depends on RBAC roles.

- **Cryptography / Secure Comms**
  - All external access over **HTTPS** using certificates from the Intermediate CA.
  - **mTLS** between `portal-app` and `db` (or backend API).
  - Secrets (DB password, OIDC client secret, etc.) injected at runtime via **Vault** (or equivalent), not stored in the codebase.

- **Observability**
  - Centralized logs from:
    - Nginx / web server.
    - IdP (Keycloak).
    - System logs from all VMs.
  - Can be extended with visual dashboards (Graylog / ELK light).

---

##  Architecture Diagram

> The diagram is stored under `architecture/diagram.md` and/or a `.drawio` file.  
> Below is a Mermaid version for quick understanding:

```mermaid
flowchart LR
    User --> Browser

    Browser -->|HTTPS| Portal[SecureCorp Portal]
    Portal -->|OIDC Redirect| IdP[IdP (Keycloak)]
    IdP -->|ID Token / Access Token (OIDC)| Portal

    Portal -->|mTLS| Backend[Backend / DB Access Layer]
    Backend -->|mTLS| DB[(Database)]

    Portal -->|Syslog / HTTP| Logs[Central Logs]
    IdP -->|Syslog / HTTP| Logs
    Backend -->|Syslog / HTTP| Logs

    RootCA[(Root CA - Offline)] -. signs .-> IntCA[(Intermediate CA - Online)]
    IntCA -->|ACME / Issue certs| Portal
```

    IntCA -->|ACME / Issue certs| IdP
    IntCA -->|Issue client certs| Backend
