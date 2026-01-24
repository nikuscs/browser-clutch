# Contributing

Thanks for your interest in contributing to Browser Clutch!

## Getting Started

```bash
# Clone the repo
git clone https://github.com/nikuscs/browser-clutch.git
cd browser-clutch

# Install dependencies
make setup

# Build and run
make all
```

## Development Workflow

1. Create a branch from `develop`
2. Make your changes
3. Run `make lint` and `make check`
4. Open a PR to `develop`

## Code Style

- Run `make lint` before committing
- Keep code simple and readable
- Use single-word verbs for function names (`load`, `save`, `find`)
- No unnecessary comments

## Pull Requests

- Keep PRs focused on a single change
- Include a clear description of what and why
- Ensure lint and type check pass

## Reporting Issues

Open an issue with:
- macOS version
- Steps to reproduce
- Expected vs actual behavior

## License

By contributing, you agree that your contributions will be licensed under the project's [non-commercial license](LICENSE.md).
