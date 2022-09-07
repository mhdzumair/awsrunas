# awsrunas
aws-runas utility script to parse &amp; setup aws credentials. Just created to make my life easier. :sunglasses: 


# Requirement
- Setup [aws-runas](https://mmmorris1975.github.io/aws-runas/quickstart.html)


# Setup
```bash
git clone https://github.com/mhdzumair/awsrunas.git
cd awsrunas

# symlink to local bin folder
cp awsrunas.py ~/.local/bin/awsrunas -l

```

# Usage
```bash
# see script help
awsrunas -h

# setup ~/.aws/credentials file
awsrunas my-account

# export to current shell environment
eval `awsrunas -e my-account`

# run with aws-runas options
awsrunas my-account -o "-a 8h -r"
```
