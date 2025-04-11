# Scripts

[![CI](https://github.com/peteoshea/scripts/workflows/CI/badge.svg)](https://github.com/peteoshea/scripts/actions)

A collection of useful bash scripts to be installed on new systems to get setup quickly. As I mainly work on WSL (Windows Subsystem for Linux) these scripts are designed specifically for that system at the moment.

Based on the my generic [base-template](https://github.com/peteoshea/base-template) repository, which includes both PowerShell and bash scripts so this has been stripped down and shuold probably have been based on [scripts-to-rule-them-all](https://github.com/peteoshea/scripts-to-rule-them-all).

## WSL (Windows System for Linux)

These are both incorporated into the [bootstrap](script/bin/bootstrap) script so either [setup](script/setup) or [update](script/update) should include both.

### [brew_update_all](wsl/brew_update_all)

Script to update Homebrew and all locally installed Homebrew packages.

### [update](wsl/update)

Script to update APT packages and check for any Ubuntu version updates for WSL.
