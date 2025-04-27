{ 
  "shell": {
    "packages": [
      "python3",
      "python3Packages.pip",
      "python3Packages.boto3",
      "python3Packages.black",
      "python3Packages.isort",
      "python3Packages.requests",
      "python3Packages.tqdm",
      "fzf",
      "zsh",
      "jq",
      "unzip",
      "trash-cli"
    ],
    "shellHook": ''
      echo "Welcome to the Nix shell environment!"
      echo "All preferred software packages are now available."
    ''
  }
}