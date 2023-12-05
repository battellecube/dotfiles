# A Better Life with Versioned Dotfiles

_NOTE: This file lives in `~/.github` as to not clutter your home directory_


## Quick Start

Just do this and you're done.


```sh
curl -sSL -o /tmp/bootstrap-dotfiles.sh https://raw.githubusercontent.com/battellecube/dotfiles/main/.local/bin/bootstrap-dotfiles.sh
bash /tmp/bootstrap-dotfiles.sh
```

That's it, you're done. If you want to know more or hack on this repo, read on!


### The What and Why of Dotfiles

Dotfiles are configuration files in Unix-like systems, typically used to personalize your system and applications. They are called "dotfiles" as they often start with a dot (e.g., `.bashrc`, `.gitconfig`), which makes them hidden files in Unix-based systems. Here's a summary of their significance and the benefits of versioning them, especially in the context of onboarding new engineers:

1. **Personalization and Customization**: Dotfiles contain settings and preferences for various tools and applications. By configuring these files, users can tailor their work environment to their liking, enhancing productivity and ease of use.

2. **Consistency Across Environments**: For teams working in similar development environments, having a consistent set of configurations is crucial. Versioned dotfiles ensure that every team member has a similar setup, reducing the chances of "it works on my machine" problems.

3. **Efficient Onboarding**: New engineers can quickly set up their development environment by cloning a repository of shared dotfiles. This eliminates the need to manually configure each tool, speeding up the onboarding process.

4. **Version Control Benefits**: By storing dotfiles in a version-controlled repository (like GitHub), changes are tracked, and updates can be easily distributed across the team. It also allows for branching and experimenting with different configurations without affecting the main setup.

5. **Backup and Restoration**: Dotfiles in a version-controlled system act as a backup. In case of system failure or when setting up a new machine, engineers can easily restore their preferred environment.

6. **Collaboration and Sharing Best Practices**: Sharing dotfiles within a team or the wider community allows for sharing of best practices and useful configurations, fostering a collaborative environment.


## Hacking the Gibson

There is a `Containerfile` that will let you build/test this repo safely in a
container...normies still say Docker ;)

Try this to get started

```sh
sudo apt update && sudo apt install podman
podman build -t dotfile-test .
podman run -it --rm dotfile-test:latest bash
```

You should be in the container now as `tester`.  The password for this uses is
also `tester`

Now you should be able to paste in the the curl-to-bash line in the README.md
and start testing.  If you want to get fancy you can map the file into the
container from your local repo.  I'll leave that an exercise for the user as
there are MANY ways this could be done...and go wrong ;)


