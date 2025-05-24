# PHP Dev Box

<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-box-seam-fill" viewBox="0 0 16 16">
  <path fill-rule="evenodd" d="M15.528 2.973a.75.75 0 0 1 .472.696v8.662a.75.75 0 0 1-.472.696l-7.25 2.9a.75.75 0 0 1-.557 0l-7.25-2.9A.75.75 0 0 1 0 12.331V3.669a.75.75 0 0 1 .471-.696L7.443.184l.01-.003.268-.108a.75.75 0 0 1 .558 0l.269.108.01.003zM10.404 2 4.25 4.461 1.846 3.5 1 3.839v.4l6.5 2.6v7.922l.5.2.5-.2V6.84l6.5-2.6v-.4l-.846-.339L8 5.961 5.596 5l6.154-2.461z"/>
</svg>

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

![Screenshot](screenshot.jpg)

## Contributing

Pull requests are welcome! If you have ideas or issues, please open an issue.

## License 

This project is licensed under the [MIT License](https://opensource.org/license/mit).