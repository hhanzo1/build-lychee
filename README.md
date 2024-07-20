## About
Lychee is a Photo self hosting application.

Initially, I tried using the [Lychee Official Docker image](https://github.com/LycheeOrg/Lychee-Docker) but encountered various issues.

Please review the [Lychee Official Documentation](https://lycheeorg.github.io/docs/) before running the script so you are familiar with the [installation process](https://lycheeorg.github.io/docs/#installation).

This shell script was created to install the required software on a Ubuntu 22 system and build the Lychee application from the source repository.
## Prerequisites
*  Tested on Ubuntu 22.04.4 LTS (Jammy Jellyfish)
## Installation
Download script to your home directory
```bash
wget https://github.com/hhanzo1/update-ufw-rule/blob/main/build-lychee-stack.sh
chmod +x build-lychee-stack.sh
```

**IMPORTANT**
Update the various variables (ie. MySQL root password, APP_URL, Nginx server_name etc) before running the script!
## Usage
### Run the script
```bash
/home/[USERID]/build-lychee-stack.sh
```

Once completed the system should be ready for the Lychee Installation to complete the installation process.

Enjoy!
## Acknowledgments
* [Lychee Org](https://lycheeorg.github.io/) Please support the developers.
