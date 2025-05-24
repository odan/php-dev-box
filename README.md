# PHP Dev Box

<img src="./assets/logo.svg" width="100" height="100" />

A lightweight, developer-friendly local server stack featuring **PHP**, **Apache**, and **MySQL** — designed for fast, simple local development without the bloat of traditional stacks.

## 🚀 Features

- ✅ Easy to install and run
- 🔧 Includes PHP, Apache and MySQL
- 📦 All-in-one local development environment
- 🗂 Simple status UI
- 💻 Designed for developers building PHP applications

## 📦 What's inside

| Component | Version | Notes                      |
|-----------|---------|----------------------------|
| PHP       | 8.4.5   |                            |
| Apache    | 2.4.63  |                            |
| MySQL     | 8.4.4   |                            |

## But why?

Since [XAMPP](https://www.apachefriends.org/) isn’t actively developed anymore, I went ahead and created this package to help you install and manage Apache, PHP (with XDebug) and MySQL on Windows. 

## Installation

### Windows

1. **Clone or download** this repository to `c:\xampp`.
 
2. **Open PowerShell as administrator**  (important to ensure everything installs smoothly).
 
3. **Run**  `.\devbox-setup.ps1` to install Apache, PHP, MySQL.

  - The script will handle the downloading and configuring of these components for you.
 
4. **Follow any on-screen prompts** and let the script do its magic.

5. Run: `devbox.exe` to start the services.

### macOS & Linux

> Support for Unix-based systems is not planned.

# Usage

Start the local server with one click (GUI) or via terminal:

```
c:\xampp\devbox.exe
```

## Security

This tool is designed for **local development only**. Never expose it to a public network.

### Screenshot 

<img src="assets/screenshot.png" width="596" />

## Contributing

Pull requests are welcome! If you have ideas or issues, please open an issue.

## License 

This project is licensed under the [MIT License](https://opensource.org/license/mit).