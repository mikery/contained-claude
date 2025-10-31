# VHS tape for Claude Code Docker sandbox demo
# Run with: vhs demo.tape
# Shows: make worktree/my-feature -> creates worktree + container + launches Claude
# Then: !git status inside Claude shows we're on my-feature branch

Output demo.gif

Set Shell bash
Set FontSize 22
Set Width 1400
Set Height 900
Set TypingSpeed 50ms
Set Theme "Catppuccin Mocha"

# Start from main directory
Type "# Create worktree, start container, launch claude"
Sleep 1s
Enter

Type "make worktree/my-feature"
Sleep 2000ms
Enter

Sleep 9s

# Now we're inside Claude - run git status
Type "!git status"
Sleep 50ms
Enter

# Wait to show output: "On branch my-feature"
Sleep 1s

Type "lfg"
Sleep 50ms
Enter

Sleep 14s
