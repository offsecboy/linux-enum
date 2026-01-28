# Linux Enumeration Cheatsheet

## Live Website

**Live Demo:** [https://offsecboy.github.io/linux-enum/](https://offsecboy.github.io/linux-enum/)

## Overview

This repository contains a static HTML cheatsheet that provides essential Linux enumeration commands in a clean, categorized format. It's designed to be a quick reference during security assessments, CTF challenges, and system administration tasks.

## Features

- **Curated Commands**: Focuses on the most critical enumeration commands for real-world use
- **Organized Categories**: Logical grouping by enumeration type (System, Users, Network, Files, etc.)
- **Quick Wins Section**: Highlights priority checks for efficient privilege escalation
- **Responsive Design**: Works well on desktop and mobile devices
- **No Dependencies**: Pure HTML/CSS - loads instantly

## Categories Covered

1. **System Information** - Kernel, environment, host details
2. **Hardware Enumeration** - CPU, memory, devices
3. **User & Group Enumeration** - Accounts, permissions, sudo access
4. **Network Information** - Interfaces, ports, DNS, routing
5. **File System Enumeration** - Permissions, SUID/SGID, capabilities
6. **Credentials & Secrets** - SSH keys, config files, command history
7. **Quick Wins** - Priority privilege escalation checks

## Usage

Simply visit the live website at [https://offsecboy.github.io/linux-enum/](https://offsecboy.github.io/linux-enum/) to use the cheatsheet.

For local use:
1. Clone the repository
2. Open `index.html` in any modern web browser
3. No server or build process required

## Project Structure

```
linux-enum/
├── index.html          # Main cheatsheet file
├── assets/            # CSS and image assets
├── LICENSE           # License file
└── README.md         # This file
```

## Development

This is a static HTML/CSS project. To modify:
1. Edit `index.html` for content changes
2. Modify CSS in the `<style>` section
3. Test by opening the file locally in a browser

## Contributing

Contributions are welcome! Please ensure:
1. Commands are relevant for Linux enumeration
2. Explanations are clear and concise
3. Formatting follows the existing structure

## Related Resources

This is a condensed version of a more comprehensive enumeration reference. For additional commands and categories, check the original full document.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This cheatsheet is for educational purposes and authorized security testing only. Always ensure you have proper authorization before running enumeration commands on systems you don't own.

## Contact

For questions or suggestions, please open an issue in this repository. 
