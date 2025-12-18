# Windows Performance Tweaker - Quick Start Guide

## 🚀 Quick Start (3 Steps)

### Step 1: Open PowerShell as Administrator

1. Press `Win + X`
2. Select **"Windows PowerShell (Admin)"** or **"Terminal (Admin)"**

### Step 2: Navigate to the Script

```powershell
cd "G:\Code\003-Projects\003-Win-Tweaker"
```

### Step 3: Run the Script

```powershell
.\Win-Tweaker.ps1
```

---

## 🎯 Recommended First-Time Use

When the menu appears, follow this sequence:

1. **Select Option 12** - Create System Restore Point

   - This creates a safety backup of your system

2. **Select Option 15** - Apply All Optimizations

   - This will automatically:
     - Apply all performance tweaks
     - Backup your settings
     - Log all changes

3. **Restart your computer**
   - Many optimizations require a restart to take effect

---

## 📋 What to Expect

### During Optimization

- You'll see colored status messages:
  - 🟢 **Green** = Success
  - 🟡 **Yellow** = Warning/Info
  - 🔴 **Red** = Error
  - ⚪ **White** = General information

### After Optimization

- A log file will be created: `WinTweaker.log`
- A backup file will be created: `WinTweaker_Backup_[timestamp].json`
- You should notice:
  - Faster boot times
  - Improved system responsiveness
  - More available disk space
  - Better overall performance

---

## ⚠️ Important Notes

### Before You Start

- ✅ Close all important applications
- ✅ Save your work
- ✅ Ensure you have administrator privileges
- ✅ Have at least 30 minutes available (for full optimization)

### After Optimization

- 🔄 **Restart your computer** for changes to take effect
- 📊 Monitor system performance for a few days
- 📝 Check the log file if you encounter any issues

---

## 🔄 If Something Goes Wrong

### Option 1: Restore from Backup

1. Run the script again
2. Select **Option 14** - Restore Previous Settings
3. Choose the backup file to restore
4. Restart your computer

### Option 2: Use System Restore

1. Press `Win + R`
2. Type `rstrui.exe` and press Enter
3. Follow the wizard to restore to the restore point created earlier

### Option 3: Manual Revert

- Re-enable services through Windows Services (`services.msc`)
- Adjust visual effects through System Properties
- Reset power plan to "Balanced"

---

## 💡 Tips for Best Results

1. **Run on a clean system** - Close all applications before running
2. **Don't interrupt** - Let each optimization complete fully
3. **Restart when prompted** - Many changes require a restart
4. **Monitor performance** - Give it a few days to see the full effect
5. **Keep backups** - Don't delete the backup files immediately

---

## 📞 Need Help?

- 📋 Check the log file: `WinTweaker.log`
- 📖 Read the full documentation: `README.md`
- 🔍 Review what each option does before running it

---

## 🎓 Understanding the Menu

### Performance Optimizations (1-11)

Individual tweaks you can apply selectively

### Backup & Restore (12-14)

Safety features to protect your system

### Utilities (15-16)

- **15**: Apply everything at once (recommended for first-time users)
- **16**: View what's been done

### Exit (0)

Close the tool

---

**Ready to optimize? Let's make your Windows fly! 🚀**
