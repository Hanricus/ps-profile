# ps-profile

A PowerShell profile that gives short aliases for network share paths (IIS webroots, local folders and scripts) and maps drive letters on demand.

## Setup on a new machine

One line, no browser needed:

```powershell
irm https://raw.githubusercontent.com/Hanricus/ps-profile/main/install.ps1 | iex
```

Run the same line again to update. Or clone it yourself:

```powershell
git clone https://github.com/Hanricus/ps-profile.git
cd ps-profile
.\install.ps1
```

Open a new PowerShell window after that.

## How it stays portable

- `install.ps1` writes a small stub into `$PROFILE` that loads the profile from this repo, so a `git pull` updates the profile.
- Machine specific paths are detected at load time (user folder, Desktop, PHP folder under `C:\`).
- Personal data lives in `%USERPROFILE%\PSRoutes` and is not tracked by git: `ps-routes.json` (your saved routes) and `backup.ps1`.

## Commands

- `newpath` adds a new route alias
- `list` shows all routes

## Private routes

Anything you do not want in git (internal server names and so on) goes in `%USERPROFILE%\PSRoutes\local.ps1`. The profile loads that file automatically if it exists, and it is git ignored.

## License

MIT. Made just for fun, use it and change it however you like.
