# Contributing to Wethereal

First off, thank you for considering contributing to Wethereal! It's people like you that make Wethereal such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by respect and professionalism. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you are creating a bug report, please include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps which reproduce the problem**
- **Provide specific examples to demonstrate the steps**
- **Describe the behavior you observed after following the steps**
- **Explain which behavior you expected to see instead and why**
- **Include screenshots if possible**
- **Include your Windows version and PowerShell version**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- **Use a clear and descriptive title**
- **Provide a step-by-step description of the suggested enhancement**
- **Provide specific examples to demonstrate the steps**
- **Describe the current behavior and explain which behavior you expected to see instead**
- **Explain why this enhancement would be useful**

### Pull Requests

- Fill in the required template
- Follow the PowerShell style guide
- Include appropriate test cases
- Update documentation as needed
- End all files with a newline

## Development Process

### Setting Up Your Development Environment

1. Fork the repository
2. Clone your fork:
   ```powershell
   git clone https://github.com/yourusername/wethereal.git
   cd wethereal
   ```
3. Create a branch:
   ```powershell
   git checkout -b feature/my-new-feature
   ```

### PowerShell Style Guide

- **Function Names**: Use approved PowerShell verbs (Get, Set, New, Remove, Start, Stop, etc.)
- **Variables**: Use camelCase for local variables, PascalCase for script-scope variables
- **Comments**: Use `#` for single-line comments, `<# #>` for multi-line
- **Indentation**: Use 4 spaces (no tabs)
- **Line Length**: Keep lines under 120 characters when possible
- **Error Handling**: Always use try-catch blocks for operations that might fail
- **Logging**: Log all significant operations using the Write-Log function

### Code Structure

```
Wethereal/
├── Win-Tweaker.ps1              # Main script
├── Modules-GamingNetwork.ps1    # Gaming & Network optimizations
├── Modules-PrivacyCleanup.ps1   # Privacy & Cleanup features
├── Modules-AdvancedTools.ps1    # Advanced tools & monitoring
├── Modules-Enhancements.ps1     # Profiles & GPU optimizations
├── Modules-Advanced.ps1         # Real-time monitoring tools
└── Modules-FinalEnhancements.ps1 # Professional diagnostic tools
```

### Adding New Features

1. **Create a new function** in the appropriate module file
2. **Follow the naming convention**: `Verb-NounDescription`
3. **Add error handling**: Use try-catch blocks
4. **Add logging**: Use Write-Log for all operations
5. **Add backup**: Use Backup-RegistryValue or Backup-ServiceState
6. **Add to menu**: Update the appropriate menu function
7. **Update documentation**: Add to README.md and CHANGELOG.md

### Example Function Template

```powershell
function Set-MyNewFeature {
    Write-Host "`n[MY NEW FEATURE]" -ForegroundColor $Script:Colors.Title
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor $Script:Colors.Title

    if (-not (Confirm-Action -Message "Apply this feature?")) {
        return
    }

    Write-Log "Starting my new feature" -Level Info -Category "Feature"

    try {
        # Backup before changes
        Backup-RegistryValue -Path "HKLM:\Path" -Name "ValueName"

        # Make changes
        Set-ItemProperty -Path "HKLM:\Path" -Name "ValueName" -Value "NewValue"

        Write-Log "My new feature completed" -Level Success -Category "Feature"
        Write-Host "`n✓ Feature applied successfully!" -ForegroundColor $Script:Colors.Success
    }
    catch {
        Write-Log "Failed to apply feature: $($_.Exception.Message)" -Level Error -Category "Feature"
        Write-Host "`n✗ Failed to apply feature" -ForegroundColor $Script:Colors.Error
    }

    Read-Host "`nPress Enter to continue"
}
```

### Testing

Before submitting a pull request:

1. **Test on Windows 10** (if possible)
2. **Test on Windows 11** (if possible)
3. **Test with different privilege levels**
4. **Test error scenarios**
5. **Verify backups work**
6. **Verify restore works**
7. **Check for PowerShell warnings**: Run `Test-ScriptFileInfo` if applicable

### Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

Examples:

```
Add network speed test feature

- Implement DNS resolution testing
- Add ping latency measurement
- Add download speed estimation
- Update menu with new option

Fixes #123
```

### Documentation

- Update README.md for new features
- Update CHANGELOG.md with changes
- Add inline comments for complex logic
- Update QUICKSTART.md if needed

## Project Structure

### Module Organization

- **Modules-GamingNetwork.ps1**: Gaming and network optimizations
- **Modules-PrivacyCleanup.ps1**: Privacy settings and cleanup tasks
- **Modules-AdvancedTools.ps1**: Advanced system tweaks and tools
- **Modules-Enhancements.ps1**: Optimization profiles and GPU features
- **Modules-Advanced.ps1**: Real-time monitoring and diagnostics
- **Modules-FinalEnhancements.ps1**: Professional tools (health check, registry optimizer, etc.)

### Adding a New Module

If you need to create a new module:

1. Create the file: `Modules-YourFeature.ps1`
2. Add the module to `Win-Tweaker.ps1` in the module loading section
3. Export functions: `Export-ModuleMember -Function *`
4. Update documentation

## Release Process

1. Update version number in `Win-Tweaker.ps1`
2. Update CHANGELOG.md
3. Update README.md version badge
4. Create a new release on GitHub
5. Tag the release with version number

## Questions?

Feel free to open an issue with your question or reach out through GitHub Discussions.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Wethereal! 🚀
