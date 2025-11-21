mon archi d'entreprise zero-trust/
├── README.md
├── architecture/
│   ├── diagram.md      # lien vers draw.io de l'architecture
├── iac/
│   ├── Vagrantfile
│   └── ansible/
│       ├── inventory
│       ├── roles/
│       └── playbooks/
├── apps/
│   └── portal/         # l'app web (API + simple frontend)
├── docs/
│   ├── Security_Policy.md
│   ├── Threat_Model.md
│   └── Post_Mortem.md
├── scripts/
│   ├── revoke_cert.sh
│   └── rotate_keys.sh
