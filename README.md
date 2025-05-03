# Certgen

![Ruby](https://img.shields.io/badge/Ruby-3.1%2B-red)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Gem Version](https://img.shields.io/gem/v/certgen)

**Certgen** is a Ruby CLI tool to generate free SSL certificates from [Let's Encrypt](https://letsencrypt.org) using **DNS-01 verification**. Perfect for developers and site owners who use cPanel or manually managed servers and need to upload certificates themselves.

## ✨ Features

- ✅ Generate valid SSL certificates via Let's Encrypt
- 🌐 Supports both base domains and `www.` subdomains automatically
- 🔐 Uses DNS-01 challenge (great for wildcard and shared hosting)
- 📁 Outputs `.crt`, `.pem`, and zipped bundles for easy upload
- 🔄 Stores reusable Let's Encrypt account key
- 🖥️ CLI interface for quick and easy usage

## 📦 Installation

```bash
gem install certgen
```

## 🚀 Usage

Run the CLI tool from your terminal:

```bash
certgen --domain example.com --email user@example.com
```

This will:
1. Generate or reuse your Let's Encrypt account key
2. Create DNS-01 challenge instructions
3. Wait for your confirmation after DNS is set
4. Generate the certificate files
5. Zip them for upload to cPanel or any hosting service

### 🔄 Example Output Files

After running, your certs will be saved in:

```
~/.ssl_output/example.com/
├── certificate.crt
├── private_key.pem
├── ca_bundle.pem
└── cert_bundle.zip
```

## ✍️ DNS Setup

You'll be prompted to create a DNS TXT record:

```text
Record Name: _acme-challenge.example.com
Record Type: TXT
Record Value: abc123...
```

Use [https://dnschecker.org](https://dnschecker.org) to confirm propagation before continuing.

## 🔧 Development

Clone and run locally:

```bash
git clone https://github.com/cdrrazan/certgen
cd certgen
bundle install
```

Run the CLI locally:

```bash
bin/certgen --domain example.com --email user@example.com
```

## ✅ Requirements

- Ruby >= 3
- DNS management access to create TXT records
- cPanel or similar manual SSL upload support

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/cdrrazan/certgen/blob/main/LICENSE) file for details.

## 🙌 Author

**Rajan Bhattarai**  
[GitHub](https://github.com/cdrrazan) • [Email](mailto:cdrrazan@gmail.com)

---

🛠 Contributions and issues are welcome — feel free to open a PR or issue on [GitHub](https://github.com/cdrrazan/certgen)!
