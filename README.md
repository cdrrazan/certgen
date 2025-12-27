# Certgen

![Ruby](https://img.shields.io/badge/Ruby-3.1%2B-red)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

**Certgen** is a pure Ruby CLI tool to generate free SSL certificates from [Let's Encrypt](https://letsencrypt.org) using **DNS-01 verification**. Perfect for developers and site owners who use cPanel or manually managed servers and need to upload certificates themselves.

## 📦 Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/cdrrazan/certgen
   cd certgen
   ```

2. **Install dependencies:**
   ```bash
   bundle install
   ```

## 🌍 Global Usage (Recommended)

To run `certgen` from anywhere without typing the full path, create a symlink in your system bin:

```bash
sudo ln -s "$(pwd)/bin/certgen" /usr/local/bin/certgen
```

Now you can simply run:
```bash
certgen generate --domain example.com --email user@example.com
```

## 🚀 Usage

#### 🔧 Generating Certificates
Run the CLI tool from the project directory:

```bash
bin/certgen generate --domain example.com --email user@example.com
```
This above command will overall:
1. Generate or reuse your Let's Encrypt account key
2. Create DNS-01 challenge instructions
3. Wait for your confirmation after DNS is set
4. Generate the certificate files
5. Zip them for upload to cPanel or any hosting service

#### 🔧 Testing with Let’s Encrypt Staging

To avoid hitting rate limits during development or testing, use the Let’s Encrypt staging environment:

```bash
certgen test --domain example.com --email you@example.com
```

- This runs the same generation process but against the staging ACME server.
- Useful for verifying DNS setup and automation without generating real certificates.

### 🔄 Example Output Files

After running, your certs will be saved in:

```
~/.ssl_output/example.com/
├── certificate.crt
├── private_key.pem
├── ca_bundle.pem
└── cert_bundle.zip
```

## 🧪 Testing

The project uses RSpec for testing. To run the full test suite:

```bash
bundle exec rspec
```

The tests include mocks for the ACME API and file system, ensuring safe and fast execution.

## ✍️ DNS Setup

You'll be prompted to create a DNS TXT record:

```text
Record Name: _acme-challenge.example.com
Record Type: TXT
Record Value: abc123...
```

Use [https://dnschecker.org](https://dnschecker.org) to confirm propagation before continuing.

## ✅ Requirements

- Ruby >= 3.1
- DNS management access to create TXT records
- cPanel or similar manual SSL upload support

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/cdrrazan/certgen/blob/main/LICENSE) file for details.

## 🙌 Author

**Rajan Bhattarai**  
[GitHub](https://github.com/cdrrazan) • [Email](mailto:cdrrazan@gmail.com)

---

🛠 Contributions and issues are welcome — feel free to open a PR or issue on [GitHub](https://github.com/cdrrazan/certgen)!
